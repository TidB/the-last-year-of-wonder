extends Node3D

func _ready():
	var dialogues = get_tree().get_nodes_in_group(Global.DIALOGUE_GROUP)
	for d in dialogues:
		d.set_player(%Player)  # TODO: At some point, we might switch to signals
	#export()
	
func _process(_delta):
	get_tree().call_group("npc", "look_at_player", %Player.position)

func export():
	var gltf_document_save := GLTFDocument.new()
	var gltf_state_save := GLTFState.new()
	gltf_document_save.visibility_mode = GLTFDocument.VISIBILITY_MODE_INCLUDE_OPTIONAL
	gltf_document_save.append_from_scene(get_tree().root, gltf_state_save)
	gltf_document_save.write_to_filesystem(gltf_state_save, "stationtest.glb")
