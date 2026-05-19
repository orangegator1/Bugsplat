extends CanvasLayer

# menu screens
@onready var main_menu: VBoxContainer = %MainMenu
@onready var new_game_menu: VBoxContainer = %NewGameMenu
@onready var load_game_menu: VBoxContainer = %LoadGameMenu

# buttons
@onready var new_game_button: Button = %NewGameButton
@onready var load_game_button: Button = %LoadGameButton
@onready var new_slot_01: Button = %NewSlot_01
@onready var new_slot_02: Button = %NewSlot_02
@onready var new_slot_03: Button = %NewSlot_03
@onready var load_slot_01: Button = %LoadSlot_01
@onready var load_slot_02: Button = %LoadSlot_02
@onready var load_slot_03: Button = %LoadSlot_03
@onready var animation_player: AnimationPlayer = $Control/MainMenu/Logo/AnimationPlayer

func _ready() -> void:
	new_game_button.pressed.connect(show_new_game_menu)
	load_game_button.pressed.connect(show_load_game_menu)

	new_slot_01.pressed.connect(_on_new_game_pressed.bind(0))
	new_slot_02.pressed.connect(_on_new_game_pressed.bind(1))
	new_slot_03.pressed.connect(_on_new_game_pressed.bind(2))

	load_slot_01.pressed.connect(_on_load_game_pressed.bind(0))
	load_slot_02.pressed.connect(_on_load_game_pressed.bind(1))
	load_slot_03.pressed.connect(_on_load_game_pressed.bind(2))

	show_main_menu()
	animation_player.animation_finished.connect(_on_animation_finished)


func _on_new_game_pressed(slot: int)-> void:
	SaveManager.create_new_game_save(slot)
	SaveManager.load_game(slot)
	self.queue_free.call_deferred()

func _on_load_game_pressed(slot: int)-> void:
	SaveManager.load_game(slot)
	self.queue_free.call_deferred()


func show_main_menu() -> void:
	main_menu.visible = true
	new_game_menu.visible = false
	load_game_menu.visible = false
	new_game_button.grab_focus()


func show_new_game_menu() -> void:
	new_game_menu.visible = true
	main_menu.visible = false
	load_game_menu.visible = false
	new_slot_01.grab_focus()

	if SaveManager.save_file_exists(0):
		new_slot_01.text = "Overwrite Slot 1"
	if SaveManager.save_file_exists(1):
		new_slot_02.text = "Overwrite Slot 2"
	if SaveManager.save_file_exists(2):
		new_slot_03.text = "Overwrite Slot 3"


func show_load_game_menu() -> void:
	load_game_menu.visible = true
	new_game_menu.visible = false
	main_menu.visible = false
	load_slot_01.grab_focus()

	load_slot_01.disabled = not SaveManager.save_file_exists(0)
	load_slot_02.disabled = not SaveManager.save_file_exists(1)
	load_slot_03.disabled = not SaveManager.save_file_exists(2)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if main_menu.visible == false:
			show_main_menu()


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "fall_in":
		animation_player.play("bob")
