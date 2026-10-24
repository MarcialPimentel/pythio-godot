extends SceneTree
# First-time practice round (owner, 2026-10-24): Take the Job asks "First time on the job?"
# once per device. Yes → one Heavy Knight, Heal only, prompts (Heal → mana and cast time →
# a warned hit), the knight can't die, then the real run starts at the spell choice with
# nothing carried over. No → straight to the spell choice. The next Take the Job never asks.
# Uses its own settings file, so it never touches the real "already asked" flag.
# Pass a path to also save screenshots of each prompt:
#   xvfb-run -a godot --rendering-driver opengl3 --script tools/tests/test_practice.gd -- /tmp/pr
var game; var f := 0; var GM; var SS; var TS; var DS; var step := 0; var wait := 0.0; var shot := ""
var P_CLASS
const CFG := "user://test_practice_settings.cfg"
func _initialize():
	var args = OS.get_cmdline_user_args()
	if args.size() > 0: shot = args[0]
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CFG))
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func snap(n):
	if shot != "":
		root.get_viewport().get_texture().get_image().save_png(shot + "_" + n + ".png"); print("saved ", n)
func coach(): return game._practice
func knight(): return TS.targets[0] if TS.targets.size() > 0 else null
func prompt() -> String: return coach()._text.get_parsed_text().replace("\n", " ") if coach() and coach()._text else ""

func _process(d):
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); SS = root.get_node("SpellSystem"); TS = root.get_node("TargetSystem"); DS = root.get_node("DifficultySystem")
			P_CLASS = load("res://scenes/practice.gd")
			P_CLASS.settings_path = CFG
			P("before: asked=%s" % P_CLASS.was_asked())
			game._on_take_job_pressed(); wait = 0.4
		1:
			P("Take the Job (first time): question shown=%s title='%s' mode=%s" % [game.card_panel.visible, game.card_panel._title.text, game._card_mode])
			snap("question")
			game.card_panel._choose(0)   # Yes, show me
			wait = 0.8
		2:
			var k = knight()
			P("practice: in_round=%s practice=%s fighters=%d (%s, %s) hp=%d/%d spells=%s round label='%s' timer='%s'" % [GM.in_round, GM.practice, TS.targets.size(),
				k.display_name, k.armor_type, k.health_comp.current_health, k.health_comp.max_health, SS.spells.map(func(s): return s.id), game.round_label.text, game.timer_label.text])
			P("asked is now saved=%s · prompt 1: %s" % [P_CLASS.was_asked(), prompt()])
			snap("step1")
			GM.mana = GM.max_mana
			SS.request_cast(SS.spells[0], k)
			wait = 2.0
		3:
			P("after a Heal: step=%d · prompt 2: %s" % [coach().step, prompt()])
			wait = coach().mana_step_time + 0.3
		4:
			P("warned hit: step=%d warning on knight=%s · prompt 3: %s" % [coach().step, knight().pending_burst_time > 0.0, prompt()])
			snap("step3")
			wait = coach().burst_warning + 1.5
		5:
			P("after the hit: step=%d hp=%d · button shown=%s · prompt 4: %s" % [coach().step, knight().health_comp.current_health, coach()._button.visible, prompt()])
			snap("step4")
			knight().health_comp.take_damage(99999.0)
			wait = 0.3
		6:
			P("can't die: hp=%d game over=%s in_round=%s" % [knight().health_comp.current_health, game.game_over_panel.visible, GM.in_round])
			P("random bursts off during practice: interval=%s" % DS.burst_interval)
			coach()._button.emit_signal("pressed")   # Start the real job
			wait = 0.8
		7:
			P("real run: practice=%s in_round=%s spell choice=%s mode=%s spells=%s debug_used=%s fighters=%d burst interval=%s" % [GM.practice, GM.in_round,
				game.card_panel.visible, game._card_mode, SS.spells.map(func(s): return s.id), GM.debug_used, TS.targets.size(), DS.burst_interval])
			game._leave_run()
			game.game_ui.visible = false; game.start_screen.visible = true
			game._on_take_job_pressed(); wait = 0.4
		8:
			P("second Take the Job: question=%s mode=%s (no question, spell choice expected)" % [game.card_panel._title.text == "First time on the job?", game._card_mode])
			game._leave_run()
			# "No" path, and Quit to title during practice, on a fresh device
			DirAccess.remove_absolute(ProjectSettings.globalize_path(CFG))
			game.game_ui.visible = false; game.start_screen.visible = true
			game._on_take_job_pressed(); wait = 0.3
		9:
			game.card_panel._choose(1)   # No, I know the work
			wait = 0.4
		10:
			P("answered No: practice=%s mode=%s asked saved=%s" % [GM.practice, game._card_mode, P_CLASS.was_asked()])
			game._leave_run()
			DirAccess.remove_absolute(ProjectSettings.globalize_path(CFG))
			game.game_ui.visible = false; game.start_screen.visible = true
			game._on_take_job_pressed(); wait = 0.3
		11:
			game.card_panel._choose(0); wait = 0.8
		12:
			game._leave_run()   # Escape → Quit to title, mid-practice
			wait = 0.3
		13:
			P("quit mid-practice: practice=%s in_round=%s coach left=%s fighters=%d burst interval=%s" % [GM.practice, GM.in_round,
				is_instance_valid(game.get_node_or_null("PracticeRound")), TS.targets.size(), DS.burst_interval])
			DirAccess.remove_absolute(ProjectSettings.globalize_path(CFG))
			quit()
	step += 1
	return false
