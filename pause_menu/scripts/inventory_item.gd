@tool

class_name InventoryItem extends Control

@export var icon: Texture2D :
	set(value) :
		icon = value
		apply_sprite()

@onready var color_rect: ColorRect = $ColorRect
@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var checkmark: Sprite2D = $Checkmark

var player: Player
var cosmetic_name := ""

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	self.focus_entered.connect(focused)
	self.focus_exited.connect(focused.bind(false))

	player = await SceneManager.get_player()


func apply_sprite() -> void:
	if Engine.is_editor_hint() and icon:
		sprite_2d.texture = icon


func select() -> void:
	if player.equipped_cosmetics.has(cosmetic_name):
		player.cosmetics.get_node_or_null(cosmetic_name).visible = false
		player.equipped_cosmetics.erase(cosmetic_name)
		checkmark.visible = false
		print("unequip")
	else:
		player.equipped_cosmetics.append(cosmetic_name)
		player.cosmetics.get_node_or_null(cosmetic_name).visible = true
		color_rect.visible = true
		checkmark.visible = true
		print("equip")


func focused(flag := true) -> void:
	color_rect.visible = flag


func _unhandled_input(event: InputEvent) -> void:
	if self.has_focus():
		if (event.is_action_pressed("ui_accept")
				or event.is_action_pressed("interact")):
			select()
