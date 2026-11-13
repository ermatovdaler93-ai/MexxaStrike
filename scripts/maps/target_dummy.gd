# res://scripts/maps/target_dummy.gd
# Мишень-манекен для тира: двигается из стороны в сторону, имеет здоровье,
# мигает при попадании, «умирает» и возрождается через 2 секунды.
# Настоящие боты с ИИ появятся в отдельной фазе.
extends AnimatableBody3D

const MAX_HEALTH := 100.0
const RESPAWN_TIME := 2.0

signal killed

var _health := MAX_HEALTH
var _alive := true
var _origin := Vector3.ZERO
var _amplitude := Vector3.ZERO
var _speed := 1.0
var _phase := 0.0
var _t := 0.0
var _flash := 0.0
var _base_color := Color(0.9, 0.15, 0.15)
var _mat: StandardMaterial3D
var _mesh: MeshInstance3D
var _col: CollisionShape3D
var _respawn_timer: Timer


func setup(origin: Vector3, amplitude: Vector3, speed: float, phase: float) -> void:
    _origin = origin
    _amplitude = amplitude
    _speed = speed
    _phase = phase
    position = origin


func _ready() -> void:
    _col = CollisionShape3D.new()
    var shape := CapsuleShape3D.new()
    shape.radius = 0.45
    shape.height = 1.8
    _col.shape = shape
    add_child(_col)

    _mesh = MeshInstance3D.new()
    var capsule := CapsuleMesh.new()
    capsule.radius = 0.45
    capsule.height = 1.8
    _mesh.mesh = capsule
    _mat = StandardMaterial3D.new()
    _mat.albedo_color = _base_color
    _mesh.material_override = _mat
    add_child(_mesh)

    _respawn_timer = Timer.new()
    _respawn_timer.one_shot = true
    _respawn_timer.timeout.connect(_respawn)
    add_child(_respawn_timer)


func _physics_process(delta: float) -> void:
    if not _alive:
        return
    _t += delta * _speed
    position = _origin + _amplitude * sin(_t + _phase)


func _process(delta: float) -> void:
    _flash = move_toward(_flash, 0.0, delta * 6.0)
    var base := _base_color.darkened(0.5 * (1.0 - _health / MAX_HEALTH))
    _mat.albedo_color = base.lerp(Color.WHITE, _flash)


## Возвращает true, если этим попаданием мишень уничтожена.
func take_damage(amount: float) -> bool:
    if not _alive:
        return false
    _health -= amount
    _flash = 1.0
    if _health <= 0.0:
        _die()
        return true
    return false


func _die() -> void:
    _alive = false
    _mesh.visible = false
    _col.set_deferred("disabled", true)
    killed.emit()
    _respawn_timer.start(RESPAWN_TIME)


func _respawn() -> void:
    _health = MAX_HEALTH
    _alive = true
    _mesh.visible = true
    _col.disabled = false
