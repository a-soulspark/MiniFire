extends Node2D
signal game_started(game_scene)

const Game = preload("res://Game.tscn")
var current_game

func _ready():
	var host = NetworkedMultiplayerENet.new()
	var error = host.create_server(8801, 1)
	if error: error = host.create_client('127.0.0.1', 8801)
	
	if !error: get_tree().set_network_peer(host)
	else: get_tree().quit()
	
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("server_disconnected", self, "_player_disconnected", [1])

func _player_connected(_id):
	current_game = Game.instance()
	get_parent().add_child(current_game)
	emit_signal("game_started", current_game)
	raise()
	
	$Tween.interpolate_property(self, 'modulate', modulate, Color.transparent, 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.interpolate_callback(self, 0.5, 'hide')
	$Tween.start()

func _player_disconnected(_id):
	if get_tree().network_peer.get_connection_status(): get_tree().network_peer.call_deferred("close_connection")
	get_tree().reload_current_scene()
	
	if current_game:
		Board.reset()
		current_game.queue_free()
