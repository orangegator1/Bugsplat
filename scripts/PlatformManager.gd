extends Node

var layer: TileMapLayer
var atlas_id: int
var filler_tile: Vector2
enum grow_mode { GROW, GEN, }

const GROW_ANIMATION = preload("res://scenes/growing_tiles_sprite.tscn")

func connect_player_to_platform_manager(player_p: CharacterBody2D) -> void:
	player_p.connect("standing_on_new_layer", set_layer)

func set_layer(l: TileMapLayer) -> void:
	layer = l

func grow(layer_p: TileMapLayer,
	atlas_id_p: int,
	filler_tile_p: Vector2, player: CharacterBody2D) -> bool:

	layer = layer_p
	atlas_id = atlas_id_p
	filler_tile = filler_tile_p

	# Convert player's world position to tile coordinates
	var player_local_pos := layer.to_local(player.global_position)
	var top_pos := layer.local_to_map(player_local_pos)

	# find nearest top tile
	var result := search_nearby(top_pos)
	top_pos = result["top_pos"]
	var below = result["below"]

	var num_tiles = 0
	if layer.preferred_growth == grow_mode.GEN:
		num_tiles = gen_stack(top_pos, below)
	else:
		num_tiles = grow_stack(top_pos)
	num_tiles += int(below)

	# make sure they won't hit the ceiling
	var collider_h = Vector2(0, player.collider.shape.size.y)
	var tile_h = Vector2(0, layer_p.tile_size * num_tiles)
	var new_height = layer.to_local(player.global_position - collider_h - tile_h)
	new_height = layer.local_to_map(new_height)
	var space_overhead := decorative_tile_or_empty_at(new_height)

	# Move the player up
	if num_tiles > 0 and space_overhead:
		var target_y = player.global_position.y - layer_p.tile_size * num_tiles
		print("num_tiles: %s" % num_tiles)
		player.velocity.x = 0
		# align player to tile grid
		# gives coords at center of tile, need to drop half a tile
		var snap = layer.map_to_local(top_pos) + Vector2(0, layer.tile_size / 2)
		var x_delta = snap.x - player_local_pos.x
		# change sprite direction if changing direction
		# tween player x to tile grid
		var dir = sign(x_delta) if abs(x_delta) > layer.tile_size / 4 else 0
		var tween = create_tween()
		player.set_tween_flags("x", tween, dir)
		tween.tween_property(player, "global_position", snap, 0.06 * abs(x_delta))
		await tween.finished
		# grow
		tween = create_tween()
		player.set_tween_flags("y", tween)
		tween.set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		tween.tween_property(player, "global_position:y", target_y, 0.5 * num_tiles)

		# growing animation
		var anim = GROW_ANIMATION.instantiate()
		get_parent().add_child(anim)
		anim.global_position = layer.map_to_local(new_height + Vector2i(0, num_tiles))

		# consider as a coding exercise, instead of calling the whole function again
		# use 'await tween.finished' in each function to set_cell and draw the tiles
		if layer.preferred_growth == grow_mode.GEN:
			tween.finished.connect(gen_stack.bind(top_pos, below, true))
		else:
			tween.finished.connect(grow_stack.bind(top_pos, true))
		return true
	else:
		return false


func gen_stack(top_pos: Vector2i, below: bool, draw := false) -> int:
	var new_pos = top_pos + Vector2i(0, -int(below))
	var stack_atlas: int = layer.stack_atlas_id.pick_random()
	var first = true

	for coords in layer.mid_tiles:
		if draw:
			layer.set_cell(new_pos, stack_atlas, coords)
		new_pos += Vector2i(0, -1)

	new_pos = top_pos + Vector2i(-1, -int(below))
	for coords in layer.left_tiles:
		# render a different tile if not on the ground
		if first and decorative_tile_or_empty_at(new_pos + Vector2i(0, 1)):
			coords = layer.left_alt_bot_tile
		if draw:
			layer.set_cell(new_pos, stack_atlas, coords)
		new_pos += Vector2i(0, -1)
		first = false

	first = true
	new_pos = top_pos + Vector2i(1, -int(below))
	for coords in layer.right_tiles:
		# render a different tile if not on the ground
		if first and decorative_tile_or_empty_at(new_pos + Vector2i(0, 1)):
			coords = layer.right_alt_bot_tile
		if draw:
			layer.set_cell(new_pos, stack_atlas, coords)
		new_pos += Vector2i(0, -1)
		first = false

	return layer.mid_tiles.size() - 1


func grow_stack(top_pos: Vector2i, draw := false) -> int:
	var height = 0
	var new_pos = top_pos
	if layer.get_cell_source_id(top_pos) != -1:
		var top_atlas_coords := layer.get_cell_atlas_coords(top_pos)
		height += int(!decorative_tile_or_empty_at(new_pos))
		new_pos += Vector2i(0, -1)
		if draw:
			layer.set_cell(new_pos, atlas_id, top_atlas_coords)

	var mid_pos := top_pos + Vector2i(0, 1)
	if layer.get_cell_atlas_coords(mid_pos) > Vector2i.ZERO:
		var mid_atlas_coords := layer.get_cell_atlas_coords(mid_pos)
		height += int(!decorative_tile_or_empty_at(new_pos))
		new_pos = mid_pos + Vector2i(0, -1)
		if draw:
			layer.set_cell(new_pos, atlas_id, mid_atlas_coords)

	var bot_pos := mid_pos + Vector2i(0, 1)
	if layer.get_cell_atlas_coords(bot_pos) > Vector2i.ZERO:
		height += int(!decorative_tile_or_empty_at(new_pos))
		if draw:
			layer.set_cell(mid_pos, atlas_id, filler_tile)

	return height


func search_nearby(pos: Vector2i) -> Dictionary:
	# if on a slope or decoration tile there will be
	# a tile coinciding with the player
	var search_pos := pos
	if layer.get_cell_source_id(search_pos) > -1:
		return {"top_pos": search_pos, "below": false}

	# look below
	search_pos.y += 1
	if layer.get_cell_source_id(search_pos) > -1:
		# found below
		return {"top_pos": search_pos, "below": true}
	else:
		# no tile found
		return {"top_pos": Vector2i.ZERO, "below": false}


# takes global position as parameter
func collider_at(global_pos: Vector2) -> bool:
	var pos = layer.to_local(global_pos)
	pos = layer.local_to_map(pos)
	return not decorative_tile_or_empty_at(pos)


# takes TileMapLayer local position as parameter
func decorative_tile_or_empty_at(pos: Vector2i) -> bool:
	var tile_data = layer.get_cell_tile_data(pos)
	if not tile_data:
		return true
	else:
		return tile_data.get_collision_polygons_count(0) == 0

# takes global position as parameter
func center_of_tile_at(global_pos: Vector2, tml: TileMapLayer) -> Vector2:
	# convert to local layer coords
	var pos = tml.to_local(global_pos)
	# convert to tile grid
	pos = tml.local_to_map(pos)
	# get center position of tile in local layer coords
	pos = tml.map_to_local(pos)
	# return as a global position
	return tml.to_global(pos)


func get_vertical_bounds(tml: TileMapLayer) -> Array:
	var rect = tml.get_used_rect()
	var top = rect.position.y * tml.tile_size
	var bot = rect.end.y * tml.tile_size
	return [bot, top]
