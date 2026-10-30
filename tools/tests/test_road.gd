extends SceneTree
const C = preload("res://tools/tests/check.gd")
# The Contract Road (docs/art-direction.md section 2, Marz 2026-10-30): which place each round
# happens in, the act line under the round, a new place's name card, weather, the Baron's Keep,
# the darker second lap, and the backdrop sitting behind every screen.
var game; var f := 0; var step := 0; var wait := 0.0
var GM; var DS; var B   # B = ui/Backdrop.gd, loaded by path once the autoloads exist
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func weather(): return game.backdrop.get_node("Art/Weather").get_children().filter(func(c): return not c.is_queued_for_deletion()).map(func(c): return String(c.name))

## Next party for round n, then start it.
func go_round(n: int) -> void:
	if GM.in_round: GM.in_round = false
	GM.current_round = n
	game._show_party_choice()

func _process(d):
	f += 1
	if f > 4000: C.timed_out(self); return true
	if game and game.card_panel and game.card_panel.visible and not game.card_panel._locked and f > 5:
		game.card_panel._choose(0)
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); DS = root.get_node("DifficultySystem")
			B = load("res://ui/Backdrop.gd")
			DS.screen_input_guard = 0.0; DS.job_finished_time = 0.0
			DS.base_dps = 0.0; DS.dps_growth = 0.0; DS.burst_interval = 999.0
			var got := {}
			for r in [1, 4, 5, 6, 9, 10, 11, 14, 15, 16, 21, 31]:
				got[r] = "%s/%d" % [B.act_for_round(r), B.lap_for_round(r)]
			P("round -> place/lap: %s" % [got])
			C.eq(got[1], "mudroad/0", "rounds 1–4: the Mudroad"); C.eq(got[4], "mudroad/0", "round 4 still the Mudroad")
			C.eq(got[5], "keep/0", "every Baron round: the Crimson Keep"); C.eq(got[10], "keep/0", "round 10: the Keep")
			C.eq(got[6], "marsh/0", "rounds 6–9: the Drowned Marsh (debuffs start)"); C.eq(got[9], "marsh/0", "round 9 still the marsh")
			C.eq(got[11], "chapel/0", "rounds 11–14: the Plague Chapel"); C.eq(got[14], "chapel/0", "round 14 still the chapel")
			C.eq(got[16], "mudroad/1", "round 16: back to the Mudroad, second lap"); C.eq(got[21], "marsh/1", "round 21: the marsh, second lap")
			C.eq(got[31], "mudroad/2", "round 31: third lap")
			C.eq(B.act_title("marsh"), "ACT II · THE DROWNED MARSH", "act line text")
			C.eq(B.act_title("keep"), "THE CRIMSON KEEP", "the Keep has no act number")
			C.ok(game.backdrop.get_index() < game.start_screen.get_index() and game.backdrop.get_index() < game.game_ui.get_index(), "the place sits behind the title screen and the game")
			C.eq(game.backdrop.act, "mudroad", "the title screen shows the Mudroad")
			game._on_start_pressed(); wait = 0.6
		1:
			if not game.party_choice_panel.visible: return false
			C.eq(game.act_label.text, "ACT I · THE MUDROAD", "Next party, round 1: act line under the round")
			game.party_choice_panel._on_left_chosen(); wait = 0.5
		2:
			if not GM.in_round: return false
			C.ok(game._act_card.visible and game._act_card.get_node("Big").text == "The Mudroad", "first round: the place's name shows big")
			C.ok(not game.backdrop.is_painted(), "no painted art yet: the code-drawn stand-in shows")
			go_round(6); wait = 0.6
		3:
			P("round 6: act=%s label='%s' weather=%s" % [game.backdrop.act, game.act_label.text, weather()])
			C.eq(game.backdrop.act, "marsh", "Next party for round 6 already shows the marsh")
			C.eq(game.act_label.text, "ACT II · THE DROWNED MARSH", "act line for the marsh")
			C.ok(weather().has("Rain") and weather().has("Fog"), "it rains in the marsh (and there's fog)")
			game.party_choice_panel._on_left_chosen(); wait = 0.5
		4:
			if not GM.in_round: return false
			C.eq(game._act_card.get_node("Big").text, "The Drowned Marsh", "entering the marsh shows its name")
			go_round(10); wait = 0.6
		5:
			C.eq(game.backdrop.act, "keep", "the Baron's round is in the Crimson Keep")
			C.ok(weather().has("Embers"), "embers rise in the Keep")
			game.party_choice_panel._on_left_chosen(); wait = 0.5
		6:
			if not GM.in_round: return false
			C.eq(game.round_label.text, "Round 10", "the Baron's title is short (the act line names the Keep)")
			go_round(12); wait = 0.6
		7:
			C.eq(game.backdrop.act, "chapel", "round 12: the chapel")
			C.ok(weather().has("Ash"), "ash falls at the chapel")
			go_round(16); wait = 1.2
		8:
			var art: Node2D = game.backdrop.get_node("Art")
			P("round 16: act=%s lap=%d light=%.2f" % [game.backdrop.act, game.backdrop.lap, art.modulate.r])
			C.ok(game.backdrop.act == "mudroad" and game.backdrop.lap == 1, "round 16: the Mudroad again, second lap")
			C.ok(art.modulate.r < 0.95, "the second lap is darker")
			C.done(self); return true
	step += 1
	return false
