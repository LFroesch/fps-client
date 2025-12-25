extends Node3D
class_name Pickup

const READY_MATERIAL := preload("res://asset_packs/tutorial-fps-assets/materials/pickup_ready_material.tres")
const NOT_READY_MATERIAL := preload("res://asset_packs/tutorial-fps-assets/materials/pickup_not_ready_material.tres")

@onready var platform: CSGCylinder3D = %Platform
@onready var mesh_holder: Node3D = $MeshHolder

enum PickupTypes {
	HealthPickup,
	GrenadePickup,
	AmmoPickup
}

var pickup_type : PickupTypes

func _ready() -> void:
	match pickup_type:
		PickupTypes.HealthPickup:
			mesh_holder.add_child(load("res://asset_packs/tutorial-fps-assets/meshes/items/health.tscn").instantiate())
		PickupTypes.GrenadePickup:
			mesh_holder.add_child(load("res://asset_packs/tutorial-fps-assets/meshes/items/grenade.tscn").instantiate())
		PickupTypes.AmmoPickup:
			mesh_holder.add_child(load("res://player/pickups/ammo.tscn").instantiate())
func cooldown_started() -> void:
	platform.material = NOT_READY_MATERIAL
	mesh_holder.hide()
	
func cooldown_ended() -> void:
	platform.material = READY_MATERIAL
	mesh_holder.show()
