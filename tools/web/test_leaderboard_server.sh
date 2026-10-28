#!/usr/bin/env bash
# Drives web/leaderboard_godot.php through PHP's built-in server in a throwaway folder.
# CI runs it; locally: bash tools/web/test_leaderboard_server.sh   (needs php and curl)
set -u
DIR="$(mktemp -d)"
cp web/leaderboard_godot.php "$DIR/"
PORT=8099
php -S 127.0.0.1:$PORT -t "$DIR" >"$DIR/server.log" 2>&1 &
SERVER=$!
trap 'kill $SERVER 2>/dev/null; rm -rf "$DIR"' EXIT
sleep 1
URL="http://127.0.0.1:$PORT/leaderboard_godot.php"
fails=0
check() {   # check LABEL CONDITION-RESULT(0/1)
  if [[ "$2" == "0" ]]; then echo "PASS: $1"; else echo "FAIL: $1"; fails=$((fails + 1)); fi
}
has() { grep -q -- "$2" <<<"$1"; echo $?; }
code_of() { curl -s -o /dev/null -w '%{http_code}' "$@"; }
post() { curl -s -X POST -H 'Content-Type: application/json' -d "$2" "$URL?action=$1"; }

r=$(curl -s "$URL?action=top")
check "top answers with JSON" "$(has "$r" '"status":"ok"')"

r=$(post submit '{"name":"Old","rounds":3,"healing":100}')
check "a score without a run ticket is refused" "$(has "$r" 'Refresh the page')"

r=$(post submit '{"name":"Fake","rounds":3,"healing":100,"run":"abcdef0123456789abcdef01"}')
check "a made-up ticket is refused" "$(has "$r" "can't be posted")"

r=$(post start '')
RUN=$(grep -oE '"run":"[a-f0-9]+"' <<<"$r" | cut -d'"' -f4)
check "start hands out a ticket" "$([[ ${#RUN} -eq 24 ]]; echo $?)"

r=$(post submit "{\"name\":\"Marz\",\"rounds\":0,\"healing\":50,\"run\":\"$RUN\"}")
check "a real ticket posts" "$(has "$r" '"rank":1')"

r=$(post submit "{\"name\":\"Marz\",\"rounds\":0,\"healing\":60,\"run\":\"$RUN\"}")
check "a ticket posts only once" "$(has "$r" "can't be posted")"

RUN2=$(post start '' | grep -oE '"run":"[a-f0-9]+"' | cut -d'"' -f4)
r=$(post submit "{\"name\":\"Speedy\",\"rounds\":10,\"healing\":500,\"run\":\"$RUN2\"}")
check "10 rounds a second after starting is refused" "$(has "$r" 'out of range')"

r=$(post submit "{\"name\":[\"x\"],\"rounds\":0,\"healing\":5,\"run\":\"$RUN2\"}")
check "an array as the name is a clean error" "$(has "$r" 'Enter a name')"

check "?board[]=x answers 200, not a server error" "$([[ $(code_of "$URL?action=top&board[]=x") == 200 ]]; echo $?)"
check "?action[]=x answers JSON" "$(has "$(curl -s "$URL?action[]=x")" '"status":"error"')"

check "the board file was written" "$([[ -s $DIR/leaderboard_godot_v2.json ]]; echo $?)"
check "no temporary file left behind" "$([[ ! -e $DIR/leaderboard_godot_v2.tmp.json ]]; echo $?)"

# Hide the entry by hand, as the owner would in File Manager
sed -i 's/"name":"Marz"/"name":"Marz","hidden":true/' "$DIR/leaderboard_godot_v2.json"
r=$(curl -s "$URL?action=top")
check "a hidden entry isn't shown" "$(has "$r" '"entries":\[\]')"

if grep -qiE 'fatal|warning|notice|deprecated' "$DIR/server.log"; then
  echo "FAIL: PHP printed warnings:"; grep -iE 'fatal|warning|notice|deprecated' "$DIR/server.log" | head; fails=$((fails + 1))
fi
echo "RESULT: $fails failed"
[[ $fails -eq 0 ]]
