@icon("res://addons/vaporwavesky/vwsky_icon.png")
@tool
extends ShaderMaterial
class_name VaporwaveSkyMaterial

const VWSkyShader = preload("res://addons/vaporwavesky/vaporwave.gdshader")

const IGNORED_PROPERTIES = [
	"shader"
]

func _validate_property(property):
	if property.name in IGNORED_PROPERTIES:
		property.usage = PROPERTY_USAGE_NO_EDITOR
		
func _init():
	shader = VWSkyShader

func _get_shader_mode():
	return Shader.MODE_SKY
	
func _get_shader_rid():
	return VWSkyShader.get_rid()
