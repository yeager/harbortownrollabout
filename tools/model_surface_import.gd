@tool
extends EditorScenePostImport

# Separate detail coordinates preserve authored artwork and the density of grain across UV seams.
const Surface := preload("res://art/surfaces/model_finish.gd")
const FINISHES := {
	"skin": ["lid rim", "lips"],
	"wood": ["timber", "oak", "wood", "beech", "bark"],
	"mineral": ["stone", "concrete", "plaster", "brick", "roof tile"],
	"rubber": ["tire", "tyre", "rubber", "sidewall", "tread"],
	"denim_fabric_04": ["denim", "trousers"],
	"cotton_jersey": ["cotton", "jacket", "collar lining"],
	"weave": ["fabric", "seat cloth", "upholstery", "zipper tape"],
	"brushed": ["brushed", "steel", "copper", "aluminium", "aluminum", "wheel forging"],
	"leaf": ["leaves", "leaf green", "spruce", "needles"],
	"paint": ["enamel", "lacquer", "paint", "rear bumper anthracite", "ceramic white", "gloss black", "traffic car", "rescue red"]
}

func _post_import(scene: Node) -> Object:
	var meshes := scene.find_children("*", "MeshInstance3D", true, false)
	if scene is MeshInstance3D:
		meshes.append(scene)
	for mesh: MeshInstance3D in meshes:
		for i in mesh.mesh.get_surface_count():
			var mat := mesh.get_active_material(i) as StandardMaterial3D
			if mat and not mat.detail_enabled and not mat.albedo_texture:
				apply_finish(mat)
	return scene

func apply_finish(mat: StandardMaterial3D) -> void:
	var label := mat.resource_name.to_lower()
	for finish: String in FINISHES:
		for word: String in FINISHES[finish]:
			if not label.contains(word):
				continue
			Surface.apply(mat, finish)
			return
