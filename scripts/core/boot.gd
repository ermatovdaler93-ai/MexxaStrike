# res://scripts/core/boot.gd
# Автозагрузка (autoload "Boot", см. project.godot). Выполняется один раз при старте:
#   FPS применяется из профиля в Game; экран не гаснет во время игры,
#   касания обрабатываются без накопления (меньше задержка управления).
extends Node

const C = preload("res://scripts/core/constants.gd")


func _ready() -> void:
    Input.use_accumulated_input = false
    DisplayServer.screen_set_keep_on(true)
    print("[MEXXA] Boot: %s" % C.GAME_NAME)
