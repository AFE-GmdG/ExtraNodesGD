tool
extends EditorPlugin

func _enter_tree() -> void:
    var throwCast2DScript = preload("res://addons/ExtraNodesGD/Nodes/ThrowCast2D.gd")
    var throwCast2DIcon = preload("res://addons/ExtraNodesGD/Icons/ThrowCast2D.png")
    add_custom_type("ThrowCast2D", "Node2D", throwCast2DScript, throwCast2DIcon)

func _exit_tree() -> void:
    remove_custom_type("ThrowCast2D")
