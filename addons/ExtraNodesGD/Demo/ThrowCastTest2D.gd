extends Node2D

onready var _cannon_position: StaticBody2D = $Cannon
onready var _throw_cast: ThrowCast2D = $Cannon/ThrowCast2D
onready var _laser: Line2D = $Cannon/Line2D
onready var _mouse_position_text: Label = $MousePositionText
onready var _throw_angle_text: Label = $ThrowAngleText
onready var _throw_speed_text: Label = $ThrowSpeedText
onready var _collider_text: Label = $ColliderText

# Overwritten Base Methods
func _process(delta: float) -> void:
    var mouse_position: Vector2 = get_global_mouse_position()
    _mouse_position_text.text = String(mouse_position)

    var cannon_position: Vector2 = _cannon_position.global_transform.origin
    var phi: float = atan2(cannon_position.y - mouse_position.y, mouse_position.x - cannon_position.x)
    var speed: float = (mouse_position - cannon_position).length() * 0.2

    _throw_angle_text.text = "%6.1f° ( %6.3f ) Sin: %6.3f Cos: %6.3f" % [rad2deg(phi), phi, sin(phi), cos(phi)]
    _throw_speed_text.text = "%6.1f" % speed

    _laser.clear_points()
    _laser.add_point(_cannon_position.to_local(cannon_position))
    _laser.add_point(_cannon_position.to_local(mouse_position))

    _throw_cast.throw_angle = phi;
    _throw_cast.throw_speed = speed;

    # The following values are from previous frame. If you really need the current changed values, uncomment the following line.
    # _throw_cast.force_throw_cast_update()
    if _throw_cast.is_colliding():
        _collider_text.text = "%s [ %6.1f %6.1f ]" % [_throw_cast.get_collider().name, _throw_cast.get_collision_point().x, _throw_cast.get_collision_point().y]
    else:
        _collider_text.text = "(null)"
