extends Node2D

var surface_spawn : PackedScene = load("res://scenes/objects/surface_spawn.tscn")

var platform_holder : Node
var spawn_positions : Array
var drop_spawn_positions : Array
var lava : Area2D

var have_spawned_neighbour : bool = false

@onready var surfaces = $Surfaces
@onready var drop_zone = $DropZone


# Called when the node enters the scene tree for the first time.
func _ready():
	lava = get_tree().get_first_node_in_group("lava")
	platform_holder = get_tree().get_first_node_in_group("platforms")
	spawn_positions = surfaces.get_children()
	drop_spawn_positions = drop_zone.get_children()
	randomize_spawn_pos()
	fill_spawn_pos()
	drop_rocks()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if global_position.y - 400 > lava.global_position.y:
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_entered():
	if !have_spawned_neighbour:
		var new_surface = surface_spawn.instantiate()
		new_surface.global_position.y = global_position.y - 960
		
		platform_holder.add_child(new_surface)
		
		have_spawned_neighbour = true
	

func randomize_spawn_pos():
	
	
	for spawn in spawn_positions:
		spawn.position += Vector2(randf_range(-100, 100), randf_range(-100, 100))
		
	for rock_spawn in drop_spawn_positions:
		rock_spawn.position.x += randf_range(-100, 100)

func fill_spawn_pos():
	
	for spawn in spawn_positions:
		var chance_detector : float = randf()
		var surface : Node
		
		if chance_detector <= 0.8:
			surface = preload("res://scenes/objects/grapple_surface.tscn").instantiate()
		else:
			surface = preload("res://scenes/objects/damage_surface.tscn").instantiate()
		
		surface.rotate(randi_range(0, 360))
		
		spawn.add_child(surface)

func drop_rocks():
	var rock_drop_scene = load("res://scenes/objects/falling_obstacle.tscn")
	
	for rock_spawn in drop_spawn_positions:
		var roll : float = randf()
		if roll > 0.85:
			var rock = rock_drop_scene.instantiate()
			rock_spawn.add_child(rock)
