<?php
// Pythio (Godot version) leaderboard.
//   GET  leaderboard_godot.php?action=top             -> top 10 entries
//   POST leaderboard_godot.php?action=submit  (JSON)  -> adds ONE entry, returns top 10 + your rank
// Unlike the old leaderboard.php, the game can't overwrite the whole list: the server
// validates each entry, keeps the best scores itself, and limits how fast an address can post.
header("Content-Type: application/json");
header("Cache-Control: no-store");

const DATA_FILE = __DIR__ . "/leaderboard_godot.json";
const KEEP = 100;          // entries stored
const SHOW = 10;           // entries returned
const MAX_ROUND = 1000;    // endless runs; sanity cap only
const MIN_SECONDS_BETWEEN_POSTS = 10;

function respond($code, $payload) { http_response_code($code); echo json_encode($payload); exit; }

function load_data() {
    if (!file_exists(DATA_FILE)) return ["entries" => [], "recent" => []];
    $d = json_decode(file_get_contents(DATA_FILE), true);
    return is_array($d) ? $d + ["entries" => [], "recent" => []] : ["entries" => [], "recent" => []];
}

function sort_entries(&$entries) {
    usort($entries, function ($a, $b) {
        if ($a["score"] !== $b["score"]) return $b["score"] - $a["score"];
        if ($a["round"] !== $b["round"]) return $b["round"] - $a["round"];
        return strcmp($a["date"], $b["date"]);   // earlier run wins ties
    });
}

function public_entries($entries) {
    return array_map(fn($e) => ["name" => $e["name"], "score" => $e["score"], "round" => $e["round"],
                                "won" => $e["won"], "date" => substr($e["date"], 0, 10)],
                     array_slice($entries, 0, SHOW));
}

$action = $_GET["action"] ?? "";

if ($action === "top") {
    $d = load_data();
    respond(200, ["status" => "ok", "entries" => public_entries($d["entries"])]);
}

if ($action === "submit" && $_SERVER["REQUEST_METHOD"] === "POST") {
    $in = json_decode(file_get_contents("php://input"), true);
    if (!is_array($in)) respond(400, ["status" => "error", "message" => "Invalid data"]);

    // Name: 1-16 letters, numbers, spaces and a few symbols
    $name = preg_replace("/[^A-Za-z0-9 _.\\-']/", "", (string)($in["name"] ?? ""));
    $name = trim(preg_replace("/\\s+/", " ", $name));
    $name = substr($name, 0, 16);
    if ($name === "") respond(400, ["status" => "error", "message" => "Enter a name"]);

    $round = (int)($in["round"] ?? 0);
    $score = (int)($in["score"] ?? -1);
    $won = (bool)($in["won"] ?? false);
    // Score is 100 x each round survived, so it can't exceed 100 * (1 + 2 + ... + round)
    $max_score = 50 * $round * ($round + 1);
    if ($round < 1 || $round > MAX_ROUND || $score < 0 || $score > $max_score)
        respond(400, ["status" => "error", "message" => "Score out of range"]);

    $fp = fopen(DATA_FILE, "c+");
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

    $entry = ["name" => $name, "score" => $score, "round" => $round, "won" => $won, "date" => gmdate("c")];
    $d["entries"][] = $entry;
    sort_entries($d["entries"]);
    $rank = array_search($entry, $d["entries"], true) + 1;
    $d["entries"] = array_slice($d["entries"], 0, KEEP);

    ftruncate($fp, 0); rewind($fp);
    fwrite($fp, json_encode($d));
    fflush($fp); flock($fp, LOCK_UN); fclose($fp);

    respond(200, ["status" => "ok", "rank" => $rank, "entries" => public_entries($d["entries"])]);
}

respond(400, ["status" => "error", "message" => "Invalid request"]);
