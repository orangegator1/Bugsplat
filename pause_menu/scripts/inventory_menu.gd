@tool
class_name InventoryMenu extends Control

@onready var inventory_label: Label = %InventoryLabel
@onready var map_label: Label = %MapLabel
@onready var map: Control = %Map
@onready var inventory_menu: InventoryMenu = %InventoryMenu
@onready var back_button: Button = %BackButton
@onready var system_menu_button: Button = %SystemMenuButton
@onready var inventory_full: Control = %InventoryFull
@onready var inventory_overlay: ColorRect = $InventoryOverlay
@onready var inventory_items: VBoxContainer = %InventoryItems

var inventory_item = "uid://dm8vuumm2brxc"

var player: Player
var selected := false
var inventory: Dictionary = {}

func _ready() -> void:
	player = await SceneManager.get_player()
	inventory = player.inventory
	populate_inventory()


func populate_inventory() -> void:
	for c in inventory.cosmetics:
		var item = load(inventory_item).instantiate()
		inventory_items.add_child(item)
		item.cosmetic_name = c
		if player.equipped_cosmetics.has(c):
			item.color_rect.visible = true
			item.checkmark.visible = true
		else:
			item.color_rect.visible = false
			item.checkmark.visible = false


func select() -> void:
	inventory_label.visible = selected
	map.visible = selected
	map_label.visible = selected
	system_menu_button.visible = selected
	back_button.visible = selected
	inventory_overlay.visible = selected

	inventory_full.visible = not selected
	selected = not selected

	inventory_items.get_child(0).grab_focus()
	Audio.play_ui_audio(Audio.ui_focus_audio)
	inventory_menu.focus_mode = Control.FOCUS_NONE


func unselect() -> void:
	inventory_label.visible = selected
	map.visible = selected
	map_label.visible = selected
	system_menu_button.visible = selected
	back_button.visible = selected
	inventory_overlay.visible = selected

	inventory_full.visible = not selected
	selected = not selected

	Audio.play_ui_audio(Audio.ui_cancel_audio)
	inventory_menu.focus_mode = Control.FOCUS_ALL
	inventory_menu.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if inventory_menu.has_focus():
		if (event.is_action_pressed("ui_accept")):
			select()
	if selected:
		if (event.is_action_pressed("ui_cancel")):
			unselect()
		elif event.is_action_pressed("interact"):
			pass
		elif event.is_action_pressed("jump"):
			pass
