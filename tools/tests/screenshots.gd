extends SceneTree
# Real screenshots of each screen: start, school pick, contract choice, a round in play
# (with a combo firing), a spell pick, the Crimson Baron, game over.
# xvfb-run -a -s "-screen 0 1920x1080x24" godot --rendering-driver opengl3 --resolution 1920x1080 \
#   --script tools/tests/screenshots.gd -- /tmp/pythio
var game; var f := 0; var out := "/tmp/s"
func _initialize():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func snap(n): root.get_viewport().get_texture().get_image().save_png(out + "_" + n + ".png"); print("saved ", n)
func _process(_d):
	f += 1
	var GM = root.get_node_or_null("GameManager"); var TS = root.get_node_or_null("TargetSystem")
	var DS = root.get_node_or_null("DifficultySystem"); var SS = root.get_node_or_null("SpellSystem")
	if f == 20:
		DS.screen_input_guard = 0.0   # frame-timed: the clicks below must not hit the input guard
		snap("start"); game._on_start_pressed()
	if f == 45: snap("school")
	if f == 47: game.card_panel._choose(1)   # Bloom
	if f == 80: snap("choice")
	if f == 82:
		DS.base_dps = 0.0; DS.dps_growth = 0.0; DS.burst_interval = 999.0
		DS.job_finished_time = 0.0; DS.screen_input_guard = 0.0   # frame-timed shots: no hold
		SS.set_spellbook_ids(PackedStringArray(["renew", "overgrowth", "shield", "aura_of_mending"]))
		game.party_choice_panel._on_left_chosen()
	if f == 90:
		GM.mana = 999.0
		for t in TS.targets: t.health_comp.current_health = t.health_comp.max_health * 0.55
		SS.request_cast(SS.get_library_spell("renew"), TS.targets[1])
	if f == 93: SS.request_cast(SS.get_library_spell("shield"), TS.targets[2])
	if f == 96:
		SS.request_cast(SS.get_library_spell("overgrowth"), TS.targets[1])
		TS.targets[3].pending_burst_time = 4.0
	if f == 104: snap("round")
	if f == 110: GM.end_round(true)
	if f == 140: snap("pick")
	if f == 142: game.card_panel._choose(0)
	if f == 170:
		GM.in_round = false; GM.current_round = 5; game._show_party_choice()
	if f == 175: game.party_choice_panel._on_left_chosen()
	if f == 200:
		TS.targets[0].health_comp.current_health = TS.targets[0].health_comp.max_health * 0.45
		TS.targets[0].pending_burst_time = 4.0
	if f == 215: snap("boss")
	if f == 220: TS.targets[0].health_comp.take_damage(99999)
	if f == 250: snap("gameover"); quit()
	return false
