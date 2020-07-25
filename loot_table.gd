extends Resource

# A LootTable defines a table that holds one or more LootItems/LootTables and it
# can roll to return one or more items.
class_name LootTable

# The name of this loot table.
var name: String
# The probability that this table will be hit. This is used when this table is
# nested within another table.
var probability: int
# Indicates whether this table is unique or not. This is used if the table is
# nested in another and if it is unique it will only be rolled once.
var is_unique: bool
# Indicates whether this table should be rolled every time or not. This is used
# when the table is nested within another table.
var should_drop_always: bool
# Indicates whether this table should be rolled for drops or not. This is used
# when the table is nested within another table.
var is_enabled: bool

# Indicates the amount of items that will be rolled off this table.
var num_of_items_to_roll: int
# The LootItems in this table.
var table_contents: Array = []
# Any unique items are added here when they are hit so that they cannot drop a
# second time.
var unique_items: Array = []

# To create a new table we need to provide it with a name. If we want to nest
# this table then we'll seed to provide the probability, whether its unique,
# whether it should always roll, and whether it's currently enabled or not.
#
# Arguments:
#
# `u_name` - The name of this table.
# `u_probability` - The probability that this table will be hit. This is used when this table is nested within another table.
# `u_unique` - Indicates whether this table is unique or not. This is used if the table is nested in another and if it is unique it will only be rolled once.
# `u_always` - Indicates whether this table should be rolled every time or not. This is used when the table is nested within another table.
# `u_enabled` - Indicates whether this table should be rolled for drops or not. This is used when the table is nested within another table .
func _init(u_name, num_of_items: int, u_probability: int = 10, unique: bool = false, always_drop: bool = false, enabled: bool = true):
	name = u_name
	num_of_items_to_roll = num_of_items
	probability = u_probability
	is_unique = unique
	should_drop_always = always_drop
	is_enabled = enabled

# Adds an item onto this table.
#
# Arguments:
#
# `item` - The LootItem to add to this table.
func add_item(item: LootItem):
	table_contents.append(item)

# Adds a table within this table. This is the same as adding an item but for
# naming sake it exists as its own method.
func add_table(table: LootTable):
	table_contents.append(table)

# Rolls the table (and any nested tables) for LootItems and adds the rolled
# items into the `results` array.
func roll_table():
	# The list of items that have been rolled. We also reset the unique_drops
	# array in case it was populated from previous rolls.
	var rolled_items: Array = []
	unique_items = []
	
	# First we look for items that are always hit. These items are always
	# returned and there is a chance that we can break the `count` limit if the
	# number of always items is greater than the number of items to roll for.
	var num_of_items_always_rolled: int = 0
	for loot in table_contents:
		if loot.should_drop_always and loot.is_enabled:
			add_to_rolled_items(rolled_items, loot)
			num_of_items_always_rolled += 1
	
	# Now after we got all of the always items, we have to see how many more
	# items we can roll for.
	var real_drop_count: int = num_of_items_to_roll - num_of_items_always_rolled
	
	# Roll for more items if we still can.
	if real_drop_count > 0:
		for _i in range(real_drop_count):
			# Find the items in the table that are eligable to be rolled and
			# were not rolled earlier.
			var loot_that_can_be_rolled: Array = []
			var total_probability: int = 0
			for table_content in table_contents:
				if table_content.is_enabled and not table_content.should_drop_always: 
					loot_that_can_be_rolled.append(table_content)
					total_probability += table_content.probability
			
			# We calculate the the number that we'll compare to the probability
			# of the items to decide what item is rolled by picking a random
			# float from 0.0 to the total probabilitiy of all the droppables.
			var hit_value: float = rand_range(0.0, total_probability)
			
			# Now we have to go through the list of droppable items and increase
			# the probability until we find an item that meets the hit_value.
			var running_value: int = 0
			for loot in loot_that_can_be_rolled:
				running_value += loot.probability
				if hit_value < running_value:
					add_to_rolled_items(rolled_items, loot)
					break
	
	# Finally we return the results of the roll.
	return rolled_items

# Since we can nest tables we need to perform some checks before we just add
# items to the results.
#
# Arguments:
#
# `rolled_items` - The array to append the loot to.
# `loot` - The LootItem or LootTable to check.
func add_to_rolled_items(rolled_items: Array, loot):
	# First we only want to proceed if them is not unique or if it is unique it
	# cannot exist in the unique_drops array.
	if not loot.is_unique or not unique_items.has(loot):
		# If this is a new unique drop then we add it to the unique drops array.
		if loot.is_unique: unique_items.append(loot)
		
		# Since we could be rolling a table we want to keep the loot to add in
		# an array so we can loop through and emit signals without extra work.
		var items_to_add = [loot]
		
		# If the item has a `roll_table` method then it is a LootTable and 
		# we need to call `roll_table` recursively and add the results to 
		# the array.
		if loot.has_method("roll_table"): items_to_add = loot.roll_table()
		
		# For each item rolled we add it to the `rolled_items` array and emit
		# the hit signal.
		for loot_item in items_to_add:
			rolled_items.append(loot_item)
			loot_item.emit_signal("hit", self)
