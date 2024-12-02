extends Node
class_name FSM1

var states: Dictionary = {}
var previous_state: int = -1
var state: int = -1: set = set_state

@onready var parent: Node = get_parent()  # Generic reference to the parent
@onready var animation_player: AnimationPlayer = null  # Initialized in _ready

func _ready() -> void:
	# Try to locate the AnimationPlayer node
	if parent.has_node("AnimationPlayer"):
		animation_player = parent.get_node("AnimationPlayer")
		print("AnimationPlayer found and initialized.")
	else:
		print("Error: AnimationPlayer not found. Check your scene setup.")

func _physics_process(delta: float) -> void:
	if state != -1:
		_state_logic(delta)
		var transition: int = _get_transition()
		if transition != -1:
			set_state(transition)

func _state_logic(_delta: float) -> void:
	pass  # Implement state-specific logic in derived scripts

func _get_transition() -> int:
	return -1  # Implement transition logic in derived scripts

func _add_state(new_state: String) -> void:
	states[new_state] = states.size()

func set_state(new_state: int) -> void:
	_exit_state(state)
	previous_state = state
	state = new_state
	_enter_state(previous_state, state)

func _enter_state(_previous_state: int, _new_state: int) -> void:
	if animation_player == null:
		print("Error: Cannot play animation. AnimationPlayer is null.")
		return
	pass  # Override this in derived scripts

func _exit_state(_state_exited: int) -> void:
	pass  # Override this in derived scripts
