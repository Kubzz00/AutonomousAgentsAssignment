extends Node3D

# ======================
# TARGETS
# ======================
@export var park_path: NodePath
@export var debug_overlay_path: NodePath
@export var menu_title_path: NodePath

@export var toggle_los_button_path: NodePath
@export var toggle_debug_button_path: NodePath
@export var reset_button_path: NodePath
@export var hide_menu_button_path: NodePath

# ======================
# SETTINGS
# ======================
@export var los_visible: bool = true
@export var debug_visible: bool = true
@export var menu_content_visible: bool = true

var park: Node = null
var debug_overlay: Node3D = null
var menu_title: Label3D = null

var toggle_los_button: Node = null
var toggle_debug_button: Node = null
var reset_button: Node = null
var hide_menu_button: Node = null


func _ready() -> void:
	park = get_node_or_null(park_path)
	debug_overlay = get_node_or_null(debug_overlay_path)
	menu_title = get_node_or_null(menu_title_path)

	toggle_los_button = get_node_or_null(toggle_los_button_path)
	toggle_debug_button = get_node_or_null(toggle_debug_button_path)
	reset_button = get_node_or_null(reset_button_path)
	hide_menu_button = get_node_or_null(hide_menu_button_path)

	connect_button(toggle_los_button)
	connect_button(toggle_debug_button)
	connect_button(reset_button)
	connect_button(hide_menu_button)

	apply_los_visibility()
	apply_debug_visibility()
	apply_menu_content_visibility()
	update_menu_text()

# ======================
# BUTTON CONNECTIONS
# ======================
func connect_button(button: Node) -> void:
	if button == null:
		push_warning("FloatingMenuController: button path missing.")
		return

	if button.has_signal("button_pressed"):
		button.button_pressed.connect(_on_button_pressed)
	else:
		push_warning("FloatingMenuController: button has no button_pressed signal: " + button.name)


func _on_button_pressed(action_name: String) -> void:
	print("FloatingMenuController received action: ", action_name)

	match action_name:
		"toggle_los":
			toggle_los()

		"toggle_debug":
			toggle_debug()

		"reset":
			reset_simulation()

		"toggle_buttons":
			toggle_menu_content()

		_:
			push_warning("FloatingMenuController: unknown action: " + action_name)


# ======================
# ACTIONS
# ======================
func toggle_los() -> void:
	los_visible = not los_visible
	apply_los_visibility()
	update_menu_text()


func toggle_debug() -> void:
	debug_visible = not debug_visible
	apply_debug_visibility()
	update_menu_text()


func toggle_menu_content() -> void:
	menu_content_visible = not menu_content_visible
	apply_menu_content_visibility()
	update_menu_text()


func reset_simulation() -> void:
	if park != null and park.has_method("reset_agents"):
		park.reset_agents()
	else:
		push_warning("FloatingMenuController: Park does not have reset_agents().")

	update_menu_text()


# ======================
# APPLY VISIBILITY
# ======================
func apply_los_visibility() -> void:
	if park == null:
		return

	set_los_visible_recursive(park, los_visible)


func set_los_visible_recursive(node: Node, value: bool) -> void:
	if node.name == "LOSDebugLine" and node is Node3D:
		node.visible = value

	for child in node.get_children():
		set_los_visible_recursive(child, value)


func apply_debug_visibility() -> void:
	if debug_overlay != null:
		debug_overlay.visible = debug_visible

	if park != null:
		set_state_markers_visible_recursive(park, debug_visible)


func set_state_markers_visible_recursive(node: Node, value: bool) -> void:
	if node.name == "StateMarker" and node is Node3D:
		node.visible = value

	for child in node.get_children():
		set_state_markers_visible_recursive(child, value)


func apply_menu_content_visibility() -> void:
	if menu_title != null:
		menu_title.visible = menu_content_visible

	if toggle_los_button != null and toggle_los_button is Node3D:
		toggle_los_button.visible = menu_content_visible

	if toggle_debug_button != null and toggle_debug_button is Node3D:
		toggle_debug_button.visible = menu_content_visible

	if reset_button != null and reset_button is Node3D:
		reset_button.visible = menu_content_visible

	# Hide/Show button must always remain visible.
	if hide_menu_button != null and hide_menu_button is Node3D:
		hide_menu_button.visible = true

	update_hide_button_text()


func update_hide_button_text() -> void:
	if hide_menu_button == null:
		return

	var label := hide_menu_button.get_node_or_null("ButtonText")

	if label == null:
		return

	if label is Label3D:
		if menu_content_visible:
			label.text = "Hide Menu"
		else:
			label.text = "Show Menu"


# ======================
# UI TEXT
# ======================
func update_menu_text() -> void:
	if menu_title == null:
		return

	var los_text := "ON"
	var debug_text := "ON"

	if not los_visible:
		los_text = "OFF"

	if not debug_visible:
		debug_text = "OFF"

	menu_title.text = (
		"MENU"
		+ "\nLOS: " + los_text
		+ " | DEBUG: " + debug_text
	)

	update_hide_button_text()
