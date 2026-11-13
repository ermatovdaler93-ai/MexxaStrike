# res://scripts/core/phase1_splash.gd
# Тестовый экран Фазы 1: название игры, версия Godot, модель телефона, GPU, разрешение,
# FPS и проверка мультитача (нужен для мобильного управления шутера).
# Прикреплён к корню сцены res://scenes/boot/phase1.tscn.
extends Control

const C = preload("res://scripts/core/constants.gd")

var _info: Label
var _touches := {}          # индекс пальца -> позиция
var _max_touches := 0
var _next_update := 0.0


func _ready() -> void:
    var bg := ColorRect.new()
    bg.color = Color(0.04, 0.05, 0.08)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var box := VBoxContainer.new()
    box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    add_child(box)

    var title := Label.new()
    title.text = C.GAME_NAME
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 72)
    title.add_theme_color_override("font_color", Color(1.0, 0.55, 0.1))
    box.add_child(title)

    _info = Label.new()
    _info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _info.add_theme_font_size_override("font_size", 30)
    box.add_child(_info)


func _process(_delta: float) -> void:
    # Текст обновляем 2 раза в секунду
    var now := Time.get_ticks_msec() / 1000.0
    if now < _next_update:
        return
    _next_update = now + 0.5

    var v := Engine.get_version_info()
    var win := DisplayServer.window_get_size()
    _info.text = "Phase 1: Godot pipeline OK\n\n" \
        + "Godot %s\n" % v["string"] \
        + "Device: %s (%s)\n" % [OS.get_model_name(), OS.get_name()] \
        + "GPU: %s\n" % RenderingServer.get_video_adapter_name() \
        + "Screen: %dx%d\n" % [win.x, win.y] \
        + "FPS: %d (target %d)\n" % [Engine.get_frames_per_second(), C.TARGET_FPS] \
        + "Touches: %d (max %d) - touch the screen with several fingers" % [_touches.size(), _max_touches]


func _input(event: InputEvent) -> void:
    if event is InputEventScreenTouch:
        if event.pressed:
            _touches[event.index] = event.position
        else:
            _touches.erase(event.index)
        _max_touches = maxi(_max_touches, _touches.size())
    elif event is InputEventScreenDrag:
        _touches[event.index] = event.position
