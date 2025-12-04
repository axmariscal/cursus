extends Node

# High-level game/run state manager
# This persists the entire run, similar to Balatro's RunManager

var current_ante := 1
var max_ante := 20

var team = []            # your runners
var deck = []            # race event cards
var jokers = []          # permanent runner modifiers
var shop_inventory = []  # practice/shop selections

var seed = 0             # run RNG seed
var run_active := false


func start_new_run():
	seed = randi()
	randomize()
	current_ante = 1
	run_active = true
	team.clear()
	deck.clear()
	jokers.clear()
	shop_inventory.clear()
	print("New run started with seed: ", seed)


func advance_ante():
	current_ante += 1
	print("Advanced to ante ", current_ante)
