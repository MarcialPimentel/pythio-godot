<?php
// Pythio (Godot version) leaderboard.
//   GET  leaderboard_godot.php?action=top[&board=v1]  -> top 10 entries of a board (default: current)
//   POST leaderboard_godot.php?action=submit  (JSON)  -> adds ONE entry, returns top 10 + your rank
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
    "v2" => ["file" => "leaderboard_godot_v2.json", "title" => "Phase C onward", "kind" => "healing"],
    "v1" => ["file" => "leaderboard_godot.json",    "title" => "Builds 1–33",    "kind" => "classic"],
];
const CURRENT = "v2";
const KEEP = 100;          // entries stored
const SHOW = 10;           // entries returned
const MAX_ROUND = 1000;    // endless runs; sanity cap only
// Effective healing can't exceed the damage the party took; damage per round grows with the
// round, so cap generously by round: 4000 per round plus 400 x rounds^2.
function max_healing($rounds) { return 4000 * max(1, $rounds) + 400 * $rounds * $rounds; }
const MIN_SECONDS_BETWEEN_POSTS = 10;

function respond($code, $payload) { http_response_code($code); echo json_encode($payload); exit; }

function board_path($id) { return __DIR__ . "/" . BOARDS[$id]["file"]; }

function load_data($id) {
    $path = board_path($id);
    if (!file_exists($path)) return ["entries" => [], "recent" => []];
    $d = json_decode(file_get_contents($path), true);
    return is_array($d) ? $d + ["entries" => [], "recent" => []] : ["entries" => [], "recent" => []];
}

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

function public_entries($entries, $kind) {
    $rows = array_slice($entries, 0, SHOW);
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

$action = $_GET["action"] ?? "";

if ($action === "top") {
    $id = $_GET["board"] ?? CURRENT;
    if (!isset(BOARDS[$id])) $id = CURRENT;
    $d = load_data($id);
    sort_entries($d["entries"], BOARDS[$id]["kind"]);
    respond(200, ["status" => "ok", "board" => $id, "kind" => BOARDS[$id]["kind"], "title" => BOARDS[$id]["title"],
                  "boards" => board_list(), "entries" => public_entries($d["entries"], BOARDS[$id]["kind"])]);
}

if ($action === "submit" && $_SERVER["REQUEST_METHOD"] === "POST") {
    $in = json_decode(file_get_contents("php://input"), true);
    if (!is_array($in)) respond(400, ["status" => "error", "message" => "Invalid data"]);

    // Name: 1-16 letters, numbers, spaces and a few symbols
    $name = preg_replace("/[^A-Za-z0-9 _.\\-']/", "", (string)($in["name"] ?? ""));
    $name = trim(preg_replace("/\\s+/", " ", $name));
    $name = substr($name, 0, 16);
    if ($name === "") respond(400, ["status" => "error", "message" => "Enter a name"]);

    $rounds = (int)($in["rounds"] ?? -1);
    $healing = (int)($in["healing"] ?? -1);
    if ($rounds < 0 || $rounds > MAX_ROUND || $healing < 0 || $healing > max_healing($rounds))
        respond(400, ["status" => "error", "message" => "Score out of range"]);
    $build = substr(preg_replace("/[^A-Za-z0-9 #._\/\-]/", "", (string)($in["build"] ?? "")), 0, 40);

    $fp = fopen(board_path(CURRENT), "c+");
    if (!$fp || !flock($fp, LOCK_EX)) respond(500, ["status" => "error", "message" => "Busy, try again"]);
    $raw = stream_get_contents($fp);
    $d = json_decode($raw ?: "", true);
    if (!is_array($d)) $d = [];
    $d += ["entries" => [], "recent" => []];

    // Simple flood protection by (hashed) address
    $who = hash("sha256", ($_SERVER["REMOTE_ADDR"] ?? "") . "pythio");
    $now = time();
    foreach ($d["recent"] as $k => $t) if ($now - $t > 3600) unset($d["recent"][$k]);
    if (isset($d["recent"][$who]) && $now - $d["recent"][$who] < MIN_SECONDS_BETWEEN_POSTS) {
        flock($fp, LOCK_UN); fclose($fp);
        respond(429, ["status" => "error", "message" => "Slow down a moment"]);
    }
    $d["recent"][$who] = $now;

    $entry = ["name" => $name, "rounds" => $rounds, "healing" => $healing, "build" => $build, "date" => gmdate("c")];
    $d["entries"][] = $entry;
    sort_entries($d["entries"], "healing");
    $rank = array_search($entry, $d["entries"], true) + 1;
    $d["entries"] = array_slice($d["entries"], 0, KEEP);

    ftruncate($fp, 0); rewind($fp);
    fwrite($fp, json_encode($d));
    fflush($fp); flock($fp, LOCK_UN); fclose($fp);

    respond(200, ["status" => "ok", "rank" => $rank, "board" => CURRENT, "kind" => "healing",
                  "title" => BOARDS[CURRENT]["title"], "boards" => board_list(),
                  "entries" => public_entries($d["entries"], "healing")]);
}

respond(400, ["status" => "error", "message" => "Invalid request"]);
