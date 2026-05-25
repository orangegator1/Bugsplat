class_name InventoryItem extends Control

@onready var color_rect: ColorRect = $ColorRect
@onready var icon: TextureRect = $Icon
@onready var checkmark: Sprite2D = $Checkmark

var cosmetic_name := ""
signal item_selected(item: InventoryItem)

func _ready() -> void:
	self.focus_entered.connect(focused)
	self.focus_exited.connect(focused.bind(false))


func focused(flag := true) -> void:
	color_rect.visible = flag


func _unhandled_input(event: InputEvent) -> void:
	if self.has_focus():
		if (event.is_action_pressed("ui_accept")
				or event.is_action_pressed("interact")):
			item_selected.emit(self)
