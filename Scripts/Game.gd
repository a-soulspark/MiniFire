extends Node2D

signal turn_playing()
signal turn_played()

var act_timer = 0
var turn_id = 0

func _ready():
	if !get_tree().network_peer:
		$Player2.queue_free()
		return
	if get_tree().is_network_server(): $Player2.set_network_master(get_tree().get_network_connected_peers()[0])
	else: $Player2.set_network_master(get_tree().get_network_unique_id())

func _process(delta):
	# if player1 has an action, and either player2 does too, or it doesn't exist, proceed to next turn
	if not $Player1.action.empty() and (not get_tree().network_peer or get_tree().network_peer and not $Player2.action.empty()):
		act_timer += delta
		if act_timer >= Board.TURN_DURATION: process_turn()

func process_turn():
	print("processing turns!")
	get_tree().call_group_flags(SceneTree.GROUP_CALL_REALTIME, 'Processable', "process_turn")
	emit_signal('turn_playing')
	turn_id += 1
	act_timer = 0
	
	$Tween.interpolate_callback(self, Board.TURN_DURATION, 'emit_signal', 'turn_played')
	$Tween.start()
