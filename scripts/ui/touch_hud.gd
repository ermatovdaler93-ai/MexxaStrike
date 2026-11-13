# res://scripts/ui/touch_hud.gd
# Мобильный HUD и сенсорное управление, всё рисуется в _draw():
#   - плавающий джойстик слева (палец, начавший касание в левых 40% экрана);
#   - зона обзора справа (перетаскивание пальцем; можно вращать камеру и пальцем на кнопке огня);
#   - кнопки: огонь, прыжок, приседание (переключатель), перезарядка, смена оружия, меню;
#   - прицел, маркер попадания, патроны, таймер, счёт, экран результатов.
# Мультитач: каждому пальцу (index) назначается роль при касании.
# Создаётся в test_arena.gd, получает игрока и арену через setup().
extends Control

const ORANGE := Color(1.0, 0.55, 0.1)
const JOY_RADIUS := 110.0
const LOOK_FACTOR := 0.12      # градусов на пиксель при чувствительности 1.0

var player
var arena

var _font: Font
var _size := Vector2(1280.0, 720.0)
var _buttons := {}             # роль -> {"c": центр, "r": радиус, "key": ключ строки}
var _roles := {}               # индекс пальца -> роль
var _joy_index := -1
var _joy_center := Vector2.ZERO
var _joy_offset := Vector2.ZERO
var _hit_flash := 0.0
var _hit_kill := false


func setup(p, a) -> void:
    player = p
    arena = a
    _font = ThemeDB.fallback_font
    player.hit_confirmed.connect(_on_hit)
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    _layout()


func _on_hit(killed: bool) -> void:
    _hit_flash = 0.25
    _hit_kill = killed


func _layout() -> void:
    var s := get_viewport_rect().size
    if s == _size and not _buttons.is_empty():
        return
    _size = s
    _buttons = {
        "fire": {"c": Vector2(s.x - 190.0, s.y - 170.0), "r": 90.0, "key": "hud_fire"},
        "jump": {"c": Vector2(s.x - 75.0, s.y - 300.0), "r": 55.0, "key": "hud_jump"},
        "crouch": {"c": Vector2(s.x - 340.0, s.y - 70.0), "r": 50.0, "key": "hud_crouch"},
        "reload": {"c": Vector2(s.x - 345.0, s.y - 195.0), "r": 50.0, "key": "hud_reload"},
        "swap": {"c": Vector2(s.x - 230.0, s.y - 345.0), "r": 50.0, "key": "hud_swap"},
        "menu": {"c": Vector2(s.x - 55.0, 55.0), "r": 36.0, "key": "hud_menu"},
    }


func _process(delta: float) -> void:
    if player == null:
        return
    _layout()
    _hit_flash = maxf(_hit_flash - delta, 0.0)
    queue_redraw()


func _notification(what: int) -> void:
    # Приложение свернули: сбрасываем «залипшие» касания
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT and player != null:
        _roles.clear()
        _joy_index = -1
        _joy_offset = Vector2.ZERO
        player.move_input = Vector2.ZERO
        player.want_fire = false


# ---------------------------------------------------------------- ввод

func _input(event: InputEvent) -> void:
    if player == null:
        return
    if arena.finished:
        _results_input(event)
        return
    if event is InputEventScreenTouch:
        if event.pressed:
            _touch_down(event.index, event.position)
        else:
            _touch_up(event.index)
    elif event is InputEventScreenDrag:
        _touch_drag(event.index, event.position, event.relative)


func _touch_down(index: int, pos: Vector2) -> void:
    for role in _buttons:
        var b: Dictionary = _buttons[role]
        if pos.distance_to(b["c"]) <= float(b["r"]) + 12.0:
            _roles[index] = role
            _press(role)
            return
    if pos.x < _size.x * 0.4 and _joy_index == -1:
        _roles[index] = "joy"
        _joy_index = index
        _joy_center = pos
        _joy_offset = Vector2.ZERO
    else:
        _roles[index] = "look"


func _press(role: String) -> void:
    match role:
        "fire":
            player.want_fire = true
        "jump":
            player.want_jump = true
        "crouch":
            player.crouching = not player.crouching
        "reload":
            player.reload()
        "swap":
            player.next_weapon()
        "menu":
            Game.go_menu()


func _touch_up(index: int) -> void:
    var role: String = _roles.get(index, "")
    _roles.erase(index)
    if role == "joy":
        _joy_index = -1
        _joy_offset = Vector2.ZERO
        player.move_input = Vector2.ZERO
    elif role == "fire":
        player.want_fire = false


func _touch_drag(index: int, pos: Vector2, rel: Vector2) -> void:
    var role: String = _roles.get(index, "")
    if role == "joy":
        var offset := pos - _joy_center
        if offset.length() > JOY_RADIUS:
            offset = offset.normalized() * JOY_RADIUS
        _joy_offset = offset
        var v := offset / JOY_RADIUS
        player.move_input = Vector2.ZERO if v.length() < 0.12 else v
    elif role == "look" or role == "fire":
        var sens := float(Game.profile["sensitivity"])
        player.look_delta += rel * LOOK_FACTOR * sens


func _results_rects() -> Dictionary:
    var c := _size * 0.5
    return {
        "again": Rect2(c.x - 330.0, c.y + 80.0, 300.0, 80.0),
        "menu": Rect2(c.x + 30.0, c.y + 80.0, 300.0, 80.0),
    }


func _results_input(event: InputEvent) -> void:
    if event is InputEventScreenTouch and event.pressed:
        var rects := _results_rects()
        if rects["again"].has_point(event.position):
            get_tree().reload_current_scene()
        elif rects["menu"].has_point(event.position):
            Game.go_menu()


# ---------------------------------------------------------------- отрисовка

func _text(pos: Vector2, text: String, font_size: int, color: Color, width: float = -1.0,
        align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
    draw_string(_font, pos, text, align, width, font_size, color)


func _draw() -> void:
    if player == null:
        return
    var s := _size
    var center := s * 0.5

    # Прицел
    var cc := Color(1.0, 1.0, 1.0, 0.9)
    draw_line(center + Vector2(-16.0, 0.0), center + Vector2(-6.0, 0.0), cc, 2.0)
    draw_line(center + Vector2(6.0, 0.0), center + Vector2(16.0, 0.0), cc, 2.0)
    draw_line(center + Vector2(0.0, -16.0), center + Vector2(0.0, -6.0), cc, 2.0)
    draw_line(center + Vector2(0.0, 6.0), center + Vector2(0.0, 16.0), cc, 2.0)
    if _hit_flash > 0.0:
        var hc := Color(1.0, 0.2, 0.2) if _hit_kill else Color.WHITE
        draw_line(center + Vector2(-12.0, -12.0), center + Vector2(-5.0, -5.0), hc, 3.0)
        draw_line(center + Vector2(12.0, -12.0), center + Vector2(5.0, -5.0), hc, 3.0)
        draw_line(center + Vector2(-12.0, 12.0), center + Vector2(-5.0, 5.0), hc, 3.0)
        draw_line(center + Vector2(12.0, 12.0), center + Vector2(5.0, 5.0), hc, 3.0)

    # Верхняя панель: время и счёт
    var secs := int(ceil(arena.time_left))
    var mins := floori(secs / 60.0)
    _text(Vector2(24.0, 46.0), "%s %d:%02d" % [Game.t("time"), mins, secs % 60], 34, Color.WHITE)
    _text(Vector2(24.0, 90.0), "%s %d" % [Game.t("score"), arena.score], 34, ORANGE)

    # Оружие и патроны (внизу по центру)
    var w = player.current_weapon()
    _text(Vector2(center.x - 160.0, s.y - 78.0), w.display_name, 30, ORANGE, 320.0,
        HORIZONTAL_ALIGNMENT_CENTER)
    var ammo_text := Game.t("reloading") if player.reloading \
        else "%d / %d" % [player.current_ammo(), w.magazine_size]
    _text(Vector2(center.x - 160.0, s.y - 34.0), ammo_text, 38, Color.WHITE, 320.0,
        HORIZONTAL_ALIGNMENT_CENTER)

    # Джойстик
    if _joy_index != -1:
        draw_circle(_joy_center, JOY_RADIUS, Color(1.0, 1.0, 1.0, 0.10))
        draw_arc(_joy_center, JOY_RADIUS, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.35), 3.0)
        draw_circle(_joy_center + _joy_offset, 44.0, Color(1.0, 1.0, 1.0, 0.35))
    else:
        var hint := Vector2(s.x * 0.14, s.y * 0.72)
        draw_arc(hint, JOY_RADIUS * 0.8, 0.0, TAU, 48, Color(1.0, 1.0, 1.0, 0.12), 3.0)

    # Кнопки
    var pressed_roles := _roles.values()
    for role in _buttons:
        var b: Dictionary = _buttons[role]
        var c: Vector2 = b["c"]
        var r: float = b["r"]
        var on: bool = pressed_roles.has(role) or (role == "crouch" and player.crouching)
        draw_circle(c, r, Color(1.0, 0.55, 0.1, 0.40) if on else Color(1.0, 1.0, 1.0, 0.14))
        draw_arc(c, r, 0.0, TAU, 40, Color(1.0, 1.0, 1.0, 0.5), 3.0)
        var fs := 30 if role == "fire" else 18
        _text(c + Vector2(-r, fs * 0.35), Game.t(b["key"]), fs, Color.WHITE, r * 2.0,
            HORIZONTAL_ALIGNMENT_CENTER)

    # Результаты матча
    if arena.finished:
        draw_rect(Rect2(Vector2.ZERO, s), Color(0.0, 0.0, 0.0, 0.70))
        var acc := 0.0
        if player.match_shots > 0:
            acc = 100.0 * player.match_hits / player.match_shots
        _text(Vector2(center.x - 300.0, center.y - 100.0), Game.t("results"), 56, ORANGE, 600.0,
            HORIZONTAL_ALIGNMENT_CENTER)
        _text(Vector2(center.x - 300.0, center.y - 30.0), "%s: %d" % [Game.t("score"), arena.score],
            40, Color.WHITE, 600.0, HORIZONTAL_ALIGNMENT_CENTER)
        _text(Vector2(center.x - 300.0, center.y + 25.0),
            "%s: %.0f%%" % [Game.t("accuracy"), acc], 34, Color.WHITE, 600.0,
            HORIZONTAL_ALIGNMENT_CENTER)
        var rects := _results_rects()
        for key in rects:
            var rc: Rect2 = rects[key]
            draw_rect(rc, Color(1.0, 0.55, 0.1, 0.35))
            draw_rect(rc, Color(1.0, 1.0, 1.0, 0.6), false, 3.0)
            var label := Game.t("again") if key == "again" else Game.t("hud_menu")
            _text(Vector2(rc.position.x, rc.position.y + 52.0), label, 32, Color.WHITE, rc.size.x,
                HORIZONTAL_ALIGNMENT_CENTER)
