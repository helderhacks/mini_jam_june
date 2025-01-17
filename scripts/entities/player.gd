class_name Player extends RigidBody2D

@export var MOVE_FORCE : float = 1000
@export var JUMP_FORCE : float = 750
@export var GRAPPLE_FORCE : float = 1500

@export var BOOST_CD : float = 2.5
@export var DISABLE_CD : float = 2

signal attach(thing : StaticBody2D, distance_to_thing : float, side : String)
signal detach(side : String)
signal boost_cd

var grapple_point : PackedScene = preload("res://scenes/objects/grapple_point.tscn")

var can_boost : bool = true

var left_ready : bool = true
var right_ready : bool = true

var left_hooked : bool = false
var right_hooked : bool = false

var left_thing_to_stick : StaticBody2D
var right_thing_to_stick : StaticBody2D

@onready var left_spring : DampedSpringJoint2D = $LeftArm/LeftSpring
@onready var right_spring : DampedSpringJoint2D = $RightArm/RightSpring
@onready var left_arm : Node2D = $LeftArm
@onready var right_arm : Node2D = $RightArm
@onready var left_grapple_spawn : Marker2D = $LeftArm/GrappleSpawn
@onready var right_grapple_spawn : Marker2D  = $RightArm/GrappleSpawn


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta : float) -> void:
	aim_arms()
	
	var input_direction : float = Input.get_axis("move_left", "move_right")
	
	if input_direction:
		apply_central_force(Vector2(input_direction * MOVE_FORCE, 0))
		

func _input(event):
	if event.is_action_pressed("boost"):
		# SLOWLY LONGEN THE LINE AND THEN USE THE LENGTH
		# AS A MULTIPLIER TO THE IMPULSE TO PROMOTE WAITING FOR LONG LINE
		
		if (!left_hooked and !right_hooked):
			if can_boost:
				if linear_velocity.y > 0:
					linear_velocity = Vector2.ZERO
				apply_central_impulse(Vector2.UP * JUMP_FORCE)
				boost_cd.emit()
		else:
			if left_hooked:
				left_spring.node_b = NodePath("")
			
				left_hooked = false
				
				detach.emit("left")
			if right_hooked:
				right_spring.node_b = NodePath("")
			
				right_hooked = false
			
				detach.emit("right")
				
	
	if event.is_action_pressed("shoot_grapple_left"):
		if left_ready:
			left_ready = false
			
			var grapple_hook : GrapplePoint = grapple_point.instantiate()
			var shoot_dir : Vector2 = (get_global_mouse_position() - left_grapple_spawn.global_position).normalized()
			
			grapple_hook.shoot_dir = shoot_dir
			grapple_hook.current_side = "left"
			
			left_grapple_spawn.add_child(grapple_hook)
			
		elif left_hooked:
			
			left_spring.node_b = NodePath("")
			
			left_hooked = false
			
			apply_central_impulse((left_thing_to_stick.global_position - left_grapple_spawn.global_position).normalized() * GRAPPLE_FORCE) 
			
			detach.emit("left")
			
	if event.is_action_pressed("shoot_grapple_right"):
		if right_ready:
			right_ready = false
			var shoot_dir : Vector2 = (get_global_mouse_position() - right_grapple_spawn.global_position).normalized()
			
			
			var grapple_hook : GrapplePoint = grapple_point.instantiate()
			grapple_hook.shoot_dir = shoot_dir
			grapple_hook.current_side = "right"
			
			right_grapple_spawn.add_child(grapple_hook)
			
		elif right_hooked:
			right_spring.node_b = NodePath("")
			
			right_hooked = false
			
			apply_central_impulse((right_thing_to_stick.global_position - right_grapple_spawn.global_position).normalized() * GRAPPLE_FORCE)
			
			detach.emit("right")

func aim_arms():
	if left_ready:
		$LeftArm.look_at(get_global_mouse_position()) 
	if right_ready:
		$RightArm.look_at(get_global_mouse_position()) 
		
	if left_hooked:
		left_arm.look_at(left_thing_to_stick.global_position)
	if right_hooked:
		right_arm.look_at(right_thing_to_stick.global_position)

func _on_attach(thing : StaticBody2D, distance_to_thing : float, side : String):
	match side: 
		"left":
			left_thing_to_stick = thing
			left_spring.length = distance_to_thing * 1.5
			left_spring.rest_length = distance_to_thing * 0.75
			left_spring.node_b = left_thing_to_stick.get_path()
			left_hooked = true
		"right":
			right_thing_to_stick = thing
			right_spring.length = distance_to_thing * 1.5
			right_spring.rest_length = distance_to_thing * 0.75
			right_spring.node_b = right_thing_to_stick.get_path()
			right_hooked = true

func _on_boost_cd():
	can_boost = false
	await get_tree().create_timer(BOOST_CD).timeout
	can_boost = true
	
func disable_side(side : String):
	match side:
		"left":
			left_ready = false
			left_arm.visible = false
			await get_tree().create_timer(DISABLE_CD).timeout
			
			left_arm.visible = true
			left_ready = true
		"right":
			right_ready = false
			right_arm.visible = false
			await get_tree().create_timer(DISABLE_CD).timeout
			
			right_arm.visible = true
			right_ready = true
	
