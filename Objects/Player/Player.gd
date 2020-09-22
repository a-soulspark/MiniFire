extends Area2D
class_name Player

signal action_chosen(action)

export var Bullet : PackedScene
export var spawn_cell = Vector2()

onready var cell = spawn_cell

var action = []
var move = Vector2()

func _ready():
	hide()
	if name != "Player1" and get_tree().network_peer or name == "Player1": yield(get_tree(), "idle_frame")
	position = Board.cell_to_world(spawn_cell) + Vector2.ONE * Board.CELL_DISTANCE / 2
	$Camera2D.set_as_toplevel(true)
	
	var color = Color.turquoise if !get_tree().network_peer or is_network_master() else Color.crimson
	$Sprite.ready(color)
	$Sprite.self_modulate = lerp(color, Color.white, 0.5)
	
	show()
	
	if get_tree().network_peer: $Camera2D.current = is_network_master()

func _process(_delta):
	if get_tree().network_peer and get_tree().network_peer.get_connection_status() and !is_network_master(): return
	if move.x == 0 and (Input.is_action_just_released('ui_down') and move.y == 1 or Input.is_action_just_released('ui_up') and move.y == -1): move.y = 0
	if move.y == 0 and (Input.is_action_just_released('ui_right') and move.x == 1 or Input.is_action_just_released('ui_left') and move.x == -1): move.x = 0
	var old_move = move
	
	if Input.is_action_just_pressed('ui_down') and cell.y < Board.size - 1: move.y = 1
	elif Input.is_action_just_pressed('ui_up') and cell.y > 0: move.y = -1
	
	if Input.is_action_just_pressed('ui_right') and cell.x < Board.size - 1: move.x = 1
	elif Input.is_action_just_pressed('ui_left') and cell.x > 0: move.x = -1
	
	if Input.is_action_just_pressed('click'):
		var clicked_cell = Board.world_to_cell(get_global_mouse_position())
		var cell_action = _get_action_for_cell(clicked_cell)
		var offset = clicked_cell - cell
		
		match cell_action:
			0: move = offset
			1: _set_action(1, Vector2(clicked_cell))
			2: skip()
	elif Input.is_action_just_pressed('skip'): skip()
	
	$Camera2D.position = lerp(get_viewport_rect().size / 2, position, 0.5)
	if move != old_move: _set_action(0, move)

func _set_action(action_type, data):
	action = [action_type, data]
	emit_signal("action_chosen", action)
	if get_tree().network_peer: rpc('update_action', action_type, data, get_parent().turn_id)

remote func update_action(action_type, data, turn_id):
	if turn_id == get_parent().turn_id: action = [action_type, data]

func skip():
	move = Vector2()
	_set_action(2, null)

func process_turn():
	match action[0]:
		0:
			$Tween.stop_all()
			$Tween.interpolate_property(self, 'position', position, position + action[1] * Board.CELL_DISTANCE, Board.TURN_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT)
			$Tween.interpolate_property(self, 'rotation',  rotation, lerp_angle(rotation, action[1].angle(), 1), Board.TURN_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT)
			$Tween.start()
			cell += action[1]
		1:
			var new_bullet = Bullet.instance()
			new_bullet.direction = (action[1] - cell).normalized()
			new_bullet.modulate = $Sprite.self_modulate
			new_bullet.bullet_owner = self
			get_parent().add_child(new_bullet)
			new_bullet.position = position
			new_bullet.process_turn()
			$Tween.interpolate_property(self, 'rotation',  rotation, lerp_angle(rotation, (action[1] - cell).angle(), 1), Board.TURN_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT)
			$Tween.start()
	
	move = Vector2()
	action = []

func _get_action_for_cell(target_cell):
	var offset = target_cell - cell
	var dst = offset.length_squared()
	if dst > 0 and dst <= 2 and Board.is_cell_valid(target_cell): return 0
	elif offset != Vector2.ZERO: return 1
	else: return 2

remotesync func die(): get_tree().current_scene._player_disconnected(get_tree().get_network_unique_id())
