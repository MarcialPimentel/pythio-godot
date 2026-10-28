<?php
// Pythio (Godot version) leaderboard.
//   GET  leaderboard_godot.php?action=top[&board=v1]  -> top 10 entries of a board (default: current)
//   POST leaderboard_godot.php?action=start           -> a one-time run ticket {"run": "<id>"}
//   POST leaderboard_godot.php?action=submit  (JSON)  -> adds ONE entry, returns top 10 + your rank
// A score needs the ticket from the start of its run, used once, and the run must have lasted
// at least as long as the rounds it claims (review 2026-10-28: anyone could post any score).
// Data lives in *.data.php files: if anyone opens one in a browser, PHP runs its first line and
// shows nothing (SiteGround serves .json files directly, ignoring .htaccess; 2026-10-28).
// To hide an entry, add "hidden": true to it in leaderboard_godot_v2.data.php (File Manager;
// keep the first line as it is).
// Unlike the old leaderboard.php, the game can't overwrite the whole list: the server
// validates each entry, keeps the best scores itself, and limits how fast an address can post.
// Boards: a new board starts only when the scoring rules change; older boards stay on the
// server and can still be browsed (◀ ▶ in the game), but nobody can post to them.
//   v2 "Phase C onward": most rounds survived, then most effective healing.
//   v1 "Builds <= 33":   the original score (100 x each round survived), then round.
// Every new entry also records the build it came from.
header("Content-Type: application/json");
header("Cache-Control: no-store");

// Newest first. To start a new board: add it at the top and point CURRENT at it.
const BOARDS = [
    "v2" => ["file" => "leaderboard_godot_v2", "title" => "Phase C onward", "kind" => "healing"],
    "v1" => ["file" => "leaderboard_godot",    "title" => "Builds 1–33",    "kind" => "classic"],
];
const CURRENT = "v2";
const KEEP = 100;          // entries stored
const SHOW = 10;           // entries returned
const MAX_ROUND = 500;     // endless runs; sanity cap only (500 rounds is about 3.5 hours of play)
// Effective healing can't exceed the damage the party took; damage per round grows with the
// round, so cap generously by round: 4000 per round plus 400 x rounds^2.
function max_healing($rounds) { return 4000 * max(1, $rounds) + 400 * $rounds * $rounds; }
const MIN_SECONDS_BETWEEN_POSTS = 10;
const RUNS_FILE = "leaderboard_godot_runs";     // open run tickets
const SECRET_FILE = "leaderboard_godot_secret"; // random salt for hashing addresses
const LOCK_FILE = "leaderboard_godot.lock";
const STORE = ".data.php";                      // every data file ends in this
const GUARD = "<?php http_response_code(404); exit; ?>\n";   // first line of every data file
const RUN_TICKET_HOURS = 12;       // a ticket expires after this long
const MAX_OPEN_TICKETS = 5000;
const MAX_STARTS_PER_HOUR = 60;    // per address
// The shortest time `rounds` cleared rounds can take: round 1 is 15s, +1s a round, at most
// 25s (DifficultySystem first_round_time, round_time_growth, round_time_max), less 10%.
function min_seconds($rounds) {
    $t = 0;
    for ($i = 1; $i <= $rounds; $i++) $t += min(15 + ($i - 1), 25);
    return (int)floor($t * 0.9);
}

function respond($code, $payload) { http_response_code($code); echo json_encode($payload); exit; }

function store_path($name) { return __DIR__ . "/" . $name . STORE; }
function board_path($id) { return store_path(BOARDS[$id]["file"]); }

function read_json($path, $empty) {
    if (!file_exists($path)) return $empty;
    $raw = (string)file_get_contents($path);
    if (strncmp($raw, "<?php", 5) === 0) $raw = (string)substr($raw, strpos($raw, "\n") + 1);
    $d = json_decode($raw, true);
    return is_array($d) ? $d + $empty : $empty;
}

function load_data($id) { return read_json(board_path($id), ["entries" => [], "recent" => []]); }

// Saves safely: write a temporary file, keep a .bak copy of the old one, then swap it in.
// A failed write leaves the old file untouched instead of an empty board.
function save_json($path, $data) {
    $json = json_encode($data);
    if ($json === false) return false;
    $body = GUARD . $json;
    $base = substr($path, 0, -strlen(STORE));
    $tmp = $base . ".tmp" . STORE;
    if (file_put_contents($tmp, $body) !== strlen($body)) { @unlink($tmp); return false; }
    if (file_exists($path)) @copy($path, $base . ".bak" . STORE);
    return rename($tmp, $path);
}

// One lock for every write (the board files get swapped, so they can't hold the lock).
function lock() {
    $fp = fopen(__DIR__ . "/" . LOCK_FILE, "c");
    if (!$fp || !flock($fp, LOCK_EX)) respond(500, ["status" => "error", "message" => "Busy, try again"]);
    return $fp;
}
function unlock($fp) { flock($fp, LOCK_UN); fclose($fp); }

// One-time move from the old public .json files: keep the entries, drop the per-address
// "recent" list (it used a guessable salt), and delete the old files.
function migrate_old_files() {
    $old = [];
    foreach (BOARDS as $b) foreach (["", ".bak", ".tmp"] as $x) $old[] = __DIR__ . "/" . $b["file"] . $x . ".json";
    foreach (["", ".bak", ".tmp"] as $x) $old[] = __DIR__ . "/" . RUNS_FILE . $x . ".json";
    if (!array_filter($old, "file_exists")) return;
    $fp = lock();
    foreach (BOARDS as $id => $b) {
        $json = __DIR__ . "/" . $b["file"] . ".json";
        if (file_exists($json) && !file_exists(board_path($id))) {
            $d = read_json($json, ["entries" => []]);
            $d["recent"] = [];
            if (!save_json(board_path($id), $d)) { unlock($fp); respond(500, ["status" => "error", "message" => "Busy, try again"]); }
        }
    }
    foreach ($old as $f) if (file_exists($f)) @unlink($f);
    unlock($fp);
}

// A random salt kept on the server, so hashed addresses can't be reversed.
function secret() {
    $path = store_path(SECRET_FILE);
    $d = read_json($path, []);
    if (empty($d["salt"])) {
        $d = ["salt" => bin2hex(random_bytes(16))];
        save_json($path, $d);
        $d = read_json($path, []) + $d;   // if two requests raced, use the one that won
    }
    return $d["salt"];
}

// Request values as text; arrays and objects (?board[]=x) become "".
function str_in($v) { return (is_string($v) || is_int($v) || is_float($v)) ? (string)$v : ""; }

function sort_entries(&$entries, $kind) {
    usort($entries, function ($a, $b) use ($kind) {
        if ($kind === "healing") {
            if ($a["rounds"] !== $b["rounds"]) return $b["rounds"] - $a["rounds"];
            if ($a["healing"] !== $b["healing"]) return $b["healing"] - $a["healing"];
        } else {
            if ($a["score"] !== $b["score"]) return $b["score"] - $a["score"];
            if ($a["round"] !== $b["round"]) return $b["round"] - $a["round"];
        }
        return strcmp($a["date"], $b["date"]);   // earlier run wins ties
    });
}

function visible($entries) { return array_values(array_filter($entries, fn($e) => empty($e["hidden"]))); }

function public_entries($entries, $kind) {
    $rows = array_slice(visible($entries), 0, SHOW);
    if ($kind === "healing")
        return array_map(fn($e) => ["name" => $e["name"], "rounds" => $e["rounds"], "healing" => $e["healing"],
                                    "build" => $e["build"] ?? "", "date" => substr($e["date"], 0, 10)], $rows);
    return array_map(fn($e) => ["name" => $e["name"], "score" => $e["score"] ?? 0, "round" => $e["round"] ?? 0,
                                "won" => $e["won"] ?? false, "date" => substr($e["date"] ?? "", 0, 10)], $rows);
}

function board_list() {
    $out = [];
    foreach (BOARDS as $id => $b) $out[] = ["id" => $id, "title" => $b["title"], "kind" => $b["kind"], "current" => $id === CURRENT];
    return $out;
}

migrate_old_files();
$action = str_in($_GET["action"] ?? "");
$who = hash("sha256", ($_SERVER["REMOTE_ADDR"] ?? "") . secret());

if ($action === "top") {
    $id = str_in($_GET["board"] ?? CURRENT);
    if (!isset(BOARDS[$id])) $id = CURRENT;
    $d = load_data($id);
    sort_entries($d["entries"], BOARDS[$id]["kind"]);
    respond(200, ["status" => "ok", "board" => $id, "kind" => BOARDS[$id]["kind"], "title" => BOARDS[$id]["title"],
                  "boards" => board_list(), "entries" => public_entries($d["entries"], BOARDS[$id]["kind"])]);
}

if ($action === "start" && $_SERVER["REQUEST_METHOD"] === "POST") {
    $fp = lock();
    $path = store_path(RUNS_FILE);
    $r = read_json($path, ["runs" => [], "starts" => []]);
    $now = time();
    $r["runs"] = array_filter($r["runs"], fn($t) => is_array($t) && $now - $t["at"] < RUN_TICKET_HOURS * 3600);
    $r["starts"] = array_filter($r["starts"], fn($l) => is_array($l) && $now - $l["since"] < 3600);
    $mine = $r["starts"][$who] ?? ["since" => $now, "n" => 0];
    if ($mine["n"] >= MAX_STARTS_PER_HOUR) { unlock($fp); respond(429, ["status" => "error", "message" => "Slow down a moment"]); }
    $r["starts"][$who] = ["since" => $mine["since"], "n" => $mine["n"] + 1];
    if (count($r["runs"]) >= MAX_OPEN_TICKETS) {
        uasort($r["runs"], fn($a, $b) => $a["at"] - $b["at"]);
        $r["runs"] = array_slice($r["runs"], count($r["runs"]) - MAX_OPEN_TICKETS + 1, null, true);
    }
    $run = bin2hex(random_bytes(12));
    $r["runs"][$run] = ["at" => $now];
    $ok = save_json($path, $r);
    unlock($fp);
    if (!$ok) respond(500, ["status" => "error", "message" => "Couldn't start the run"]);
    respond(200, ["status" => "ok", "run" => $run]);
}

if ($action === "submit" && $_SERVER["REQUEST_METHOD"] === "POST") {
    $in = json_decode(file_get_contents("php://input"), true);
    if (!is_array($in)) respond(400, ["status" => "error", "message" => "Invalid data"]);

    // Name: 1-16 letters, numbers, spaces and a few symbols
    $name = preg_replace("/[^A-Za-z0-9 _.\\-']/", "", str_in($in["name"] ?? ""));
    $name = trim(preg_replace("/\\s+/", " ", $name));
    $name = substr($name, 0, 16);
    if ($name === "") respond(400, ["status" => "error", "message" => "Enter a name"]);

    $rounds = (int)($in["rounds"] ?? -1);
    $healing = (int)($in["healing"] ?? -1);
    if ($rounds < 0 || $rounds > MAX_ROUND || $healing < 0 || $healing > max_healing($rounds))
        respond(400, ["status" => "error", "message" => "Score out of range"]);
    $build = substr(preg_replace("/[^A-Za-z0-9 #._\/\-]/", "", str_in($in["build"] ?? "")), 0, 40);

    $run = preg_replace("/[^a-f0-9]/", "", str_in($in["run"] ?? ""));
    if ($run === "") respond(400, ["status" => "error", "message" => "Refresh the page to get the latest game, then post again"]);

    $fp = lock();
    $now = time();
    // The run's ticket: it must exist, it's used up now, and the run must have taken long enough.
    $runs_path = store_path(RUNS_FILE);
    $r = read_json($runs_path, ["runs" => [], "starts" => []]);
    $ticket = $r["runs"][$run] ?? null;
    if (!is_array($ticket) || $now - $ticket["at"] > RUN_TICKET_HOURS * 3600) {
        unlock($fp);
        respond(400, ["status" => "error", "message" => "This run can't be posted (it wasn't registered when it started)"]);
    }
    if ($now - $ticket["at"] < min_seconds($rounds)) {
        unlock($fp);
        respond(400, ["status" => "error", "message" => "Score out of range"]);
    }

    $d = load_data(CURRENT);
    // Simple flood protection by (hashed) address
    foreach ($d["recent"] as $k => $t) if ($now - $t > 3600) unset($d["recent"][$k]);
    if (isset($d["recent"][$who]) && $now - $d["recent"][$who] < MIN_SECONDS_BETWEEN_POSTS) {
        unlock($fp);
        respond(429, ["status" => "error", "message" => "Slow down a moment"]);
    }
    $d["recent"][$who] = $now;

    $entry = ["name" => $name, "rounds" => $rounds, "healing" => $healing, "build" => $build, "date" => gmdate("c")];
    $d["entries"][] = $entry;
    sort_entries($d["entries"], "healing");
    $rank = array_search($entry, visible($d["entries"]), true) + 1;
    $d["entries"] = array_slice($d["entries"], 0, KEEP);

    unset($r["runs"][$run]);   // a ticket posts once
    $ok = save_json(board_path(CURRENT), $d) && save_json($runs_path, $r);
    unlock($fp);
    if (!$ok) respond(500, ["status" => "error", "message" => "Couldn't save, try again"]);

    respond(200, ["status" => "ok", "rank" => $rank, "board" => CURRENT, "kind" => "healing",
                  "title" => BOARDS[CURRENT]["title"], "boards" => board_list(),
                  "entries" => public_entries($d["entries"], "healing")]);
}

respond(400, ["status" => "error", "message" => "Invalid request"]);
