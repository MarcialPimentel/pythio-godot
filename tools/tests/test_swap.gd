extends SceneTree
# Full spell bar (#67): a new spell replaces one you choose (with a Back button), rank-ups
# still work, Skip gives +max mana for the run, and "build complete" still fires once.
var game; var f := 0; var GM; var DS; var SS; var step := 0; var wait := 0.0; var complete := 0
func _initialize():
	game = load("res://scenes/Game.tscn").instantiate()
	root.add_child.call_deferred(game)
func P(s): print("TEST: ", s)
func ids(list): return list.map(func(s): return s.id if s is SpellData else str(s))
func lib(id): return SS.get_library_spell(id)
func badges(): return game.card_panel._cards.size()

func _process(d):
	f += 1
	wait -= d
	if wait > 0: return false
	match step:
		0:
			if f < 3: return false
			GM = root.get_node("GameManager"); DS = root.get_node("DraftSystem"); SS = root.get_node("SpellSystem")
			DS.build_complete.connect(func(): complete += 1)
			root.get_node("DifficultySystem").base_dps = 0.0; root.get_node("DifficultySystem").burst_interval = 999.0
			game._on_start_pressed(); wait = 0.2
		1:
			game.card_panel._choose(0); wait = 0.6   # Mending
		2:
			SS.set_spellbook_ids(PackedStringArray(["heal", "flash_heal", "binding_heal", "chain_heal"]))
			P("bar full: %s spells_full=%s" % [ids(SS.spells), DS.spells_full()])
			var o: Array = DS.make_offers()
			P("offers with a full bar include new spells (swaps)=%s: %s" % [o.any(func(s): return not s.is_passive() and SS.owned_rank(s.family()) == 0), ids(o)])
			game._show_spell_pick([lib("renew"), lib("heal_2"), lib("mana_conduit")], 3); wait = 0.4
		3:
			var cards: Array = game._card_options
			P("pick screen: options=%s (3 offers + Skip) needs_swap=%s" % [ids(cards), cards.slice(0, 3).map(func(s): return DS.needs_swap(s))])
			P("cards: %s" % [game.card_panel._cards.size()])
			game.card_panel._choose(0); wait = 0.5   # Renew → bar is full → choose what it replaces
		4:
			P("swap screen: visible=%s mode=%s options=%s back button=%s" % [game.card_panel.visible, game._card_mode, ids(game._card_options), game.card_panel._back.visible])
			game.card_panel._on_back(); wait = 0.5
		5:
			P("Back → offers again: mode=%s options=%s spellbook unchanged=%s" % [game._card_mode, ids(game._card_options), ids(SS.spells)])
			game.card_panel._choose(0); wait = 0.5
		6:
			game.card_panel._choose(2); wait = 0.6   # replace Binding Heal (slot E)
		7:
			P("RESULT swapped: spellbook=%s (renew in Binding Heal's slot 3=%s) contract screen=%s" % [ids(SS.spells), SS.spells[2].id == "renew", game.party_choice_panel.visible])
			# Rank-up with a full bar: no swap screen
			game._show_spell_pick([lib("heal_2"), lib("lifebloom"), lib("mana_conduit")], 5); wait = 0.4
		8:
			game.card_panel._choose(0); wait = 0.6
		9:
			P("rank-up with a full bar → no swap screen: spellbook=%s mode='%s'" % [ids(SS.spells), game._card_mode])
			# Skip
			var before: float = GM.max_mana
			game._show_spell_pick([lib("lifebloom"), lib("overgrowth"), lib("mana_conduit")], 7); wait = 0.4
			set_meta("before", before)
		10:
			game.card_panel._choose(3); wait = 0.6   # Skip
		11:
			var before: float = get_meta("before")
			P("RESULT skip: max mana %.0f → %.0f (+10), bonus=%.0f, spellbook unchanged=%s" % [before, GM.max_mana, GM.bonus_max_mana, ids(SS.spells)])
			GM.end_round(true)
			P("next round's max mana keeps the bonus: %.0f = %.0f + 10" % [GM.max_mana, root.get_node("DifficultySystem").get_max_mana(GM.current_round)])
			# Build complete still fires once with swaps on (full + no rank-ups left)
			for id in ["heal_3", "mana_conduit", "aura_of_mending", "second_wind"]:
				SS.add_spell(lib(id))
			SS.set_spellbook_ids(PackedStringArray(["heal_3", "flash_heal", "renew", "chain_heal", "mana_conduit", "overflow", "second_wind"]))
			SS.add_spell(lib("rejuvenation"))
			var a = DS.offers_after_round(9); var b = DS.offers_after_round(11)
			P("RESULT full + ranked: build complete count=%d (1), offers still come (swaps)=%s" % [complete, not a.is_empty() and not b.is_empty()])
			quit()
	step += 1
	return false
