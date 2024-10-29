extends StaticBody3D

const CANNONBALL = preload("res://cannonball.tscn")

@export var shot_force: float= 10.0

@onready var muzzle = $MeshInstance3D/Muzzle


func shoot():
	var obj: RigidBody3D= CANNONBALL.instantiate()
	obj.position= muzzle.global_position
	get_tree().current_scene.add_child(obj)
	obj.linear_velocity= muzzle.global_basis.y * shot_force
