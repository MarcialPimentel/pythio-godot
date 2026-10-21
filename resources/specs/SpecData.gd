# resources/specs/SpecData.gd
# A specialization (school) you pick at the start of a run. It gives your starter spell
# and decides which spells you're offered most.
class_name SpecData
extends Resource

@export var id: String = "mending"
@export var display_name: String = "Mending"
@export_enum("MENDING", "BLOOM", "WARD") var school: String = "MENDING"
## One line under the name.
@export var tagline: String = ""
## A sentence or two on how the school plays.
@export_multiline var description: String = ""
@export var starter: SpellData
## Order on the pick screen.
@export var order: int = 0
