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

var icons: Dictionary = {
	"propeller_hat" : "uid://bx4c8hpovj3vo",
	"metroidvania_hair" : "uid://l8nift5jpxmk"
}
var slot: Dictionary = {
	"propeller_hat" : "head",
	"metroidvania_hair" : "head"
}

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
		item.icon.texture = load(icons[c])
		item.item_selected.connect(on_item_selected)
		item.checkmark.visible = player.equipped_cosmetics.has(c)


func on_item_selected(i: InventoryItem) -> void:
	if player.equipped_cosmetics.has(i.cosmetic_name):
		unequip(i.cosmetic_name)
		i.checkmark.visible = false
	else:
		# equip
		for c in player.equipped_cosmetics:
			if slot[c] == slot[i.cosmetic_name]:
				unequip(c)
		player.equipped_cosmetics.append(i.cosmetic_name)
		player.cosmetics.get_node_or_null(i.cosmetic_name).visible = true
		i.checkmark.visible = true

func unequip(c: String) -> void:
	player.cosmetics.get_node_or_null(c).visible = false
	player.equipped_cosmetics.erase(c)
	for i in inventory_items.get_children():
		if i.cosmetic_name == c:
			i.checkmark.visible = false

func select() -> void:
	inventory_label.visible = selected
	map.visible = selected
	map_label.visible = selected
	system_menu_button.visible = selected
	back_button.visible = selected
	inventory_overlay.visible = selected

	inventory_full.visible = not selected
	inventory_items.get_child(0).grab_focus()
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
