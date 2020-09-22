extends Node
signal game_started(game_scene)

const Game = preload("res://Game.tscn")
var current_game

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	get_tree().connect("server_disconnected", self, "_player_disconnected", [1])

func _player_connected(_id):
	current_game = Game.instance()
	get_parent().add_child(current_game)
	emit_signal("game_started", current_game)
	raise()
	
	$Tween.interpolate_property($UI, 'modulate', $UI.modulate, Color.transparent, 0.5, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$Tween.interpolate_callback($UI, 0.5, 'hide')
	$Tween.start()

func _player_disconnected(_id):
	if get_tree().network_peer.get_connection_status(): get_tree().network_peer.call_deferred("close_connection")
	get_tree().reload_current_scene()
	
	if current_game:
		Board.reset()
		current_game.queue_free()

func join(ip = null):
	var join_ip : String = ip if ip else $UI/JoinPanel/IPField.text
	var error = OK
	var host
	
	if not join_ip.is_valid_ip_address(): error = ERR_CANT_RESOLVE
	else:
		host = NetworkedMultiplayerENet.new()
		error = host.create_client(join_ip, 8801)
	match error:
		ERR_ALREADY_IN_USE: $UI/Status.set_status("This match has already started")
		ERR_CANT_CREATE: $UI/Status.set_status("Couldn't create client")
		ERR_CANT_RESOLVE: $UI/Status.set_status("Invalid IP")
		OK: get_tree().set_network_peer(host)

func host():
	var host = NetworkedMultiplayerENet.new()
	var error = host.create_server(8801, 1)
	match error:
		ERR_ALREADY_IN_USE: $UI/Status.set_status("A host already exists")
		ERR_CANT_CREATE: $UI/Status.set_status("ERROR: Couldn't create host")
		OK:
			$UI/JoinPanel.visible = false
			get_tree().set_network_peer(host)
			$UI/Status.text = "Waiting for player..."
