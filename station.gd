extends Node3D

func _ready():
	var gltf_document_save := GLTFDocument.new()
	var gltf_state_save := GLTFState.new()
	gltf_document_save.visibility_mode = GLTFDocument.VISIBILITY_MODE_INCLUDE_OPTIONAL
	gltf_document_save.append_from_scene(get_tree().root, gltf_state_save)
	gltf_document_save.write_to_filesystem(gltf_state_save, "stationtest.glb")
