# tools/words: Phase H word list (#61)

**`export_words.py`** builds `docs/words/pythio-words.xlsx`: every line a player reads, one row
each, with the area, where it shows, the current text, a yellow "Your version" column for Marz,
and the file and line it came from (so edits can be put back exactly).

    python -m pip install openpyxl
    python tools/words/export_words.py

What it reads: spell and passive `.tres` files (names, flavour, combo words, hand-written card
text), battlefield rules, `data/PythioLines.gd`, and the text in the screen, HUD and effect
scripts listed in `CODE_FILES`. Text in code is found by a rule of thumb (sentences and labels
in, ids and paths out), so a few rows may be things nobody sees; the sheet tells Marz to leave
those empty. The debug panel (F1) is left out.

**`font_samples.gd`** renders `docs/words/font-samples.png`: each font slot (titles, UI,
Pythio's lines) in the current font and three free alternatives. The alternatives aren't in
the game; download them (OFL, from fontsource) into a folder first, named as in the script:

    curl -L -o <dir>/grenze-gotisch.woff2 https://cdn.jsdelivr.net/fontsource/fonts/grenze-gotisch@latest/latin-400-normal.woff2
    godot --path . --script tools/words/font_samples.gd -- <dir> docs/words/font-samples.png
