extends Sprite

onready var player = $"../Player1" if Board.is_server() else $"../Player2"
var cell = Vector2()
var turn_playing

func _ready():
	player.connect("action_chosen", self, "_on_player_acted")
	scale = Vector2.ONE * Board.PIXEL_SCALE

func _process(_delta):
	if turn_playing: return
	
	position = Board.snap_to_board(get_global_mouse_position() - Vector2.ONE * Board.CELL_GAP / 2)
	cell = Board.world_to_cell(position + Vector2.ONE * Board.CELL_GAP)
	
	if player.action.empty():
		var action = player._get_action_for_cell(cell)
		_set_color_from_action(action)

func _set_color_from_action(action):
	match action:
		0:
			modulate = Color('#3bff80')
		1:
			modulate = Color('#ff3b3b')
		2:
			modulate = Color('#3bd5ff')

func _on_turn_playing(): turn_playing = true
func _on_turn_played(): turn_playing = false

func _on_player_acted(action):
	_set_color_from_action(action[0])
	$Tween.stop_all()
	$Tween.interpolate_property(self, 'modulate', Color.white, modulate, Board.TURN_DURATION, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.start()
