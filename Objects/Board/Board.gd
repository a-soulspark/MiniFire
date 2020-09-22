extends Sprite

const PIXEL_SCALE = 4
const CELL_SIZE = 8 * PIXEL_SCALE
const CELL_GAP = PIXEL_SCALE
const CELL_DISTANCE = CELL_SIZE + CELL_GAP
const TURN_DURATION = 0.2

export var size : int = 8
var current_scene

func _ready():
	hide()
	scale = Vector2.ONE * PIXEL_SCALE
	region_rect.size = Vector2.ONE * (CELL_DISTANCE * size + CELL_GAP) / PIXEL_SCALE
	call_deferred("reparent")

func reparent():
	current_scene = get_tree().current_scene
	if current_scene.has_signal("game_started"): current_scene = yield(current_scene, "game_started")
	
	get_parent().remove_child(self)
	var back_sibling = current_scene.get_node_or_null("Background")
	if !back_sibling: return
	
	current_scene.add_child_below_node(back_sibling, self)
	
	position = get_viewport_rect().size / 2
	show()

func reset():
	var root = get_tree().root
	get_parent().remove_child(self)
	root.add_child(self)
	call_deferred("reparent")

func cell_to_world(cell)->Vector2: return  position + cell * CELL_DISTANCE + Vector2.ONE * CELL_GAP / 2 - region_rect.size / 2 * PIXEL_SCALE

#cell = ((world to board(point) - vec(cell gap / 2) / cell dst).floor()
#floor(cell) = (world to board(point) - vec(cell gap / 2) / cell dst)
#world to board(point) - vec(cell gap / 2) = floor(cell) * cell dst
#world to board(point) = floor(cell) * cell dst + vec(cell gap / 2)
#
#point - position + region rect size / 2 * pixel scale = cell * cell dst + vec(cell gap / 2)
#point = cell * cell dst + vec(cell gap / 2) + position - region rect size / 2 * pixel scale
#
#world to board(point) = point - position + region rect.size / 2 * pixel scale

func world_to_board(point)->Vector2: return point - position + region_rect.size / 2 * PIXEL_SCALE

func world_to_cell(point)->Vector2: return ((world_to_board(point) - Vector2.ONE * CELL_GAP / 2) / CELL_DISTANCE).floor()

func snap_to_board(point)->Vector2: return world_to_board(point - Vector2.ONE * CELL_DISTANCE / 2).snapped(Vector2.ONE * CELL_DISTANCE) + position - region_rect.size / 2 * PIXEL_SCALE

func is_cell_valid(cell): return cell.x >= 0 and cell.x < size and cell.y >= 0 and cell.y < size

func is_server(): return get_tree().network_peer and get_tree().is_network_server() or !get_tree().network_peer
