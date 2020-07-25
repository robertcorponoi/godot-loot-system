<p align="center">
  <img width="500" height="250" src="https://raw.githubusercontent.com/robertcorponoi/graphics/master/tutorials/creating-a-loot-system/chest.png">
</p>

<h1 align="center">Creating Loot Systems</h1>

<p align="center">A demo repository for an article on creating loot systems.<p>

The contents of this README are the same as the article on my [website](https://robertcorponoi.com/creating-loot-systems/). If you came from the website, you can just download or clone the repo and import the project in Godot to see the loot system in action.

## Getting Started

If you're making a game that involves the player killing and looting enemies or looting chests then you're probably wondering of a good way to create a loot system for it. There's a couple approaches to this. You could of course just have an array of items that the enemy or chest drops but the problem with that everything has the same weight. Imagine that you wanted a monster to drop some coins and maybe a piece of armor but there's varying levels of armor. You want the boss to drop a low level piece of armor most of the time you want to give the player something to work towards if they want to so ever so often you want a monster to drop a higher level piece of armor. In order to accomplish this you'll need to create a loot table with weighted options but it's actually easier than it looks and it can be done in two parts. This article was inspired by [this](https://www.codeproject.com/Articles/420046/Loot-Tables-Random-Maps-and-Monsters-Part-I) so check it out to see a slightly different approach (in C#).

**Note:** While this article covers how to do it in Godot, this can be easily ported to any other engine as its just 2 simple classes.

## Part 1 - The Items

The first things we need to do is create the class for the items that go in the loot tables. For this, we need to decide what basic properties all of our items will need and it can be boiled down to the following:

- **probability**: The single most important part of our item is the probability. This is just a number, any number you wish. A probability of 1 is very low and chances are the item won't be rolled often while a probability of 100 me
ans that item will probably be rolled more often. An important thing to note is that this is not a percentage so don't think of it that way. Probability can be 5 or 4500, it's all relative to the probabilities of the other items on the loot table.

- **is_unique**: This is used to indicates whether an item is unique or not. If an item is unique then it cannot be rolled twice. For example, if you have a piece of rare armor on your drop table you don't want it to be able to be rolled twice while on the other hand you might a drop of leather boots to drop more than once.

- **always_drop**: This indicates whether the item should always be rolled. For example, your monster might drop bones and that would be a drop that always happens.

- **is_enabled**: This indicates whether the item is currently able to be rolled or not. This enables you to enable/disable drops whenever you wish.

- **item**: The data of the item to put on the loot table. Since there's so many ways to represent the data in your game it all gets set in this property in any way you wish. I personally prefer using a dictionary with the name and stats of the item but you could also just change `item` to `id` and use and id that you can check against a database when it's rolled.

Now that we have our item's properties, let's put them in a `LootItem` class in a new script named `loot_item.gd`:

```gdscript
extends Resource

# A LootItem defines an item that goes on a DropTable and it contains an item's
# properties and it's chance of being hit along with other variables that define
# how often it gets hit.
class_name LootItem

# The data that represents the properties of this item.
var item
# The probability that this item will be selected.
var probability: int
# Indicates whether this item is unique or not. A unique item will only drop
# once per roll.
var is_unique: bool
# Indicates whether this item should drop every time or not.
var should_drop_always: bool
# Indicates whether this item is eligible to be rolled or not.
var is_enabled: bool

# To create a LootItem we need the item's data, its probability, whether it's
# unique or not, if it should always be rolled, and whether it's currently
# enabled or not.
#
# Arguments:
#
# `u_item` - The data that represents the properties of this item.
# `u_probability` - The probability that this item will be selected.
# `unique` - Indicates whether this item is unique or not. A unique item will only drop once per roll.
# `always` - Indicates whether this item should drop every time or not.
# `enabled` - Indicates whether this item is eligible to be rolled or not.
func _init(u_item, u_probability: int, unique: bool = false, always_drop: bool = false, enabled: bool = true):
	item = u_item
	probability = u_probability
	is_unique = unique
	should_drop_always = always_drop
	is_enabled = enabled
```

Just like that, the first part is done. Notice how there's nothing fancy in the `LootItem` class, it's just a collection of properties that the loot table will use to decide if this item is rolled or not.

## Part 2 - The Table

The loot table is what's going to be rolled and will decide which items should be rolled. Let's see what properties we'll need out of our loot tables:

- **name**: While this isn't necessary it's nice to give some context to our table (kind of like the item is defined by its item property).

- **num_of_items_to_roll**: This is the most important part of the table, this lets the table know how many items that it should roll for.

- **table_contents**: This is where all of the items in the table are stored.

- **unique_drops**: We need to keep track of which unique drops have been rolled because we do not want a unique drop to be rolled twice.

Alright that's all of the basic properties of the table to let's set up the basic properties and constructor in a class named `LootTable` in a file named `loot_table.gd`:

```gdscript
extends Resource

# A LootTable defines a table that holds one or more LootItems and it
# can roll to return one or more items.
class_name LootTable

# The name of this loot table.
var name: String
# Indicates the amount of items that will be rolled off this table.
var num_of_items_to_roll: int
# The LootItems in this table.
var table_contents: Array = []
# Any unique drops are added here when they are hit so that they cannot drop a
# second time.
var unique_drops: Array = []

# To create a new table we need to provide it with a name and specify the amount
# of items within it.
#
# Arguments:
#
# `u_name` - The name of this table.
# `num_items` - The amount of items that this table should roll for.
func _init(u_name, num_of_items: int):
	name = u_name
	num_of_items_to_roll = num_of_items
```

Simple enough so far right? Well now we need to create a method to add `LootItem`s to the `table_contents` array:

```gdscript
# Adds an item onto this table.
#
# Arguments:
#
# `item` - The LootItem to add to this table.
func add_item(item: LootItem):
	table_contents.append(item)
```

All we do above is add an item to the loot table which is really just adding an item to the end of the `table_contents` array.

Now that the user can add items to the table, let's get into the more complicated part, rolling for items. Here's an overview of what we need to do when we roll for items:

1. We need to create an array to keep track of the items that have been rolled and we need to reset our `unique_drops` array in case it contains data from previous rolls.

2. We need to check the table for items that have `should_drop_always` set to `true`. This is because these items need to always drop so we don't need to roll for them.

3. Get a count of the amount of items we need to roll for. This isn't just the flat out `num_of_items_to_roll` because of the step above. We need to get the amount of items to roll for after the always drops have been found. For example, let's say that you have your table set to roll for 4 items. However, in your table, there's 2 items that are set to always. In the step above we set these items aside and now the number of items to roll for is 2 not 4.

4. Now's the fun part, we have to do some looping. The first loop is going to run as many times as we have items left to drop. Then inside it we loop through each item and check to see if it's enabled and that it doesn't already exist in the `unique_drops` array. After we get a list of the items that are eligible to be rolled for, we calculate the `hit_probability` which is going to be a random number from 0 to the total probability of each item in the list of items that can be rolled. We then loop over all of the items that can be rolled for and keep a running tally of probability while we check to see if the `hit_probability` value is less than this running value. Let's take this and expand on it to make sure that you fully understand it.

Let's say that for example you have the following 4 items in your loot table:

| Item   | Probability |
|--------|-------------|
| Sword  | 10          |
| Shield | 5           |
| Bow    | 15          |
| Boots  | 30          |

These 4 items have a combined probability of 60. If you run a random number generator to get 2 values from 0 to 60 you might get something like: 42 and 15.

Now we loop through each of these items and keep a running tally on their probability while checking to see if the hit value is less than this running tally.

Let's go through the loop:

| Loop Item | Running Probability Tally | Hit Probability |
|-----------|---------------------------|-----------------|
| Sword     | 10                        | 42              |
| Shield    | 15                        | 42              |
| Bow       | 30                        | 42              |
| Boots     | 60                        | 42              |

Now if we're checking if `hit_probability < running_probability_tally` we'll check:

1. `42 < 10` - `false`
2. `42 < 15` - `false`
3. `42 < 30` - `false`
4. `42 < 60` - `true`

This means that we'll get boots as a drop! Let's run through this again with the other random value, 15.

1. `15 < 10` - `false`
2. `15 < 15` - `false`
3. `15 < 30` - `true`

Now we get a bow as our drop.

Let's get into the code and see how it's done now that we got the theory set up. Let's add a new method below our constructor:

```gdscript
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
			# Find the items in the table that are eligible to be rolled and
			# were not rolled earlier.
			var loot_that_can_be_rolled: Array = []
			var total_probability = 0
			for table_content in table_contents:
				if table_content.is_enabled and not table_content.should_drop_always: 
					loot_that_can_be_rolled.append(table_content)
					total_probability += table_content.probability
			
			# We calculate the the number that we'll compare to the probability
			# of the items to decide what item is rolled by picking a random
			# float from 0.0 to the total probability of all the items that can be rolled.
			var hit_value: float = rand_range(0.0, total_probability)
			
			# Now we have to go through the list of items that can be rolled and increase
			# the probability until we find an item that meets the hit_value.
			var running_value: int = 0
			for loot in loot_that_can_be_rolled:
				running_value += loot.probability
				if hit_value < running_value:
					add_to_rolled_items(rolled_items, loot)
					break
	
	# Finally we return the results of the roll.
	return rolled_items
```

Everything above is what we covered before but you'll notice something missing, what's `add_to_rolled_items`? This is the method that checks if the item is unique and if so checks the unique items array to see if this item already exists there. Otherwise it adds it to the `rolled_items` array. You're probably wondering why this method is even separate but we'll add some more advanced functionality later.

```gdscript
# Since we can nest tables we need to perform some checks before we just add
# items to the results.
#
# Arguments:
#
# `rolled_items` - The array to append the loot to.
# `loot` - The LootItem to check.
func add_to_rolled_items(rolled_items: Array, loot):
	# First we only want to proceed if them is not unique or if it is unique it
	# cannot exist in the unique_drops array.
	if not loot.is_unique or not unique_items.has(loot):
		# If this is a new unique drop then we add it to the unique drops array.
		if loot.is_unique: unique_items.append(loot)
		
		# We add the item to the results array and emit the signal for when an 
		# item has been hit.
		add_to_rolled_items.append(loot)
```

That's all for the current functionality. With everything we've covered we can create loot items and add them to a loot table and roll for items, which is what we'll do next.

## Let's Roll!

Alright now that we have the scaffolding let's make a demo. Create a new script named `main.gd` and let's get started. Here's what we have to do:

1. Create an instance of a `LootTable`.
2. Create instances of `LootItem` for all of the items we want to add to the table created in step 1.
3. Roll for items!

Pretty simple right? Let's get it in code:

```gdscript
extends Node

# Run this on ready so we can see the results right away.
func _ready():
	# We need to call `randomize()` so that we don't get the same results every # # time because random isn't really random.
	randomize() 

	# Create a loot table named "Boss" that's meant to roll 3 items at a time.
	var boss_loot_table: LootTable = LootTable.new("Boss", 3)

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

	# Add the created items 3
	boss_loot_table.add_item(sword_loot_item)
	boss_loot_table.add_item(shield_loot_item)
	boss_loot_table.add_item(bow_loot_item)
	boss_loot_table.add_item(staff_loot_item)
	boss_loot_table.add_item(helmet_loot_item)

	# Roll for items.
	var roll_results: Array = boss_loot_table.roll_table()

	# Go through each of the rolled items and print out what we got.
	for rolled_item in roll_results:
		print("Rolled: ", rolled_item.item.name)
```

The results of running the above should be something like:

- Helmet
- Bow
- Shield

Of course, you'll get different results than me and you'll get different results each time you run it (unless you take out `randomize`, `randomize` guarantees we get a different number each time from `rand_range`).


## What's Next?

The current setup works just fine for a table with items but what if you wanted to nest tables in tables?

This might sound strange at first but think about it. Imagine you have a table that has super rare loot but you want people to maybe get lucky and roll this table when they kill a monster. You don't want to put the monster's drops on it because it only has super rare items. The solution is to create a table with a low probability and set it as an item of the monster table. This makes it so that when the monster table is rolled, the super rare table has a chance of being rolled instead of one of the items of the monster.

Here's a simple diagram to illustrate it:

![Nested Tables](https://raw.githubusercontent.com/robertcorponoi/graphics/master/tutorials/creating-a-loot-system/nested-tables.png)

You can see that when you roll the monster table you have a chance to get a sword, a shield, or a drop off the rare loot table with the chances being what probabilities you choose to set.

So, at this point you might be asking how we can implement it? Well it's actually pretty simple, so let's take it one step at a time:

1. Copy over the properties from `LootItem`. The `LootTable` class now needs its own `probability`, `is_unique`, `should_drop_always`, and `is_enabled` properties:

```gdscript
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
```

2. Add the properties to the constructor like in `LootItem`:

```gdscript
# To create a new table we need to provide it with a name. If we want to nest
# this table then we'll seed to provide the probability, whether its unique,
# whether it should always roll, and whether it's currently enabled or not.
#
# Arguments:
#
# `u_name` - The name of this table.
# `u_probability` - The probability that this table will be hit. This is used when this table is nested within another table.
# `unique` - Indicates whether this table is unique or not. This is used if the table is nested in another and if it is unique it will only be rolled once.
# `always_drop` - Indicates whether this table should be rolled every time or not. This is used when the table is nested within another table.
# `enabled` - Indicates whether this table should be rolled for drops or not. This is used when the table is nested within another table .
func _init(u_name, num_of_items: int, u_probability: int = 10, unique: bool = false, always_drop: bool = false, enabled: bool = true):
	name = u_name
	num_of_items_to_roll = num_of_items
	probability = u_probability
	is_unique = unique
	should_drop_always = always_drop
	is_enabled = enabled
```

3. Optionally create a method that does the same thing as `add_item` but named `add_table` to be more verbose and easy to read in the code later.

```gdscript
# Adds a table within this table. This is the same as adding an item but for
# naming sake it exists as its own method.
func add_table(table: LootTable):
	table_contents.append(table)
```

3. Modify the `add_to_rolled_items` method to handle tables recursively by checking if the item that's rolled is a table (by having the `roll_table` method) and if so we call that table's `roll_table` method and add the rolled item/s to ours.

```gdscript
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
			loot.emit_signal("hit")
```

That's all for nesting tables, the full `LootTable` class with nested table support can be found below:

```gdscript
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
# `unique` - Indicates whether this table is unique or not. This is used if the table is nested in another and if it is unique it will only be rolled once.
# `always_drop` - Indicates whether this table should be rolled every time or not. This is used when the table is nested within another table.
# `enabled` - Indicates whether this table should be rolled for drops or not. This is used when the table is nested within another table .
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
	
	# For each table or item added we now emit the pre-roll signal.
	for loot in table_contents: loot.emit_signal("pre_roll")
	
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
			# Find the items in the table that are eligible to be rolled and
			# were not rolled earlier.
			var loot_that_can_be_rolled: Array = []
			var total_probability = 0
			for table_content in table_contents:
				if table_content.is_enabled and not table_content.should_drop_always: 
					loot_that_can_be_rolled.append(table_content)
					total_probability += table_content.probability
			
			# We calculate the the number that we'll compare to the probability
			# of the items to decide what item is rolled by picking a random
			# float from 0.0 to the total probability of all the items that can be rolled.
			var hit_value: float = rand_range(0.0, total_probability)
			
			# Now we have to go through the list of items that can be rolled and increase
			# the probability until we find an item that meets the hit_value.
			var running_value: int = 0
			for loot in loot_that_can_be_rolled:
				running_value += loot.probability
				if hit_value < running_value:
					add_to_rolled_items(rolled_items, loot)
					break
	
	# Now for each item we rolled we dispatch the post roll signal.
	for o in rolled_items: o.emit_signal("post_roll")
	
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
			loot.emit_signal("hit")
```

Now let's modify our `main.gd` so we can test this out:

1. Let's start out by creating a couple `LootTables` that will be nested in our Boss table. We'll give the Common table a 3x greater chance to be hit than the Rare drop table.

```gdscript
	...
	# Create our nested tables and add them to the Boss table.
	var common_drop_table: LootTable = LootTable.new("Common", 1, 30, false, false, true)
	var rare_drop_table: LootTable = LootTable.new("Rare", 1, 10, false, false, true)
	
	boss_loot_table.add_table(common_drop_table)
	boss_loot_table.add_table(rare_drop_table)
	...
```

2. Instead of adding the items directly to the Boss table, let's split them up onto the two sub-tables.

```gdscript
    ...
	common_drop_table.add_item(sword_loot_item)
	common_drop_table.add_item(shield_loot_item)
	common_drop_table.add_item(bow_loot_item)
	rare_drop_table.add_item(staff_loot_item)
	rare_drop_table.add_item(helmet_loot_item)
	rare_drop_table.add_item(platebody_loot_item)
	...
```

3. Now we press play and see the results of the roll! In my demo I set the Boss table to drop 2 items and my 2 ended up being:

 - Staff
 - Bow

 Now this time we actually hit the rare drop table, but in another roll I got:

 - Bow
 - Sword

 So that time I hit the common table for both items.

## Bonus!

In the article that gave me the inspiration for this, the author implements events for the loot items and table and I figured it may be useful to someone so here's a bonus section for it. So an event based system in Godot would involve signals and we're going to create a custom signal that will get emitted when an item on the drop table is it or even when a table within a table is hit. One example of when this could be useful is in a multiplayer game if you want to notify every player when someone gets a super rare drop.

So this is actually pretty easy. To do this, open up your `loot_item` class and add the `hit` signal below the variables.

```gdscript
...
var is_enabled: bool

# The signal that gets emitted when this item is hit on the drop table.
signal hit
...
```

Now in the `loot_table` class, we want to go down to our `add_to_rolled_items` method and right below where we append the the item to the `rolled_items` array and emit the signal like so:

```gdscript
# For each item rolled we add it to the `rolled_items` array and emit
# the hit signal.
for loot_item in items_to_add:
	rolled_items.append(loot_item)
	loot.emit_signal("hit")
```

Finally, head over to the `main.gd` file we created to test our loot system and add a signal to one of the items (I picked the shield) like so:

```gdscript
var shield: Dictionary = {
	"name": "Shield",
	"attack": 0,
	"defence": 5
}
var shield_loot_item: LootItem = LootItem.new(shield, 10, false, false, true)

# Connect the shield's hit signal to a function named "_on_shield_rolled".
shield_loot_item.connect("hit", self, "_on_shield_rolled")

# This function is going to print to the console when we roll the shield.
func _on_shield_rolled():
	print("We rolled a shield!")
```

Just make sure you have a function in the `main.gd` file that you can attach the function to as shown above whenever you roll the shield you should see that message print to the console.

Of course this means that if you have nested tables then the signal will be emitted twice because the sub table will roll it and then the main table also will so the signal gets emitted twice so you can change the `emit_signal` to also include the table object like so:

```gdscript
# For each item rolled we add it to the `rolled_items` array and emit
# the hit signal.
for loot_item in items_to_add:
	rolled_items.append(loot_item)
	loot.emit_signal("hit", self)
```

Then, in your `_on_shield_rolled` function you can check to see if the main boss table rolled it like so:

```gdscript
# This function is going to print to the console when we roll the shield.
func _on_shield_rolled(table: LootTable):
	if table.name == "Boss": print("We rolled a shield!")
```

There's other ways this could be handled but I'll leave that as a challenge to you, the above gets you 95% of the way there.

 ## Conclusion

 Now that you have the basic workings of a loot system, the challenge for you is to figure out how to best implement it in your game. You could for example not provide any item definitions when creating items but instead just provide an id of an item that links to an id of a resource somewhere else like a database. Also since the loot items and tables are resources you could make your items into resources in Godot (sword.tres, shield.tres, etc) and on another class you could ask for an export of items/tables so you don't have to do it by code. I might expand on these concepts in a later tutorial but for now let me know if you have any questions and I'll gladly answer them!
