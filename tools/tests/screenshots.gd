extends SceneTree
# godot --script shot2.gd -- out_prefix
var game; var f := 0; var out := "/tmp/s"
func _initialize():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: out = args[0]
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func snap(n): root.get_viewport().get_texture().get_image().save_png(out + "_" + n + ".png"); print("saved ", n)
func _process(_d):
	f += 1
	var GM = root.get_node_or_null("GameManager"); var TS = root.get_node_or_null("TargetSystem"); var DS = root.get_node_or_null("DifficultySystem")
	if f == 20: snap("start"); game._on_start_pressed()
	if f == 40: snap("choice")
	if f == 42:
		DS.base_dps = 0.0; DS.dps_growth = 0.0
		GM.in_round = false; GM.current_round = 5; game._show_party_choice()
	if f == 50: game.party_choice_panel._on_left_chosen()
	if f == 80:
		TS.targets[0].health_comp.current_health = TS.targets[0].health_comp.max_health * 0.45
		TS.targets[0].pending_burst_time = 4.0
	if f == 95: snap("boss")
	if f == 100: TS.targets[0].health_comp.take_damage(99999)
	if f == 130: snap("gameover"); quit()
	return false
