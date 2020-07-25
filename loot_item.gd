extends Resource

# A LootItem defines an item that goes on a DropTable and it contain's an item's
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
# Indicates whether this item is eligable to be rolled or not.
var is_enabled: bool

# The signal that gets emitted when this item is hit on the drop table.
signal hit

# To create a LootItem we need the item's data, its probability, whether it's
# unique or not, if it should always be rolled, and wehterh it's currently
# enabled or not.
#
# Arguments:
#
# `u_item` - The data that represents the properties of this item.
# `u_probability` - The probability that this item will be selected.
# `unique` - Indicates whether this item is unique or not. A unique item will only drop once per roll.
# `always` - Indicates whether this item should drop every time or not.
# `enabled` - Indicates whether this item is eligable to be rolled or not.
func _init(u_item, u_probability: int, unique: bool = false, always_drop: bool = false, enabled: bool = true):
	item = u_item
	probability = u_probability
	is_unique = unique
	should_drop_always = always_drop
	is_enabled = enabled
