extends RefCounted

const TILES := {
	"avatar_jacket_twill": preload("res://art/surfaces/avatar_jacket_twill.jpg"),
	"wool_boucle": preload("res://art/surfaces/wool_boucle_Diffuse.jpg"),
	"denim_fabric_04": preload("res://art/surfaces/denim_fabric_04_Diffuse.jpg"),
	"cotton_jersey": preload("res://art/surfaces/cotton_jersey_Diffuse.jpg"),
	"brushed": preload("res://art/surfaces/brushed.png"),
	"leaf": preload("res://art/surfaces/leaf.png"),
	"mineral": preload("res://art/surfaces/mineral.png"),
	"paint": preload("res://art/surfaces/paint.png"),
	"rubber": preload("res://art/surfaces/rubber.png"),
	"skin": preload("res://art/surfaces/skin.png"),
	"weave": preload("res://art/surfaces/weave.png"),
	"wood": preload("res://art/surfaces/wood.png"),
}

const FABRIC_NORMALS := {
	"cotton_jersey": preload("res://art/surfaces/cotton_jersey_nor_gl.jpg"),
	"denim_fabric_04": preload("res://art/surfaces/denim_fabric_04_nor_gl.jpg"),
	"wool_boucle": preload("res://art/surfaces/wool_boucle_nor_gl.jpg"),
}

static func apply(mat: StandardMaterial3D, finish: String) -> void:
	mat.detail_albedo = TILES[finish]
	mat.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	mat.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	mat.uv2_triplanar = true
	mat.uv2_scale = Vector3.ONE * (1.5 if finish in ["wood", "mineral", "leaf"] else 5.0)
	if FABRIC_NORMALS.has(finish):
		mat.detail_normal = FABRIC_NORMALS[finish]
	mat.detail_enabled = true
