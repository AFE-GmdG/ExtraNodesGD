tool
extends Node2D
class_name ThrowCast2D

# Other Fields
var _rebuild_necessary: bool = false
var _exclude: Array = []
var _debug_mesh: MeshInstance2D
var _is_colliding: bool = false
var _collider: Object = null
var _collision_point: Vector2 = Vector2()
var _collision_normal: Vector2 = Vector2()
var _collision_shape: int = 0

# Exported Properties
export var enabled: bool = false setget _set_enabled, _get_enabled

func _set_enabled(value: bool) -> void:
    enabled = value
    _rebuild_necessary = true

func _get_enabled() -> bool:
    return enabled

export var exclude_parent: bool = true setget _set_exclude_parent, _get_exclude_parent

func _set_exclude_parent(value: bool) -> void:
    exclude_parent = value
    if not is_inside_tree():
        return
    var parent_collision_object = get_parent()
    if not parent_collision_object:
        return
    if value and not _exclude.has(parent_collision_object.get_rid()):
        _exclude.append(parent_collision_object.get_rid())
    else:
        _exclude.remove(parent_collision_object.get_rid())

func _get_exclude_parent() -> bool:
    return exclude_parent

var throw_angle: float = 0.0 setget _set_throw_angle, _get_throw_angle

func _set_throw_angle(value: float) -> void:
    throw_angle = value
    _rebuild_necessary = true

func _get_throw_angle() -> float:
    return throw_angle

export(float, -360.0, 360.0, 0.1) var throw_angle_deg: float = 0.0 setget _set_throw_angle_deg, _get_throw_angle_deg

func _set_throw_angle_deg(value: float) -> void:
    throw_angle = deg2rad(value)
    _rebuild_necessary = true

func _get_throw_angle_deg() -> float:
    return rad2deg(throw_angle)

export(float, 0.0, 1000.0, 0.1) var throw_speed: float = 100.0 setget _set_throw_speed, _get_throw_speed

func _set_throw_speed(value: float) -> void:
    throw_speed = value
    _rebuild_necessary = true

func _get_throw_speed() -> float:
    return throw_speed

export(float, -10.0, 10.0, 0.01) var gravity: float = 9.81 setget _set_gravity, _get_gravity

func _set_gravity(value: float) -> void:
    gravity = value
    _rebuild_necessary = true

func _get_gravity() -> float:
    return gravity

export(int, 1, 500, 1) var segments: int = 100 setget _set_segments, _get_segments

func _set_segments(value: int) -> void:
    segments = value
    _rebuild_necessary = true

func _get_segments() -> int:
    return segments

export(float, 0.0, 10.0, 0.1) var width: float = 2.0 setget _set_width, _get_width

func _set_width(value: float) -> void:
    width = value
    _rebuild_necessary = true

func _get_width() -> float:
    return width

export(int, LAYERS_2D_PHYSICS) var collision_mask: int = 1
export var collide_with_areas: bool = false
export var collide_with_bodies: bool = true
export(ShaderMaterial) var throw_cast_line_material

# Overwritten Base Methods
func _ready() -> void:
    if throw_cast_line_material == null and not Engine.editor_hint:
        throw_cast_line_material = load("res://addons/ExtraNodesGD/Nodes/ThrowCast2D.material")

func _enter_tree() -> void:
    _debug_mesh = MeshInstance2D.new()
    _debug_mesh.mesh = ArrayMesh.new()
    _debug_mesh.visible = false
    add_child(_debug_mesh)

func _exit_tree() -> void:
    if _debug_mesh != null:
        if _debug_mesh.is_inside_tree():
            _debug_mesh.queue_free()
        else:
            _debug_mesh.free()
        _debug_mesh = null

func _process(delta: float) -> void:
    if _rebuild_necessary:
        var mesh: ArrayMesh = _debug_mesh.mesh as ArrayMesh
        if mesh == null:
            return

        while mesh.get_surface_count() > 0:
            mesh.surface_remove(0)

        var vertices = PoolVector3Array()
        var uvs = PoolVector2Array()
        var indices = PoolIntArray()
        vertices.resize(segments * 2 + 2)
        uvs.resize(segments * 2 + 2)
        indices.resize(segments * 6)

        uvs[segments * 2 + 0] = Vector2(0.0, 1.0)
        uvs[segments * 2 + 1] = Vector2(1.0, 1.0)

        for i in segments:
            uvs[i * 2 + 0] = Vector2(0.0, i / float(segments))
            uvs[i * 2 + 1] = Vector2(1.0, i / float(segments))

            indices[i * 6 + 0] = i * 2 + 2
            indices[i * 6 + 1] = i * 2 + 1
            indices[i * 6 + 2] = i * 2 + 0
            indices[i * 6 + 3] = i * 2 + 2
            indices[i * 6 + 4] = i * 2 + 3
            indices[i * 6 + 5] = i * 2 + 1

        var p0 = Vector2()
        var p1 = Vector2(0.0, width * -0.5)
        var p2 = Vector2(0.0, width * 0.5)
        var p3 = Vector2()

        var vx0 = throw_speed * cos(throw_angle) # Horizontal Start Speed
        var vy0 = throw_speed * sin(throw_angle) # Vertical Start Speed

        for i in segments + 1:
            var t = i * 0.5 # Time
            var x = t * vx0 # X Position at time t
            var vy = vy0 - gravity * t # Y Speed at time t
            var y = -(vy0 * t - (gravity * 0.5 * t * t)) # Y Position at tim t (Y-Flipped)
            var phi = -atan2(vy, vx0) # Angle at time t
            p0 = Vector2(x, y)
            p3 = p1.rotated(phi) + p0
            vertices[i * 2 + 0] = Vector3(p3.x, p3.y, 0.0)
            p3 = p2.rotated(phi) + p0
            vertices[i * 2 + 1] = Vector3(p3.x, p3.y, 0.0)

        var a = []
        a.resize(Mesh.ARRAY_MAX)
        a[Mesh.ARRAY_VERTEX] = vertices
        a[Mesh.ARRAY_TEX_UV] = uvs
        a[Mesh.ARRAY_INDEX] = indices
        mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a, [], 0)
        _debug_mesh.material = throw_cast_line_material

    _debug_mesh.visible = enabled

    if not enabled:
        return

    _update_throw_cast_state()

# Public Node specific Methods
func is_colliding() -> bool:
    return _is_colliding

func get_collider() -> Object:
    return _collider

func get_collision_point() -> Vector2:
    return _collision_point

func get_collision_normal() -> Vector2:
    return _collision_normal

func get_collision_shape() -> int:
    return _collision_shape

func force_throw_cast_update() -> void:
    _update_throw_cast_state()

# Private Node specific Methods
func _update_throw_cast_state() -> void:
    var w2d = get_world_2d()
    var dss = Physics2DServer.space_get_direct_state(w2d.space)
    var gt = global_transform
    var m: ShaderMaterial = _debug_mesh.material as ShaderMaterial
    var p0 = Vector2()
    var p1 = Vector2()
    var vx0 = throw_speed * cos(throw_angle)
    var vy0 = throw_speed * sin(throw_angle)
    for i in range(1, segments + 1):
        var t = i * 0.5 # Time
        var x = t * vx0 # X Position at time t
        var y = -(vy0 * t - (gravity * 0.5 * t * t)) # Y Position at tim t (Y-Flipped)
        p1 = Vector2(x, y)
        var p2 = gt.xform(p0)
        var p3 = gt.xform(p1)
        var rr: Dictionary = dss.intersect_ray(p2, p3, _exclude, collision_mask, collide_with_bodies, collide_with_areas)
        if not rr.empty():
            _is_colliding = true
            _collider = instance_from_id(rr.collider_id)
            _collision_point = rr.position
            _collision_normal = rr.normal
            _collision_shape = rr.shape

            if m != null and m.shader.has_param("collideAt"):
                var l0 = (i - 1) / float(segments)
                var l1 = i / float(segments)
                var l2 = l1 - l0
                var l3 = (p3 - p2).length()
                var l4 = (_collision_point - p2).length()
                m.set_shader_param("collideAt", l0 + ((l4 / l3) * l2))

            return

        p0 = p1

    _is_colliding = false
    _collider = null
    _collision_point = Vector2()
    _collision_normal = Vector2()
    _collision_shape = 0

    if m != null and m.shader.has_param("collideAt"):
        m.set_shader_param("collideAt", 100.0)
