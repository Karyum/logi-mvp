extends Resource
class_name MapConfiguration


@export var starting_positions: Array[Vector2i] = []
@export var territories_hexes: Array[TerritoryResource] = []
@export var armies: Array[ArmySpawnersResource] = []
#@export var camera_rotation: Dictionary[Vector2i, int] = {}
@export var max_zoom: float = 0.5
@export var min_zoom: float = 0.2
@export var map_scene: PackedScene = null
@export var trucks_amount: int = 3
