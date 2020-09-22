extends Area2D

export var speed : float = 1

var direction = Vector2()
var bullet_owner : Node

func _ready(): rotation = direction.angle()

func process_turn():
	$Tween.stop_all()
	$Tween.interpolate_property(self, 'position', position, position + direction * speed * Board.CELL_DISTANCE, Board.TURN_DURATION, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.interpolate_property($TrailParticles, 'speed_scale', 2, 0, Board.TURN_DURATION * 2, Tween.TRANS_SINE, Tween.EASE_OUT)
	$Tween.start()


func on_area_entered(area):
	if area is Player and area != bullet_owner:
		area.rpc('die')
