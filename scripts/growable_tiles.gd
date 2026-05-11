class_name GrowableTile extends TileMapLayer

enum grow_mode { GEN, GROW, }
@export var preferred_growth: grow_mode
@export var tile_size := 16
@export var friction := 500
@export var atlas_id := 1
@export var filler_tile := Vector2i(0,0)

# pre-fab stacks of tiles, can be any height, filled from bottom up
@export var stack_atlas_id: Array[int] = [ 1, 2, ]
@export var left_tiles: Array[Vector2i] = [
	Vector2i(0,2),
	Vector2i(0,1),
	Vector2i(0,0),
]
@export var mid_tiles: Array[Vector2i] = [
	Vector2i(1,2),
	Vector2i(1,1),
	Vector2i(1,0),
]
@export var right_tiles: Array[Vector2i] = [
	Vector2i(2,2),
	Vector2i(2,1),
	Vector2i(2,0),
]
@export var left_alt_bot_tile := Vector2i(0,1)
@export var right_alt_bot_tile := Vector2i(2,1)
