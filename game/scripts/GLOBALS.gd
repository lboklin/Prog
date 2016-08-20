extends Node

# This script is the base from which the game is loaded
# and which holds the necessary global variables and other data

const VSCALE = 0.5
const PXPM = 200

# Physical constants
# G = gravity constant (in m/(s)^2). Player is ~102 px in width; a tile is 256 px in width (isometric perspective).
const G = 9.8

var current_scene = null

func goto_scene(path):
	
    # This function will usually be called from a signal callback,
    # or some other function from the running scene.
    # Deleting the current scene at this point might be
    # a bad idea, because it may be inside of a callback or function of it.
    # The worst case will be a crash or unexpected behavior.

    # The way around this is deferring the load to a later time, when
    # it is ensured that no code from the current scene is running:
	
	call_deferred( "_deferred_goto_scene", path )
	
func _deferred_goto_scene( path ):

    # Immediately free the current scene,
    # there is no risk here.
	current_scene.free()
	
	# Load new scene
	var s = ResourceLoader().load( path )
	
	# Instance the new scene
	current_scene = s.instance()
	
	# Add it to the active scene of root
	get_tree().get_root().add_child( current_scene )
	
	# optional, to make it compatible with the SceneTree.change_scene() API
#    get_tree().set_current_scene( current_scene )
	
func _ready():
	var root = get_tree().get_root()
	current_scene = root.get_child( root.get_child_count() -1 )
