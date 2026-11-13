# res://scripts/maps/test_arena.gd
# Тестовая арена-тир: пол, стены, укрытия, движущиеся мишени, игрок и HUD.
# Вся геометрия строится кодом (никаких внешних моделей).
# Матч длится MATCH_TIME секунд; после окончания показываются результаты.
extends Node3D

const Player = preload("res://scripts/player/player.gd")
const Dummy = preload("res://scripts/maps/target_dummy.gd")
const Hud = preload("res://scripts/ui/touch_hud.gd")

const MATCH_TIME := 120.0
const ARENA_HALF := 30.0

var time_left := MATCH_TIME
var score := 0
var finished := false
var player

var _grid_tex: ImageTexture


func _ready() -> void:
    _grid_tex = _make_grid_texture()
    _build_environment()
    _build_level()
    _spawn_targets()

    player = Player.new()
    player.position = Vector3(0.0, 0.1, 24.0)   # смотрит в сторону -Z, к мишеням
    add_child(player)

    var layer := CanvasLayer.new()
    add_child(layer)
    var hud = Hud.new()
    layer.add_child(hud)
    hud.setup(player, self)
    Game.call_deferred("apply_performance_settings")


func _process(delta: float) -> void:
    if finished:
        return
    time_left -= delta
    if time_left <= 0.0:
        time_left = 0.0
        _finish()


func _notification(what: int) -> void:
    # Кнопка «Назад» на Android возвращает в меню
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        Game.go_menu()


func _finish() -> void:
    finished = true
    player.active = false
    player.want_fire = false
    player.move_input = Vector2.ZERO
    Game.record_match(score, player.match_shots, player.match_hits)


func _on_dummy_killed() -> void:
    if not finished:
        score += 1


# ---------------------------------------------------------------- построение мира

func _build_environment() -> void:
    var env := Environment.new()
    var sky := Sky.new()
    var sky_mat := ProceduralSkyMaterial.new()
    sky_mat.sky_top_color = Color(0.10, 0.18, 0.40)
    sky_mat.sky_horizon_color = Color(0.85, 0.55, 0.35)
    sky_mat.ground_horizon_color = Color(0.85, 0.55, 0.35)
    sky_mat.ground_bottom_color = Color(0.10, 0.10, 0.15)
    sky.sky_material = sky_mat
    env.background_mode = Environment.BG_SKY
    env.sky = sky
    env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
    env.ambient_light_energy = 1.0
    var we := WorldEnvironment.new()
    we.environment = env
    add_child(we)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
    sun.light_energy = 1.1
    add_child(sun)


func _build_level() -> void:
    var floor_mat := _make_mat(Color(0.55, 0.58, 0.65))
    var wall_mat := _make_mat(Color(0.35, 0.40, 0.55))
    var size := ARENA_HALF * 2.0

    # Пол и периметр
    _add_box(Vector3(0.0, -0.5, 0.0), Vector3(size, 1.0, size), floor_mat)
    _add_box(Vector3(0.0, 2.5, -ARENA_HALF - 0.5), Vector3(size + 2.0, 5.0, 1.0), wall_mat)
    _add_box(Vector3(0.0, 2.5, ARENA_HALF + 0.5), Vector3(size + 2.0, 5.0, 1.0), wall_mat)
    _add_box(Vector3(-ARENA_HALF - 0.5, 2.5, 0.0), Vector3(1.0, 5.0, size + 2.0), wall_mat)
    _add_box(Vector3(ARENA_HALF + 0.5, 2.5, 0.0), Vector3(1.0, 5.0, size + 2.0), wall_mat)

    # Низкие укрытия у точки старта (для тренировки приседания)
    var low_mat := _make_mat(Color(0.20, 0.75, 0.85))
    _add_box(Vector3(-6.0, 0.6, 18.0), Vector3(6.0, 1.2, 0.8), low_mat)
    _add_box(Vector3(6.0, 0.6, 18.0), Vector3(6.0, 1.2, 0.8), low_mat)

    # Ящики-укрытия между игроком и мишенями (фиксированная раскладка)
    var palette := [
        Color(0.95, 0.55, 0.15), Color(0.65, 0.35, 0.85),
        Color(0.20, 0.75, 0.85), Color(0.90, 0.30, 0.40),
    ]
    var rng := RandomNumberGenerator.new()
    rng.seed = 20260101
    for i in range(14):
        var s := rng.randf_range(1.4, 3.0)
        var h := rng.randf_range(1.2, 3.0)
        var x := rng.randf_range(-24.0, 24.0)
        var z := rng.randf_range(-4.0, 12.0)
        _add_box(Vector3(x, h * 0.5, z), Vector3(s, h, s), _make_mat(palette[i % palette.size()]))


func _spawn_targets() -> void:
    var count := clampi(Game.target_count, 3, 10)
    var rng := RandomNumberGenerator.new()
    rng.randomize()
    for i in range(count):
        var x := lerpf(-20.0, 20.0, (i + 0.5) / float(count))
        var z := rng.randf_range(-26.0, -10.0)
        var dummy = Dummy.new()
        add_child(dummy)
        dummy.setup(
            Vector3(x, 0.9, z),
            Vector3(rng.randf_range(2.0, 6.0), 0.0, 0.0),
            rng.randf_range(0.6, 1.3),
            rng.randf() * TAU)
        dummy.killed.connect(_on_dummy_killed)


func _add_box(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
    var body := StaticBody3D.new()
    body.position = pos
    var col := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    col.shape = shape
    body.add_child(col)
    var mi := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    mi.mesh = mesh
    mi.material_override = mat
    body.add_child(mi)
    add_child(body)


func _make_mat(color: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = color
    m.albedo_texture = _grid_tex
    m.uv1_triplanar = true                  # текстура-сетка без UV-развёртки
    m.uv1_scale = Vector3(0.5, 0.5, 0.5)
    return m


## Белая текстура с серыми линиями: albedo_color окрашивает её в нужный цвет.
func _make_grid_texture() -> ImageTexture:
    var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
    img.fill(Color(1.0, 1.0, 1.0))
    var line := Color(0.6, 0.6, 0.65)
    for i in range(64):
        for k in range(2):
            img.set_pixel(i, k, line)
            img.set_pixel(k, i, line)
    return ImageTexture.create_from_image(img)
