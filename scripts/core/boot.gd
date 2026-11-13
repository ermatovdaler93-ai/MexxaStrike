# res://scripts/core/boot.gd
# Автозагрузка (autoload "Boot", см. project.godot). Выполняется один раз при старте:
#   лимит 60 FPS, экран не гаснет во время игры, касания обрабатываются без накопления
#   (меньше задержка управления).
extends Node

const C = preload("res://scripts/core/constants.gd")


func _ready() -> void:
    Engine.max_fps = C.TARGET_FPS
    Input.use_accumulated_input = false
    DisplayServer.screen_set_keep_on(true)
    print("[MEXXA] Boot: %s, target %d FPS" % [C.GAME_NAME, C.TARGET_FPS])
