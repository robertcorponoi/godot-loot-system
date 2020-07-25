extends Spatial

func _ready():
	# We need to call `randomize()` so that we don't get the same results every # # time because random isn't really random.
	randomize() 
	
	# Create a loot table named "Boss" that's meant to roll 3 items at a time.
	var boss_loot_table: LootTable = LootTable.new("Boss", 2)
	
	# Create our nested tables and add them to the Boss table.
	var rare_drop_table: LootTable = LootTable.new("Rare", 1, 10, false, false, true)
	var common_drop_table: LootTable = LootTable.new("Common", 1, 30, false, false, true)
	
	boss_loot_table.add_table(rare_drop_table)
	boss_loot_table.add_table(common_drop_table)

	# Define various items and create LootItem instances of them with the item
	# data as the first parameter.
	# None of the items are unique or set to drop always for simplicity.
	var sword: Dictionary = {
		"name": "Sword",
		"attack": 5,
		"defence": 3
	}
	var sword_loot_item: LootItem = LootItem.new(sword, 10, false, false, true)
	
	var shield: Dictionary = {
		"name": "Shield",
		"attack": 0,
		"defence": 5
	}
	var shield_loot_item: LootItem = LootItem.new(shield, 10, false, false, true)
	
	var bow: Dictionary = {
		"name": "Bow",
		"attack": 5,
		"defence": 1
	}
	var bow_loot_item: LootItem = LootItem.new(bow, 10, false, false, true)
	
	var staff: Dictionary = {
		"name": "Staff",
		"attack": 7,
		"defence": 2
	}
	var staff_loot_item: LootItem = LootItem.new(staff, 10, false, false, true)
	
	var helmet: Dictionary = {
		"name": "Helmet",
		"attack": 0,
		"defence": 7
	}
	var helmet_loot_item: LootItem = LootItem.new(helmet, 10, false, false, true)
	
	var platebody: Dictionary = {
		"name": "Platebody",
		"attack": 1,
		"defence": 5
	}
	var platebody_loot_item: LootItem = LootItem.new(platebody, 10, false, false, true)
	
	var boots: Dictionary = {
		"name": "Boots",
		"attack": 1,
		"defence": 5
	}
	var boots_loot_item: LootItem = LootItem.new(boots, 10, false, false, true)
	
	var belt: Dictionary = {
		"name": "Belt",
		"attack": 1,
		"defence": 5
	}
	var belt_loot_item: LootItem = LootItem.new(belt, 10, false, false, true)
	
	var battleaxe: Dictionary = {
		"name": "Battleaxe",
		"attack": 1,
		"defence": 5
	}
	var battleaxe_loot_item: LootItem = LootItem.new(battleaxe, 10, false, false, true)

	# Add the created items 3
#	boss_loot_table.add_item(sword_loot_item)
#	boss_loot_table.add_item(shield_loot_item)
#	boss_loot_table.add_item(bow_loot_item)
#	boss_loot_table.add_item(staff_loot_item)
#	boss_loot_table.add_item(helmet_loot_item)

	common_drop_table.add_item(sword_loot_item)
	common_drop_table.add_item(shield_loot_item)
	common_drop_table.add_item(bow_loot_item)
	rare_drop_table.add_item(staff_loot_item)
	rare_drop_table.add_item(helmet_loot_item)
	rare_drop_table.add_item(platebody_loot_item)
	
	# Roll for items.
	var roll_results: Array = boss_loot_table.roll_table()
	
	# Go through each of the rolled items and print out what we got.
	for rolled_item in roll_results:
		print("Rolled: ", rolled_item.item.name)
