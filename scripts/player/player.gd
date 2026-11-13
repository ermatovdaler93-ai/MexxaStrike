# res://scripts/player/player.gd
# Игрок от первого лица: движение, прыжок, приседание, стрельба лучом (hitscan),
# перезарядка, смена оружия. Всё строится кодом в _ready().
# Управление приходит снизу из HUD: move_input, look_delta, want_fire, want_jump, crouching.
extends CharacterBody3D

const WeaponDB = preload("res://scripts/weapons/weapon_db.gd")

signal hit_confirmed(killed: bool)

const WALK_SPEED := 5.5
const CROUCH_SPEED := 2.6
const JUMP_SPEED := 5.2
const GRAVITY := 14.0
const EYE_STAND := 1.6
const EYE_CROUCH := 1.05

var active := true
var move_input := Vector2.ZERO    # x - вправо, y - назад (джойстик вверх = вперёд)
var look_delta := Vector2.ZERO    # градусы за кадр: x - рыскание, y - тангаж
var want_fire := false
var want_jump := false
var crouching := false

var weapons: Array = []
var weapon_index := 0
var mags: Array = []              # патроны в магазине для каждого оружия
var reloading := false

var match_shots := 0
var match_hits := 0

var head: Node3D
var camera: Camera3D

var _viewmodel: MeshInstance3D
var _viewmodel_mat: StandardMaterial3D
var _flash: OmniLight3D
var _reload_timer: Timer
var _spark_mesh: SphereMesh
var _spark_mat: StandardMaterial3D
var _pitch := 0.0
var _kick := 0.0
var _fire_cooldown := 0.0
var _flash_time := 0.0
var _eye_height := EYE_STAND


func _ready() -> void:
    var col := CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.4
    shape.height = 1.8
    col.shape = shape
    col.position = Vector3(0.0, 0.9, 0.0)
    add_child(col)

    head = Node3D.new()
    head.position = Vector3(0.0, EYE_STAND, 0.0)
    add_child(head)

    camera = Camera3D.new()
    camera.fov = 75.0
    camera.near = 0.05
    head.add_child(camera)
    camera.make_current()

    # «Оружие в руках»: простой параллелепипед, цвет и длина зависят от оружия
    _viewmodel = MeshInstance3D.new()
    var box := BoxMesh.new()
    box.size = Vector3(0.09, 0.12, 0.55)
    _viewmodel.mesh = box
    _viewmodel_mat = StandardMaterial3D.new()
    _viewmodel.material_override = _viewmodel_mat
    _viewmodel.position = Vector3(0.24, -0.22, -0.5)
    camera.add_child(_viewmodel)

    # Вспышка выстрела
    _flash = OmniLight3D.new()
    _flash.light_color = Color(1.0, 0.8, 0.4)
    _flash.omni_range = 6.0
    _flash.light_energy = 0.0
    _flash.position = Vector3(0.24, -0.2, -0.9)
    camera.add_child(_flash)

    # Общие ресурсы для искр попадания
    _spark_mesh = SphereMesh.new()
    _spark_mesh.radius = 0.07
    _spark_mesh.height = 0.14
    _spark_mat = StandardMaterial3D.new()
    _spark_mat.albedo_color = Color(1.0, 0.7, 0.2)
    _spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

    _reload_timer = Timer.new()
    _reload_timer.one_shot = true
    _reload_timer.timeout.connect(_finish_reload)
    add_child(_reload_timer)

    weapons = WeaponDB.all()
    for w in weapons:
        mags.append(w.magazine_size)
    _apply_weapon_visual()


func _process(delta: float) -> void:
    if active:
        rotate_y(deg_to_rad(-look_delta.x))
        _pitch = clampf(_pitch - look_delta.y, -85.0, 85.0)
    look_delta = Vector2.ZERO

    _kick = move_toward(_kick, 0.0, delta * 14.0)
    head.rotation.x = deg_to_rad(_pitch + _kick)

    var eye_target := EYE_CROUCH if crouching else EYE_STAND
    _eye_height = move_toward(_eye_height, eye_target, delta * 5.0)
    head.position.y = _eye_height

    # Отдача «оружия в руках» и наклон при перезарядке
    _viewmodel.position.z = lerpf(_viewmodel.position.z, -0.5, delta * 12.0)
    var tilt := -25.0 if reloading else 0.0
    _viewmodel.rotation_degrees.x = lerpf(_viewmodel.rotation_degrees.x, tilt, delta * 8.0)

    if _flash_time > 0.0:
        _flash_time -= delta
        if _flash_time <= 0.0:
            _flash.light_energy = 0.0


func _physics_process(delta: float) -> void:
    var dir := Vector3.ZERO
    if active:
        dir = transform.basis * Vector3(move_input.x, 0.0, move_input.y)
    var speed := CROUCH_SPEED if crouching else WALK_SPEED
    velocity.x = dir.x * speed
    velocity.z = dir.z * speed

    if is_on_floor():
        if want_jump and active:
            velocity.y = JUMP_SPEED
    else:
        velocity.y -= GRAVITY * delta
    want_jump = false
    move_and_slide()

    _fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
    if active and want_fire and not reloading and _fire_cooldown <= 0.0:
        _fire()
        if not weapons[weapon_index].automatic:
            want_fire = false   # полуавтомат: один выстрел на нажатие


func current_weapon():
    return weapons[weapon_index]


func current_ammo() -> int:
    return mags[weapon_index]


func _fire() -> void:
    var w = weapons[weapon_index]
    if mags[weapon_index] <= 0:
        reload()
        return

    mags[weapon_index] -= 1
    _fire_cooldown = w.fire_interval
    match_shots += 1

    var space := get_world_3d().direct_space_state
    var cam_t := camera.global_transform
    var origin := cam_t.origin
    var spread := deg_to_rad(w.spread_deg)
    var any_hit := false
    var any_kill := false

    for i in range(w.pellets):
        var dir := -cam_t.basis.z
        dir = dir.rotated(cam_t.basis.x, randf_range(-spread, spread))
        dir = dir.rotated(cam_t.basis.y, randf_range(-spread, spread))
        var query := PhysicsRayQueryParameters3D.create(origin, origin + dir.normalized() * w.max_range)
        query.exclude = [get_rid()]
        var result := space.intersect_ray(query)
        if result.is_empty():
            continue
        _spawn_spark(result["position"])
        var collider = result["collider"]
        if collider != null and collider.has_method("take_damage"):
            any_hit = true
            if collider.take_damage(w.damage):
                any_kill = true

    if any_hit:
        match_hits += 1
        hit_confirmed.emit(any_kill)

    _kick += w.recoil_deg
    _viewmodel.position.z = -0.42
    _flash.light_energy = 3.0
    _flash_time = 0.05

    if mags[weapon_index] <= 0:
        reload()


func _spawn_spark(pos: Vector3) -> void:
    var spark := MeshInstance3D.new()
    spark.mesh = _spark_mesh
    spark.material_override = _spark_mat
    get_parent().add_child(spark)
    spark.global_position = pos
    get_tree().create_timer(0.2).timeout.connect(spark.queue_free)


func reload() -> void:
    var w = weapons[weapon_index]
    if reloading or mags[weapon_index] >= w.magazine_size:
        return
    reloading = true
    _reload_timer.start(w.reload_time)


func _finish_reload() -> void:
    mags[weapon_index] = weapons[weapon_index].magazine_size
    reloading = false


func next_weapon() -> void:
    weapon_index = (weapon_index + 1) % weapons.size()
    _reload_timer.stop()
    reloading = false
    _fire_cooldown = 0.25
    want_fire = false
    _apply_weapon_visual()


func _apply_weapon_visual() -> void:
    var w = weapons[weapon_index]
    _viewmodel_mat.albedo_color = w.color
    _viewmodel.scale = Vector3(1.0, 1.0, 0.6 + w.max_range / 250.0)
