extends SceneTree
const C = preload("res://tools/tests/check.gd")
# The inked case-file pick cards (Marz, 2026-10-30): every card has its inked layer and a number
# tab, the art window shows the icon (or a monogram), the screen rebuilds cleanly, and hovering
# lifts a card. Text fitting inside the frame is checked on real-window screenshots.
var game; var f := 0; var step := 0; var wait := 0.0
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)

func busiest_card() -> Dictionary:
	var icon: Texture2D = load("res://assets/art/ui/icons/spell_hot.png")
	return {"header": "UPGRADES RENEW", "badge": "RANK UP", "icon": icon, "title": "Divine Protection",
		"cast": "1.5s CAST", "stats": "22 mana · 8s cooldown", "tags": ["DIRECT", "HOT", "CLEANSE"],
		"body_bb": "Heals 20, then heals 15 over 5s, then removes Poison from the fighter.",
		"hint_bb": "[color=#ffd24d]★ Your Overgrowth, Aura of Mending combos with this[/color]\n[color=#ffd24d]via Heal-over-Time[/color]",
		"flavor": "Contagious, in the good way.", "accent": Color("3ddc84")}

func _process(d):
	f += 1
	if f > 2000: C.timed_out(self); return true
	wait -= d
	if wait > 0 or f < 3: return false
	var panel = game.card_panel
	match step:
		0:
			panel.show_cards("Add a spell", "test", [busiest_card(), {"title": "Skip", "stats": "+10 max mana for the rest of the run", "body_bb": "Keep your build."}, busiest_card()])
			wait = 0.4
		1:
			var cards: Array = panel._cards
			C.eq(cards.size(), 3, "three cards")
			C.ok(cards.all(func(b): return b.get_node_or_null("Ink") != null), "every card has its inked layer")
			C.eq(cards.map(func(b): return b.get_node("Key").text), ["1", "2", "3"], "number tabs 1, 2, 3")
			var card: Button = cards[0]
			# (Text fitting inside the frame is checked on screenshots: headless runs don't lay out
			# wrapped text like a real window does.)
			C.ok(card.find_child("Icon", true, false) is TextureRect, "the art window shows the spell icon")
			C.ok(cards[1].find_child("Art", true, false).get_child_count() == 1, "a card without an icon shows a monogram")
			# Rebuild with fewer cards while the old ones are still being freed: no errors.
			panel.show_cards("Choose", "", [busiest_card()])
			wait = 0.3
		2:
			C.eq(panel._cards.size(), 1, "the screen rebuilds cleanly with fewer cards")
			panel._set_hover(0, true)
			C.ok(panel._hover[0] and panel._cards[0].scale.x > 1.0, "hovering lifts the card")
			C.done(self); return true
	step += 1
	return false
