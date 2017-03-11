extends Node


var round_timer = 0
var points = {}
signal player_killed()


func _add_point(reciever):
  points[reciever] += 1


func _process(delta):
	self.round_timer += delta


func _ready():
  for p_id in GameState.players.values():
    get_tree().find_node(p_id).connect("player_killed", self, "add_point")
  for p in GameState.players.keys():
    points[p] = 0
	set_process(true)
