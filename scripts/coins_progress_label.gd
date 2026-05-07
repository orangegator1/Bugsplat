extends Label

@onready var game_manager: Node = $GameManager

func _ready():
	set_text(str(game_manager.score) + "/" + str(game_manager.possible_score) + "\ncoins")
