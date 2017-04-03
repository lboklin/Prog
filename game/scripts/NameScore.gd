extends HSplitContainer

# onready var nd_name = get_node("Name")
# onready var nd_score = get_node("Score")


func set_name_score(name, score):
    get_node("Name").set_text(name)
    get_node("Score").set_text(str(score))


func _ready():
    pass
