extends TileMap  # This needs to be attached to a TileMap node

signal lock_doors
signal unlock_doors
	
var top_door_scene = preload("res://top_door.tscn")
var right_door_scene = preload("res://right_door.tscn")
# Constants
const MAP_WIDTH = 125
const MAP_HEIGHT = 100
const MIN_LEAF_SIZE = 24  # Smaller leaf size
const MAX_LEAF_SIZE = 32  # Smaller maximum leaf size
const MIN_ROOM_SIZE = 16 # Smaller room size
const MAX_ROOMS = 15  # Limit the number of rooms to 15
const CAMERA_SPEED = 2000  # Speed for camera movement
const ZOOM_SPEED = 0.5  # Speed for zooming the camera

# Variables for HUD labels
var boss_label
var shop_label
var chest_label
var all_doors = []  # Store references to all doors in the dungeon

# Global dictionary to store Area2D references for each room
var room_area_detectors = {}

# Global variables
var leaves = []
var root_leaf
var room_count = 0  # Counter to track number of generated rooms
var current_seed = 0
# Room class
class Room:
	var id
	var rect
	var connections = []
	var enemies: Array = []
	var doors = []
	var visited = false

	func _init(_id, _rect):
		id = _id
		rect = _rect

	func add_enemy(enemy):
		enemies.append(enemy)
		print("Added enemy to room", id, ". Current count:", enemies.size())

	func enemy_died(enemy):
		if enemies.has(enemy):
			enemies.erase(enemy)
			print("Enemy removed from room:", id)

		# Unlock doors if no enemies are left in the room
		if not has_enemies():
			get_parent().unlock_doors_in_all_rooms()
			print("All enemies defeated in room", id, ". Doors unlocked.")
	func has_enemies() -> bool:
		return enemies.size() > 0

	func get_enemy_info() -> Dictionary:
		return {
			"count": enemies.size(),
			"enemies": enemies
		}

	func get_enemy_count() -> int:
		return enemies.size()

	func get_enemy_list() -> Array:
		return enemies

func _on_enemy_defeated(enemy):
	print("Defeated signal received from:", enemy)
	var room = get_room_for_enemy(enemy)
	if room:
		room.enemy_died(enemy)  # Calls the room’s local door management function
		if any_room_has_enemies():
			emit_signal("lock_doors")  # Emit lock signal if enemies remain in other rooms
	else:
		print("Enemy's room not found.")

# Union-Find class for Kruskal's algorithm
class UnionFind:
	var parent = {}
	
	func make_set(x):
		parent[x] = x
	
	func find(x):
		if parent[x] != x:
			parent[x] = find(parent[x])  # Path compression
		return parent[x]
	
	func union(x, y):
		var x_root = find(x)
		var y_root = find(y)
		if x_root != y_root:
			parent[y_root] = x_root
			return true  # Union was successful
		return false  # x and y are already in the same set

class Leaf:
	static var room_id = 0

	# Instance variables for the leaf class
	var rect       # The rectangle representing this leaf's area
	var left_child = null
	var right_child = null
	var room = null
	var rooms = []
	var corridors = []

	func _init(_rect):
		rect = _rect

	func split() -> bool:
		if left_child != null or right_child != null:
			return false  # Already split

		var split_horizontally = randf() > 0.5

		if rect.size.x > rect.size.y and rect.size.x / rect.size.y >= 1.25:
			split_horizontally = false
		elif rect.size.y > rect.size.x and rect.size.y / rect.size.x >= 1.25:
			split_horizontally = true

		var max_size = (rect.size.y - MIN_LEAF_SIZE) if split_horizontally else (rect.size.x - MIN_LEAF_SIZE)
		if max_size <= MIN_LEAF_SIZE:
			return false  # Too small to split

		var split_distance = randf_range(MIN_LEAF_SIZE, max_size)

		if split_horizontally:
			left_child = Leaf.new(Rect2(rect.position, Vector2(rect.size.x, split_distance)))
			right_child = Leaf.new(
				Rect2(
					rect.position + Vector2(0, split_distance),
					Vector2(rect.size.x, rect.size.y - split_distance)
				)
			)
		else:
			left_child = Leaf.new(Rect2(rect.position, Vector2(split_distance, rect.size.y)))
			right_child = Leaf.new(
				Rect2(
					rect.position + Vector2(split_distance, 0),
					Vector2(rect.size.x - split_distance, rect.size.y)
				)
			)

		return true

	func create_rooms():
		if left_child != null or right_child != null:
			if left_child != null:
				left_child.create_rooms()
				self.rooms += left_child.rooms
			if right_child != null:
				right_child.create_rooms()
				self.rooms += right_child.rooms
		else:
			var room_width = randf_range(MIN_ROOM_SIZE, rect.size.x - 10)
			var room_height = randf_range(MIN_ROOM_SIZE, rect.size.y - 10)
			var room_size = Vector2(room_width, room_height)
			var room_position = rect.position + Vector2(
				randf_range(5, rect.size.x - room_width - 5),
				randf_range(5, rect.size.y - room_height - 5)
			)

			Leaf.room_id += 1
			room = Room.new(Leaf.room_id, Rect2(room_position, room_size))
			self.rooms.append(room)

	# Move the connect_rooms() function inside the Leaf class
	func connect_rooms(room1_rect: Rect2, room2_rect: Rect2) -> Array:
		var corridor_segments = []

		# Calculate edge points of both rooms towards the target room
		var point1 = get_room_edge_point_towards(room1_rect, room2_rect.position + room2_rect.size / 2)
		var point2 = get_room_edge_point_towards(room2_rect, room1_rect.position + room1_rect.size / 2)

		# Make the corridors stop just outside the room edges
		if abs(point1.x - point2.x) > abs(point1.y - point2.y):
			# Horizontal corridor
			if point1.x < point2.x:
				point2.x -= 1  # Stop before the room's right edge
			else:
				point2.x += 1  # Stop before the room's left edge
			corridor_segments.append(Rect2(point1, Vector2(point2.x - point1.x, 5)))  # Width of 5 for corridor
		else:
			# Vertical corridor
			if point1.y < point2.y:
				point2.y -= 1  # Stop before the room's bottom edge
			else:
				point2.y += 1  # Stop before the room's top edge
			corridor_segments.append(Rect2(point1, Vector2(5, point2.y - point1.y)))  # Width of 5 for corridor

		return corridor_segments


	func create_room_connections():
		var edges = []
		for i in range(self.rooms.size()):
			var room_a = self.rooms[i]
			for j in range(i + 1, self.rooms.size()):
				var room_b = self.rooms[j]
				var pos_a = room_a.rect.position + room_a.rect.size / 2
				var pos_b = room_b.rect.position + room_b.rect.size / 2
				var distance = pos_a.distance_to(pos_b)
				edges.append({"room_a": room_a, "room_b": room_b, "distance": distance})

		# Sort edges by distance
		edges.sort_custom(func(a, b):
			return a["distance"] < b["distance"]
		)

		var uf = UnionFind.new()
		for room in self.rooms:
			uf.make_set(room.id)

		# Kruskal's Algorithm to create corridors
		for edge in edges:
			var room_a_id = edge["room_a"].id
			var room_b_id = edge["room_b"].id
			if uf.union(room_a_id, room_b_id):
				var corridor = self.connect_rooms(edge["room_a"].rect, edge["room_b"].rect)
				self.corridors += corridor
				# Update connections
				edge["room_a"].connections.append(room_b_id)
				edge["room_b"].connections.append(room_a_id)


	func get_room_edge_point_towards(room_rect: Rect2, target_point: Vector2) -> Vector2:
		var center = room_rect.position + room_rect.size / 2
		var dx = target_point.x - center.x
		var dy = target_point.y - center.y
		var abs_dx = abs(dx)
		var abs_dy = abs(dy)
		var edge_point = Vector2()

		# Determine if the connection should be on the horizontal or vertical edge
		if abs_dx > abs_dy:
			# Intersection with left or right edge
			if dx > 0:
				# Right edge
				edge_point.x = room_rect.position.x + room_rect.size.x
				edge_point.y = center.y + dy * ((edge_point.x - center.x) / dx)
			else:
				# Left edge
				edge_point.x = room_rect.position.x
				edge_point.y = center.y + dy * ((edge_point.x - center.x) / dx)
		else:
			# Intersection with top or bottom edge
			if dy > 0:
				# Bottom edge
				edge_point.y = room_rect.position.y + room_rect.size.y
				edge_point.x = center.x + dx * ((edge_point.y - center.y) / dy)
			else:
				# Top edge
				edge_point.y = room_rect.position.y
				edge_point.x = center.x + dx * ((edge_point.y - center.y) / dy)

		return edge_point
# Function to spawn enemies in rooms
func spawn_enemies_in_rooms():
	# Ensure rooms are available
	if root_leaf.rooms.size() == 0:
		print("No rooms available to spawn enemies.")
		return


var initial_room: Room = null

func spawn_character_in_room():
	if root_leaf.rooms.size() == 0:
		print("No rooms available to spawn the player.")
		return

	# Choose a random room for the player to spawn in
	initial_room = root_leaf.rooms[randi_range(0, root_leaf.rooms.size() - 1)]

	# Get a random position within the room's bounds
	var spawn_x = int(randf_range(initial_room.rect.position.x + 1, initial_room.rect.position.x + initial_room.rect.size.x - 1))
	var spawn_y = int(randf_range(initial_room.rect.position.y + 1, initial_room.rect.position.y + initial_room.rect.size.y - 1))

	# Set the player's position
	var player = $player
	player.position = Vector2(spawn_x, spawn_y) * 32

	# Mark the initial room as visited and unlock its doors
	initial_room.visited = true
	#initial_room.unlock_doors()
	print("Player spawned in initial room ", initial_room.id, " at position: ", player.position)



var enemy_spawn_scene = preload("res://enemy_spawn.tscn")
var wraith_scene = preload("res://wraith.tscn")
var firey_scene = preload("res://fire_ball.tscn")
# Dictionary for enemy spawn probabilities (adjustable values)
var enemy_probabilities = {
	"Wraith": 0.1,  # 30% chance to spawn a Wraith
	"Firey": 0.9,   # Currently set to 0% as a placeholder (set to the desired probability later)
	"Zombie": 0.0   # Currently set to 0% as a placeholder (set to the desired probability later)
}

# Dictionary to preload enemy scenes (add scenes as they become available)
var enemy_scenes = {
	"Wraith": preload("res://wraith.tscn"),
	"Firey": preload("res://fire_ball.tscn"),
	"Zombie": null  # Placeholder for future enemy scene
}

func spawn_enemies_in_room(room: Room):
	if room.has_enemies():
		print("Enemies already spawned in room", room.id)
		return  # Avoid spawning again if enemies already exist

	print("Spawning enemies in room", room.id)

	var enemy_count = randi_range(3, 6)

	for i in range(enemy_count):
		var spawn_x = int(randf_range(room.rect.position.x + 1, room.rect.position.x + room.rect.size.x - 1))
		var spawn_y = int(randf_range(room.rect.position.y + 1, room.rect.position.y + room.rect.size.y - 1))

		var enemy_scene = choose_enemy_based_on_probability()

		if enemy_scene != null:
			var enemy_instance = enemy_scene.instantiate()
			enemy_instance.position = Vector2(spawn_x, spawn_y) * 32
			room.add_enemy(enemy_instance)  # Add enemy to the room
			enemy_instance.call_deferred("connect", "defeated", Callable(self, "_on_enemy_defeated"))
			add_child(enemy_instance)

			print("Spawned enemy in room", room.id, "at position:", enemy_instance.position)
		else:
			print("Error: No valid enemy scene to instantiate.")

	print("Total enemies in room", room.id, ":", room.get_enemy_count())
	print("Enemies in room", room.id, ":", room.get_enemy_list())




# Assuming `spawn_instance` is the spawn animation and `enemy_instance` is the actual enemy
func _on_spawn_animation_finished(spawn_instance):
	var enemy_instance = spawn_instance.enemy  # Reference to the enemy
	if enemy_instance:
		enemy_instance.position = spawn_instance.position
		# Update the enemy position in the game logic
		# Optionally, signal or notify the room manager
		notify_room_about_enemy_position(enemy_instance)
func notify_room_about_enemy_position(enemy_instance):
	var room = get_room_for_enemy(enemy_instance)
	if room:
		# Update the tracking information here
		print("Updating position for enemy in room:", room.id, "to", enemy_instance.position)


func get_room_for_area2d(area2d: Area2D) -> Room:
	if room_area_detectors.has(area2d):
		return room_area_detectors[area2d]
	print("No matching room found for the Area2D. Total rooms checked:", room_area_detectors.size())
	return null

func get_room_for_enemy(enemy) -> Room:
	# Loop through each room and check if the enemy is in the room's enemies array
	for room in root_leaf.rooms:
		if room.enemies.has(enemy):
			return room
	return null



@onready var area2d_container: Node2D = $TileMap/Area2DContainer
@onready var detection_area_scene = preload("res://room_detection.tscn")

func add_area2d_to_room(room: Room):
	# Instantiate the DetectionArea scene
	var detection_area = detection_area_scene.instantiate() as Area2D
	detection_area.room_id = room.id

	# Set the position and size of the DetectionArea
	detection_area.position = (room.rect.position + room.rect.size / 2) * 32  # Center the Area2D in the room
	var collision_shape = detection_area.get_node("CollisionShape2D") as CollisionShape2D
	if collision_shape != null:
		collision_shape.shape.extents = room.rect.size * 16  # Assuming room size is in tiles

	# Add the instantiated DetectionArea to the container
	area2d_container.add_child(detection_area)

	# Connect the custom player_entered signal
	detection_area.connect("player_entered", Callable(self, "_on_player_entered_room"))
	detection_area.connect("enemy_exited", Callable(self, "_on_enemy_defeated"))

	# Map the DetectionArea to the room
	room_area_detectors[detection_area] = room
	print("Created Area2D for room ID:", room.id)


func _on_player_entered_room(room_id):
	var room = get_room_by_id(room_id)
	if room == null:
		print("Room not found for ID:", room_id)
		return

	if not room.visited:
		room.visited = true
		spawn_enemies_in_room(room)  # Spawn enemies if needed

		if any_room_has_enemies():
			lock_doors_in_all_rooms()  
			print("All doors locked due to enemies.")
	else:
		print("Room already visited:", room_id)

func any_room_has_enemies() -> bool:
	for room in root_leaf.rooms:
		if room.has_enemies():
			return true
	return false
	
func add_door_to_room(room: Room, door_instance: Node2D):
	if room:
		room.doors.append(door_instance)
		print("Added door to room", room.id)
	else:
		print("Error: Room not found for the door at position", door_instance.position)

		
func get_room_by_id(room_id: int) -> Room:
	for room in root_leaf.rooms:
		if room.id == room_id:
			return room
	return null


func print_room_mappings():
	print("Room-Area2D Mapping:")
	for area2d in room_area_detectors.keys():
		var room = room_area_detectors[area2d]
		print("Area2D:", area2d, "Room ID:", room.id, "Position:", area2d.position)


func choose_enemy_based_on_probability() -> PackedScene:
	var rand_value = randf()
	var cumulative_probability = 0.0

	for enemy_type in enemy_probabilities.keys():
		cumulative_probability += enemy_probabilities[enemy_type]
		if rand_value < cumulative_probability:
			if enemy_scenes[enemy_type] != null:
				print("Chose enemy type: ", enemy_type)
				return enemy_scenes[enemy_type]
			else:
				print("Warning: Enemy scene for '%s' not yet available." % enemy_type)

	print("No enemy type selected, returning null.")
	return null  # If no valid scene is found, return null



func _ready():
	# Initialize labels, dungeon seed, and generate dungeon layout
	boss_label = $BossLabel
	shop_label = $ShopLabel
	chest_label = $ChestLabel

	initialize_seed()
	randomize()
	generate_level()
	place_tiles()  # Place room tiles
	place_corridor_tiles()  # Place corridor tiles

	# Ensure Area2DContainer exists or create it
	if not area2d_container:
		area2d_container = Node2D.new()
		area2d_container.name = "Area2DContainer"
		add_child(area2d_container)

	# Set the room labels after the dungeon is generated
	set_room_labels()
	spawn_character_in_room()
	

	
	# Add Area2D detectors for each room based on room dimensions
	for room in root_leaf.rooms:
		add_area2d_to_room(room)
	for room in root_leaf.rooms:
		var enemy_info = room.get_enemy_info()
		print("Initial state for room", room.id, ": Total enemies:", enemy_info["count"])
		print("Enemies in room", room.id, ":", enemy_info["enemies"])
	print("Dungeon setup complete.")
	print_room_mappings()

	# Initialize the random seed
func initialize_seed(seed_value = 0):
	if seed_value == 0:
		# If no seed is provided, generate a random seed
		current_seed = randi()
	else:
		# If a seed is provided, use it (could be player input in the future)
		current_seed = seed_value
	
	# Set the seed for random number generation
	seed(current_seed)
	
	# Optionally, print the seed so the player can see and reuse it
	print("Dungeon Seed: ", current_seed)
# Generate the level using BSP
func generate_level():
	root_leaf = Leaf.new(Rect2(0, 0, MAP_WIDTH, MAP_HEIGHT))
	leaves.append(root_leaf)

	var did_split = true
	while did_split:
		did_split = false
		for leaf in leaves.duplicate():
			if leaf.left_child == null and leaf.right_child == null:
				if leaf.rect.size.x > MAX_LEAF_SIZE or leaf.rect.size.y > MAX_LEAF_SIZE or randf() > 0.8:
					if leaf.split():
						leaves.append(leaf.left_child)
						leaves.append(leaf.right_child)
						did_split = true

	root_leaf.create_rooms()
	root_leaf.create_room_connections()
	#spawn_enemies_in_rooms()

func set_room_labels():
	# Ensure there are enough rooms generated to place labels
	if root_leaf.rooms.size() < 3:
		print("Not enough rooms generated to assign all labels.")
		return
	
	# Randomly pick 3 unique rooms for Boss, Shop, and Chest
	var boss_room = get_random_room()
	var shop_room = get_random_room([boss_room])
	var chest_room = get_random_room([boss_room, shop_room])

	# Set the Boss Room label
	var boss_position = get_randomized_room_position(boss_room)
	boss_label.text = "Boss Room: ID %s" % boss_room.id
	boss_label.position = boss_position + Vector2(0, -20)  # Slightly above the random position

	# Set the Shop Room label
	var shop_position = get_randomized_room_position(shop_room)
	shop_label.text = "Shop Room: ID %s" % shop_room.id
	shop_label.position = shop_position + Vector2(0, -20)  # Slightly above the random position

	# Set the Chest Room label
	var chest_position = get_randomized_room_position(chest_room)
	chest_label.text = "Chest Room: ID %s" % chest_room.id
	chest_label.position = chest_position + Vector2(0, -20)  # Slightly above the random position

# Function to get a random room, optionally excluding some rooms
func get_random_room(exclude=[]):
	var available_rooms = []  # Create a new list for available rooms
	
	# Add rooms to the available list if they are not in the exclude list
	for room in root_leaf.rooms:
		if not exclude.has(room):
			available_rooms.append(room)
	
	# Return a random room from the available list
	return available_rooms[randi_range(0, available_rooms.size() - 1)]

# Function to get a random position within the bounds of the room
func get_randomized_room_position(room) -> Vector2:
	# Get room bounds in tile coordinates
	var room_position = room.rect.position
	var room_size = room.rect.size
	
	# Randomize a position within the room's bounds
	var random_x = randf_range(room_position.x + 5, room_position.x + room_size.x - 5)  # Add padding of 5 tiles to avoid walls
	var random_y = randf_range(room_position.y + 5, room_position.y + room_size.y - 5)
	
	# Convert the random tile coordinates to world coordinates
	return map_to_local(Vector2(random_x, random_y))

# Example logic to check room types
func room_is_boss_room(room):
	return room.id == 1  # Assume the first room generated is the Boss Room

func room_is_shop_room(room):
	return room.id == 2  # Assume the second room generated is the Shop Room

func room_is_chest_room(room):
	return room.id == 3  # Assume the third room generated is the Chest Room

func is_corridor_connected(x, y) -> bool:
	# Function to check if there's a corridor connected to this position
	for corridor in root_leaf.corridors:
		var corridor_start = corridor.position
		var corridor_end = corridor.position + corridor.size

		# Adjust the check to account for the 2-tile wide corridor
		var x_offset = 2
		var y_offset = 2

		# Horizontal corridors
		if corridor.size.x > corridor.size.y:
			if (x >= int(corridor_start.x) - x_offset and x <= int(corridor_end.x) + x_offset) and y == int(corridor_start.y):
				return true
		
		# Vertical corridors
		else:
			if (y >= int(corridor_start.y) - y_offset and y <= int(corridor_end.y) + y_offset) and x == int(corridor_start.x):
				return true

	return false


# Function to handle wall removal and floor placement for corridor connections
func replace_walls_with_floor(x, y, horizontal=true):
	if horizontal:
		# Horizontal corridors: Replace 5 tiles vertically (center and 2 above/below)
		for y_offset in range(-2, 3):
			set_cell(0, Vector2i(x, y + y_offset), 1, Vector2i(7, 3))  # Floor tile
	else:
		# Vertical corridors: Replace 5 tiles horizontally (center and 2 left/right)
		for x_offset in range(-2, 3):
			set_cell(0, Vector2i(x + x_offset, y), 1, Vector2i(7, 3))  # Floor tile

func place_tiles():
	var layer = 2  # Layer for both walls and floors

	# Atlas floor tile coordinates (3,3) through (10,5)
	var floor_pattern_start = Vector2i(3, 3)
	var floor_pattern_end = Vector2i(10, 5)

	# Calculate the width and height of the atlas matrix
	var atlas_width = floor_pattern_end.x - floor_pattern_start.x + 1
	var atlas_height = floor_pattern_end.y - floor_pattern_start.y + 1

	# Place floor and walls for each room
	for room in root_leaf.rooms:
		# Room coordinates
		var x_start = int(floor(room.rect.position.x))
		var y_start = int(floor(room.rect.position.y))
		var x_end = int(floor(room.rect.position.x + room.rect.size.x))
		var y_end = int(floor(room.rect.position.y + room.rect.size.y))

		# Place floor tiles inside the room, traversing the atlas matrix in a repeating pattern
		for x in range(x_start, x_end):
			for y in range(y_start, y_end):
				# Calculate the current tile in the atlas based on the x and y offsets
				var atlas_x = floor_pattern_start.x + (x - x_start) % atlas_width
				var atlas_y = floor_pattern_start.y + (y - y_start) % atlas_height

				# Place the current floor tile from the atlas
				set_cell(layer, Vector2i(x, y), 1, Vector2i(atlas_x, atlas_y))

		# Place 2-tile thick walls around the room perimeter

		# Top and Bottom walls
		for x in range(x_start - 2, x_end + 2):
			# Top wall (2 tiles thick)
			set_cell(layer, Vector2i(x, y_start - 1), 0, Vector2i(7, 1))  # First row of top wall
			set_cell(layer, Vector2i(x, y_start - 2), 0, Vector2i(7, 0))  # Second row of top wall
			# Bottom wall (2 tiles thick)
			set_cell(layer, Vector2i(x, y_end), 0, Vector2i(7, 7))  # First row of bottom wall
			set_cell(layer, Vector2i(x, y_end + 1), 0, Vector2i(7, 8))  # Second row of bottom wall

		# Left and Right walls
		for y in range(y_start - 1, y_end + 2):
			# Left wall (2 tiles thick)
			set_cell(layer, Vector2i(x_start - 2, y), 0, Vector2i(0, 4))  # First column of left wall
			set_cell(layer, Vector2i(x_start - 1, y), 0, Vector2i(1, 4))  # Second column of left wall
			# Right wall (2 tiles thick)
			set_cell(layer, Vector2i(x_end, y), 0, Vector2i(12, 4))  # First column of right wall
			set_cell(layer, Vector2i(x_end + 1, y), 0, Vector2i(13, 4))  # Second column of right wall

		# Place corner tiles (4 tiles per corner)
		# Top-left corner
		set_cell(layer, Vector2i(x_start - 2, y_start - 1), 0, Vector2i(0, 1))
		set_cell(layer, Vector2i(x_start - 1, y_start - 1), 0, Vector2i(1, 1))
		set_cell(layer, Vector2i(x_start - 2, y_start - 2), 0, Vector2i(0, 0))
		set_cell(layer, Vector2i(x_start - 1, y_start - 2), 0, Vector2i(1, 0))

		# Top-right corner
		set_cell(layer, Vector2i(x_end, y_start - 1), 0, Vector2i(12, 1))
		set_cell(layer, Vector2i(x_end + 1, y_start - 1), 0, Vector2i(13, 1))
		set_cell(layer, Vector2i(x_end, y_start - 2), 0, Vector2i(12, 0))
		set_cell(layer, Vector2i(x_end + 1, y_start - 2), 0, Vector2i(13, 0))

		# Bottom-left corner
		set_cell(layer, Vector2i(x_start - 2, y_end), 0, Vector2i(0, 7))
		set_cell(layer, Vector2i(x_start - 1, y_end), 0, Vector2i(1, 7))
		set_cell(layer, Vector2i(x_start - 2, y_end + 1), 0, Vector2i(0, 8))
		set_cell(layer, Vector2i(x_start - 1, y_end + 1), 0, Vector2i(1, 8))

		# Bottom-right corner
		set_cell(layer, Vector2i(x_end, y_end), 0, Vector2i(12, 7))
		set_cell(layer, Vector2i(x_end + 1, y_end), 0, Vector2i(13, 7))
		set_cell(layer, Vector2i(x_end, y_end + 1), 0, Vector2i(12, 8))
		set_cell(layer, Vector2i(x_end + 1, y_end + 1), 0, Vector2i(13, 8))


# Function to place corridor tiles using atlas coordinates, with walls and corner tiles
# Function to handle wall removal and floor placement for corridor connections
func replace_walls_with_floor_at_connection(x, y, is_horizontal=true):
	if is_horizontal:
		# Horizontal corridors: Remove walls and replace 5 tiles vertically (center and 2 above/below)
		for y_offset in range(-2, 3):
			set_cell(0, Vector2i(x, y + y_offset), 1, Vector2i(7, 3))  # Floor tile
	else:
		# Vertical corridors: Remove walls and replace 5 tiles horizontally (center and 2 left/right)
		for x_offset in range(-2, 3):
			set_cell(0, Vector2i(x + x_offset, y), 1, Vector2i(7, 3))  # Floor tile
# Function to place horizontal path tiles using atlas coordinates, with walls and corner tiles
# Function to place horizontal path tiles and walls using atlas coordinates
# Function to place horizontal path tiles and walls on the Path layer (layer 2)

# Function to place corridor tiles (path, walls, and corners) only on Layer 2
func place_corridor_tiles():
	var layer = 2  # Only use Layer 2 for all corridor-related tiles

	for corridor in root_leaf.corridors:
		var x_start = int(floor(corridor.position.x))
		var y_start = int(floor(corridor.position.y))
		var x_end = int(floor(corridor.position.x + corridor.size.x))
		var y_end = int(floor(corridor.position.y + corridor.size.y))

		# Determine if this segment is horizontal or vertical
		var is_horizontal = abs(x_end - x_start) > abs(y_end - y_start)

		if is_horizontal:
# Atlas floor tile coordinates for horizontal corridors (8,12 to 12,13)
			var floor_pattern_start = Vector2i(8, 12)
			var floor_pattern_end = Vector2i(11, 13)

			# Calculate the width and height of the atlas matrix
			var atlas_width = floor_pattern_end.x - floor_pattern_start.x + 1
			var atlas_height = floor_pattern_end.y - floor_pattern_start.y + 1

			# Place floor tiles for horizontal corridors using the specified pattern
			for x in range(x_start, x_end + 1):
				for y_offset in [-1, 0, 1]:  # 3 tiles wide (center, top, and bottom)
					var atlas_x = floor_pattern_start.x + (x - x_start) % atlas_width
					var atlas_y = floor_pattern_start.y + (y_offset - (-1)) % atlas_height

					# Place the floor tile from the atlas
					set_cell(layer, Vector2i(x, y_start + y_offset), 2, Vector2i(atlas_x, atlas_y))
			# **Place doors at the center of the horizontal corridor**
			var horizontal_center_x = int((x_start + x_end) / 2)
			var horizontal_center_y = y_start  # Corridor's center Y

			# Spawn two doors at the center of the corridor
			spawn_doors(Vector2(horizontal_center_x, horizontal_center_y), true)

			for x in range(x_start, x_end + 1):  # Include the last column by using x_end + 1
				# Place the centerline and side floor tiles (width of 3 tiles)
				#set_cell(layer, Vector2i(x, y_start), 2, Vector2i(7, 3))  # Center floor tile
				#set_cell(layer, Vector2i(x, y_start - 1), 2, Vector2i(7, 3))  # Top floor tile
				#set_cell(layer, Vector2i(x, y_start + 1), 2, Vector2i(7, 3))  # Bottom floor tile

				# Wall placement for the top walls
				if x == x_start + 2:  # Left side top wall
					set_cell(layer, Vector2i(x, y_start - 2), 2, Vector2i(7, 11))  # Tile (7,11)
					set_cell(layer, Vector2i(x, y_start - 3), 2, Vector2i(7, 10))  # Extra tile above (7,10)
				elif x == x_end - 2:  # Right side top wall
					set_cell(layer, Vector2i(x, y_start - 2), 2, Vector2i(12, 11))  # Tile (12,11)
					set_cell(layer, Vector2i(x, y_start - 3), 2, Vector2i(12, 10))  # Extra tile above (12,10)
				else:  # Middle walls
					set_cell(layer, Vector2i(x, y_start - 2), 2, Vector2i(9, 11))  # Middle wall tile (9,11)
					set_cell(layer, Vector2i(x, y_start - 3), 2, Vector2i(9, 10))  # Extra tile above (9,10)

				# Wall placement for the bottom walls
				if x == x_start + 2:  # Left side bottom wall
					set_cell(layer, Vector2i(x, y_start + 2), 2, Vector2i(7, 14))  # Tile (7,14)
					set_cell(layer, Vector2i(x, y_start + 3), 2, Vector2i(7, 15))  # Extra tile below (7,15)
				elif x == x_end - 2:  # Right side bottom wall
					set_cell(layer, Vector2i(x, y_start + 2), 2, Vector2i(12, 14))  # Tile (12,14)
					set_cell(layer, Vector2i(x, y_start + 3), 2, Vector2i(12, 15))  # Extra tile below (12,15)
				else:  # Middle walls
					set_cell(layer, Vector2i(x, y_start + 2), 2, Vector2i(9, 14))  # Middle wall tile (9,14)
					set_cell(layer, Vector2i(x, y_start + 3), 2, Vector2i(9, 15))  # Extra tile below (9,15)

			# Corrected Corner tile placement for all four corners of the corridor
			# Top-left corner (5,9 to 6,11)
			set_cell(layer, Vector2i(x_start, y_start - 4), 2, Vector2i(5, 9))  # Top-left corner 1
			set_cell(layer, Vector2i(x_start + 1, y_start - 4), 2, Vector2i(6, 9))  # Top-left corner 2
			set_cell(layer, Vector2i(x_start, y_start - 3), 2, Vector2i(5, 10))  # Second row of the top-left corner
			set_cell(layer, Vector2i(x_start + 1, y_start - 3), 2, Vector2i(6, 10))  # Second row corner
			set_cell(layer, Vector2i(x_start, y_start - 2), 2, Vector2i(5, 11))  # Third row of the top-left corner
			set_cell(layer, Vector2i(x_start + 1, y_start - 2), 2, Vector2i(6, 11))  # Third row corner

			# Top-right corner (13,9 to 14,11)
			set_cell(layer, Vector2i(x_end, y_start - 4), 2, Vector2i(14, 9))  # Top-right corner 1
			set_cell(layer, Vector2i(x_end - 1, y_start - 4), 2, Vector2i(13, 9))  # Top-right corner 2
			set_cell(layer, Vector2i(x_end, y_start - 3), 2, Vector2i(14, 10))  # Second row of the top-right corner
			set_cell(layer, Vector2i(x_end - 1, y_start - 3), 2, Vector2i(13, 10))  # Second row corner
			set_cell(layer, Vector2i(x_end, y_start - 2), 2, Vector2i(14, 11))  # Third row of the top-right corner
			set_cell(layer, Vector2i(x_end - 1, y_start - 2), 2, Vector2i(13, 11))  # Third row corner

			# Bottom-left corner (5,14 to 6,16)
			set_cell(layer, Vector2i(x_start, y_start + 2), 2, Vector2i(5, 14))  # Bottom-left corner 1
			set_cell(layer, Vector2i(x_start + 1, y_start + 2), 2, Vector2i(6, 14))  # Bottom-left corner 2
			set_cell(layer, Vector2i(x_start, y_start + 3), 2, Vector2i(5, 15))  # Second row of the bottom-left corner
			set_cell(layer, Vector2i(x_start + 1, y_start + 3), 2, Vector2i(6, 15))  # Second row corner
			set_cell(layer, Vector2i(x_start, y_start + 4), 2, Vector2i(5, 16))  # Third row of the bottom-left corner
			set_cell(layer, Vector2i(x_start + 1, y_start + 4), 2, Vector2i(6, 16))  # Third row corner

			# Bottom-right corner (13,14 to 14,16)
			set_cell(layer, Vector2i(x_end, y_start + 2), 2, Vector2i(14, 14))  # Bottom-right corner 1
			set_cell(layer, Vector2i(x_end - 1, y_start + 2), 2, Vector2i(13, 14))  # Bottom-right corner 2
			set_cell(layer, Vector2i(x_end, y_start + 3), 2, Vector2i(14, 15))  # Second row of the bottom-right corner
			set_cell(layer, Vector2i(x_end - 1, y_start + 3), 2, Vector2i(13, 15))  # Second row corner
			set_cell(layer, Vector2i(x_end, y_start + 4), 2, Vector2i(14, 16))  # Third row of the bottom-right corner
			set_cell(layer, Vector2i(x_end - 1, y_start + 4), 2, Vector2i(13, 16))  # Third row corner

		else:
			# Vertical corridor: 3 floor tiles wide and walls on the left and right

			# Vertical corridor: 3 floor tiles wide and walls on the left and right
			# Atlas floor tile coordinates for vertical corridors (17,10 to 18,13)
			var floor_pattern_start = Vector2i(17, 10)
			var floor_pattern_end = Vector2i(18, 13)

			# Calculate the width and height of the atlas matrix
			var atlas_width = floor_pattern_end.x - floor_pattern_start.x + 1
			var atlas_height = floor_pattern_end.y - floor_pattern_start.y + 1

			# Place floor tiles for vertical corridors using the specified pattern
			for y in range(y_start, y_end + 1):
				for x_offset in [-1, 0, 1]:  # 4 tiles wide (center, left, right, and extra)
					var atlas_x = floor_pattern_start.x + (x_offset - (-1)) % atlas_width
					var atlas_y = floor_pattern_start.y + (y - y_start) % atlas_height

					# Place the floor tile from the atlas
					set_cell(layer, Vector2i(x_start + x_offset, y), 2, Vector2i(atlas_x, atlas_y))

			# **Place doors at the center of the vertical corridor**
			var vertical_center_x = x_start  # Corridor's center X
			var vertical_center_y = int((y_start + y_end) / 2)

			# Spawn two doors at the center of the corridor
			spawn_doors(Vector2(vertical_center_x, vertical_center_y), false)
			
# Wall placement for the left and right walls
# Loop through vertical corridor positions and place walls
			# Loop through vertical corridor positions and place walls
			for y in range(y_start, y_end + 1):
				print("y:", y, "y_start + 2:", y_start + 2, "y_end - 2:", y_end - 2)

				# Wall placement for the left walls
				if y == y_start + 3:  # Bottom-left wall (only exactly at y_start + 2)
					print("Placing bottom-left wall at y:", y, "at position:", Vector2i(x_start - 1, y))
					set_cell(layer, Vector2i(x_start - 1, y), 2, Vector2i(2, 3))  # Move to -1
					set_cell(layer, Vector2i(x_start - 2, y), 2, Vector2i(1, 3))  # Move to -1
					set_cell(layer, Vector2i(x_start - 3, y), 2, Vector2i(0, 3))  # Adjust extra tile to -2
				elif y == y_end - 3:  # Top-left wall (only exactly at y_end - 2)
					print("Placing top-left wall at y:", y, "at position:", Vector2i(x_start - 1, y))
					set_cell(layer, Vector2i(x_start - 1, y), 2, Vector2i(2, 5))  # Move to -1
					set_cell(layer, Vector2i(x_start - 2, y), 2, Vector2i(1, 5))  # Move to -1
					set_cell(layer, Vector2i(x_start - 3, y), 2, Vector2i(0, 5))  # Adjust extra tile to -2
				else:  # Middle left walls (between top and bottom corners)
					if y > y_start + 3 and y < y_end - 3:  # Adjust range to stop earlier by 1 tile
						print("Placing middle-left wall at y:", y, "at position:", Vector2i(x_start - 1, y))
						set_cell(layer, Vector2i(x_start - 2, y), 2, Vector2i(1, 4))  # Adjust to -1
						set_cell(layer, Vector2i(x_start - 3, y), 2, Vector2i(0, 4))  # Adjust extra tile to -2

				# Wall placement for the right walls
				if y == y_start + 3:  # Bottom-right wall (only exactly at y_start + 2)
					print("Placing bottom-right wall at y:", y, "at position:", Vector2i(x_start + 2, y))
					set_cell(layer, Vector2i(x_start + 1, y), 2, Vector2i(11, 5))  # Bottom-right wall tile
					set_cell(layer, Vector2i(x_start + 2, y), 2, Vector2i(12, 5))  # Extra tile to the right
					set_cell(layer, Vector2i(x_start + 3, y), 2, Vector2i(13, 5))  # Extra tile to the right

				elif y == y_end - 3:  # Top-right wall (only exactly at y_end - 2)
					print("Placing top-right wall at y:", y, "at position:", Vector2i(x_start + 2, y))
					set_cell(layer, Vector2i(x_start + 1, y), 2, Vector2i(11, 3))  # Top-right wall tile
					set_cell(layer, Vector2i(x_start + 2, y), 2, Vector2i(12, 3))  # Extra tile to the right
					set_cell(layer, Vector2i(x_start + 3, y), 2, Vector2i(13, 3))  # Extra tile to the right

				else:  # Middle right walls (between top and bottom corners)
					if y > y_start + 3 and y < y_end - 3:  # Adjust range to stop earlier by 1 tile
						print("Placing middle-right wall at y:", y, "at position:", Vector2i(x_start + 2, y))
						set_cell(layer, Vector2i(x_start + 2, y), 2, Vector2i(12, 4))  # Middle wall tile (right)
						set_cell(layer, Vector2i(x_start + 3, y), 2, Vector2i(13, 4))  # Extra tile for the right


			# Adjusted Corner tile placement for all four corners of the vertical corridor
			# Top-left corner (shifted down 2 more tiles)
			set_cell(layer, Vector2i(x_start - 3, y_start), 2, Vector2i(20, 2))  # Top-left corner 1
			set_cell(layer, Vector2i(x_start - 2, y_start), 2, Vector2i(21, 2))  # Top-left corner 2
			set_cell(layer, Vector2i(x_start - 3, y_start + 1), 2, Vector2i(20, 3))  # Second row of the top-left corner
			set_cell(layer, Vector2i(x_start - 2, y_start + 1), 2, Vector2i(21, 3))  # Second row corner
			set_cell(layer, Vector2i(x_start - 3, y_start + 2), 2, Vector2i(20, 4))  # Third row of the top-left corner
			set_cell(layer, Vector2i(x_start - 2, y_start + 2), 2, Vector2i(21, 4))  # Third row corner

			# Top-right corner (shifted down 2 more tiles)
			set_cell(layer, Vector2i(x_start + 2, y_start), 2, Vector2i(16, 2))  # Top-right corner 1
			set_cell(layer, Vector2i(x_start + 3, y_start), 2, Vector2i(17, 2))  # Top-right corner 2
			set_cell(layer, Vector2i(x_start + 2, y_start + 1), 2, Vector2i(16, 3))  # Second row of the top-right corner
			set_cell(layer, Vector2i(x_start + 3, y_start + 1), 2, Vector2i(17, 3))  # Second row corner
			set_cell(layer, Vector2i(x_start + 2, y_start + 2), 2, Vector2i(16, 4))  # Third row of the top-right corner
			set_cell(layer, Vector2i(x_start + 3, y_start + 2), 2, Vector2i(17, 4))  # Third row corner

			# Bottom-left corner (shifted up 2 more tiles)
			set_cell(layer, Vector2i(x_start - 3, y_end - 2), 2, Vector2i(20, 6))  # Bottom-left corner 1
			set_cell(layer, Vector2i(x_start - 2, y_end - 2), 2, Vector2i(21, 6))  # Bottom-left corner 2
			set_cell(layer, Vector2i(x_start - 3, y_end - 1), 2, Vector2i(20, 7))  # Second row of the bottom-left corner
			set_cell(layer, Vector2i(x_start - 2, y_end - 1), 2, Vector2i(21, 7))  # Second row corner
			set_cell(layer, Vector2i(x_start - 3, y_end), 2, Vector2i(20, 8))  # Third row of the bottom-left corner
			set_cell(layer, Vector2i(x_start - 2, y_end), 2, Vector2i(21, 8))  # Third row corner

			# Bottom-right corner (shifted up 2 more tiles)
			set_cell(layer, Vector2i(x_start + 2, y_end - 2), 2, Vector2i(16, 6))  # Bottom-right corner 1
			set_cell(layer, Vector2i(x_start + 3, y_end - 2), 2, Vector2i(17, 6))  # Bottom-right corner 2
			set_cell(layer, Vector2i(x_start + 2, y_end - 1), 2, Vector2i(16, 7))  # Second row of the bottom-right corner
			set_cell(layer, Vector2i(x_start + 3, y_end - 1), 2, Vector2i(17, 7))  # Second row corner
			set_cell(layer, Vector2i(x_start + 2, y_end), 2, Vector2i(16, 8))  # Third row of the bottom-right corner
			set_cell(layer, Vector2i(x_start + 3, y_end), 2, Vector2i(17, 8))
			
func lock_doors_in_all_rooms():
	emit_signal("lock_doors")

func unlock_doors_in_all_rooms():
	emit_signal("unlock_doors")

func spawn_doors(center: Vector2, is_horizontal: bool):
	var door_instance

	# For horizontal corridors, use top doors
	if is_horizontal:
		door_instance = top_door_scene.instantiate() as Node2D
		door_instance.position = (center + Vector2(1.5, 1.35)) * 32   # Position for top door
	else:
		# For vertical corridors, use right doors
		door_instance = right_door_scene.instantiate() as Node2D
		door_instance.position = (center + Vector2(0.5, 1.35)) * 32  # Position for right door

	# Add the door instance to the scene and register it to all_doors
	add_child(door_instance)
	all_doors.append(door_instance)

	# Determine the room to which the door belongs
	var room = get_room_for_area2d(area2d_container)
	if room:
		room.doors.append(door_instance)  # Add the door to the room's list of doors
		print("Added door to room:", room.id)

		# Check if this room is the initial spawn room
		if room == initial_room:
			# Unlock the door by default if it's connected to the initial room
			door_instance.unlock()



# Camera movement and zooming using WASD and -/= keys
func _process(delta):
	var camera = $Camera2D
	var move_vector = Vector2()

	# Camera movement with WASD
	if Input.is_key_pressed(KEY_W):  # Move up
		move_vector.y -= 1
	if Input.is_key_pressed(KEY_A):  # Move left
		move_vector.x -= 1
	if Input.is_key_pressed(KEY_S):  # Move down
		move_vector.y += 1
	if Input.is_key_pressed(KEY_D):  # Move right
		move_vector.x += 1
	
	# Apply the movement
	camera.position += move_vector * CAMERA_SPEED * delta

	# Camera zooming with - and =
	if Input.is_key_pressed(KEY_9):  # Zoom out
		camera.zoom += Vector2(ZOOM_SPEED, ZOOM_SPEED) * delta
	if Input.is_key_pressed(KEY_0):  # Zoom in (using = key)
		camera.zoom -= Vector2(ZOOM_SPEED, ZOOM_SPEED) * delta

	# Clamp zoom to avoid excessive zoom in/out (you can adjust these limits)
	camera.zoom.x = clamp(camera.zoom.x, 0.2, 5)
	camera.zoom.y = clamp(camera.zoom.y, 0.2, 5)

# Handling direct key presses in _input(event) using keycode (Godot 4)
func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_W:
				$Camera2D.position.y -= CAMERA_SPEED * get_process_delta_time()
			KEY_A:
				$Camera2D.position.x -= CAMERA_SPEED * get_process_delta_time()
			KEY_S:
				$Camera2D.position.y += CAMERA_SPEED * get_process_delta_time()
			KEY_D:
				$Camera2D.position.x += CAMERA_SPEED * get_process_delta_time()
