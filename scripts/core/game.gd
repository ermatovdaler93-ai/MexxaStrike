# res://scripts/core/game.gd
# Автозагрузка "Game": профиль игрока (JSON в user://), язык, переходы между сценами.
# Профиль хранится с полем version для будущих миграций формата.
extends Node

const PROFILE_PATH := "user://profile.json"
const SAVE_VERSION := 1

var profile := {
    "version": SAVE_VERSION,
    "nickname": "Player",
    "lang": "en",
    "sensitivity": 1.0,
    "fps_limit": 60,
    "graphics_quality": "medium",
    "resolution_scale": 1.0,
    "shadows": "high",
    "anti_aliasing": "msaa2",
    "effects": "medium",
    "texture_quality": "high",
    "show_fps": true,
    "kills": 0,
    "shots": 0,
    "hits": 0,
    "matches": 0,
    "best_score": 0,
}

# Настройка «Offline»: сколько мишеней в тире
var target_count := 5

# Строки интерфейса: ключ -> [English, Русский]
const STR := {
    "play": ["PLAY", "ИГРАТЬ"],
    "offline": ["OFFLINE", "ОФЛАЙН"],
    "lan": ["LAN MULTIPLAYER", "LAN-СЕТЬ"],
    "settings": ["SETTINGS", "НАСТРОЙКИ"],
    "weapons": ["WEAPONS", "ОРУЖИЕ"],
    "profile": ["PROFILE", "ПРОФИЛЬ"],
    "about": ["ABOUT", "О ИГРЕ"],
    "start": ["START", "НАЧАТЬ"],
    "targets": ["Targets", "Мишеней"],
    "offline_desc": ["Shooting range: hit moving targets for 2 minutes.", "Тир: сбивайте движущиеся мишени 2 минуты."],
    "lan_desc": ["LAN multiplayer over local Wi-Fi is coming in a later phase. No internet will be needed.", "Игра по локальной сети Wi-Fi появится в одной из следующих фаз. Интернет не понадобится."],
    "sensitivity": ["Look sensitivity", "Чувствительность камеры"],
    "performance": ["PERFORMANCE", "ПРОИЗВОДИТЕЛЬНОСТЬ"],
    "fps_limit": ["FPS limit", "Лимит FPS"],
    "graphics_quality": ["Graphics quality", "Качество графики"],
    "show_fps": ["Show FPS counter", "Показывать FPS"],
    "language": ["Language", "Язык"],
    "nickname": ["Nickname", "Ник"],
    "level": ["Level", "Уровень"],
    "kills": ["Kills", "Убийства"],
    "accuracy": ["Accuracy", "Точность"],
    "matches": ["Matches", "Матчей"],
    "best": ["Best score", "Лучший счёт"],
    "about_text": ["MEXXA STRIKE - original mobile FPS prototype built with Godot 4.\nBuild 0.2: menu, touch controls, 5 weapons, shooting range.\nControls: left thumb moves, right side looks, buttons fire / jump / crouch / reload / swap weapon.", "MEXXA STRIKE - оригинальный мобильный FPS-прототип на Godot 4.\nСборка 0.2: меню, сенсорное управление, 5 видов оружия, тир.\nУправление: левый палец - движение, правая часть экрана - обзор, кнопки: огонь / прыжок / присесть / перезарядка / смена оружия."],
    "hud_fire": ["FIRE", "ОГОНЬ"],
    "hud_jump": ["JUMP", "ПРЫЖОК"],
    "hud_crouch": ["CROUCH", "ПРИСЕСТЬ"],
    "hud_reload": ["RELOAD", "ПЕРЕЗАР."],
    "hud_swap": ["SWAP", "СМЕНА"],
    "hud_menu": ["MENU", "МЕНЮ"],
    "reloading": ["RELOADING...", "ПЕРЕЗАРЯДКА..."],
    "time": ["TIME", "ВРЕМЯ"],
    "score": ["SCORE", "СЧЁТ"],
    "results": ["TIME'S UP", "ВРЕМЯ ВЫШЛО"],
    "again": ["PLAY AGAIN", "ЕЩЁ РАЗ"],
    "dmg": ["Damage", "Урон"],
    "rate": ["Fire rate", "Скорострельность"],
    "mag": ["Magazine", "Магазин"],
    "reload": ["Reload", "Перезарядка"],
}


func _ready() -> void:
    load_profile()
    apply_performance_settings()


func apply_performance_settings() -> void:
    var fps_limit := int(profile.get("fps_limit", 60))
    if not [30, 60, 90].has(fps_limit):
        fps_limit = 60
        profile["fps_limit"] = fps_limit
    Engine.max_fps = fps_limit

    var viewport := get_viewport()
    var scale_value := float(profile.get("resolution_scale", 1.0))
    if not [0.5, 0.75, 1.0].has(scale_value):
        scale_value = 1.0
        profile["resolution_scale"] = scale_value
    viewport.scaling_3d_scale = scale_value

    var aa := str(profile.get("anti_aliasing", "msaa2"))
    match aa:
        "off":
            viewport.msaa_3d = Viewport.MSAA_DISABLED
        "msaa2":
            viewport.msaa_3d = Viewport.MSAA_2X
        "msaa4":
            viewport.msaa_3d = Viewport.MSAA_4X
        "msaa8":
            viewport.msaa_3d = Viewport.MSAA_8X
        _:
            profile["anti_aliasing"] = "msaa2"
            viewport.msaa_3d = Viewport.MSAA_2X

    viewport.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED

    var quality := str(profile.get("graphics_quality", "medium"))
    if not ["low", "medium", "high", "ultra"].has(quality):
        quality = "medium"
        profile["graphics_quality"] = quality

    _apply_scene_graphics()
    call_deferred("_apply_scene_graphics")


func apply_graphics_preset(preset: String) -> void:
    match preset:
        "low":
            profile["resolution_scale"] = 0.5
            profile["shadows"] = "off"
            profile["anti_aliasing"] = "off"
            profile["effects"] = "low"
            profile["texture_quality"] = "low"
        "medium":
            profile["resolution_scale"] = 0.75
            profile["shadows"] = "low"
            profile["anti_aliasing"] = "msaa2"
            profile["effects"] = "medium"
            profile["texture_quality"] = "medium"
        "high":
            profile["resolution_scale"] = 1.0
            profile["shadows"] = "high"
            profile["anti_aliasing"] = "msaa4"
            profile["effects"] = "high"
            profile["texture_quality"] = "high"
        "ultra":
            profile["resolution_scale"] = 1.0
            profile["shadows"] = "high"
            profile["anti_aliasing"] = "msaa8"
            profile["effects"] = "high"
            profile["texture_quality"] = "high"
        _:
            return

    profile["graphics_quality"] = preset
    apply_performance_settings()
    save_profile()


func _apply_scene_graphics() -> void:
    var scene := get_tree().current_scene
    if scene != null:
        _apply_graphics_to_node(scene)


func _apply_graphics_to_node(node: Node) -> void:
    var shadow_mode := str(profile.get("shadows", "high"))
    var effects_mode := str(profile.get("effects", "medium"))
    var texture_mode := str(profile.get("texture_quality", "high"))
    var graphics_quality := str(profile.get("graphics_quality", "medium"))

    if node is Light3D:
        node.shadow_enabled = shadow_mode != "off"
        if node is DirectionalLight3D:
            node.directional_shadow_max_distance = 45.0 if shadow_mode == "low" else (150.0 if graphics_quality == "ultra" else 100.0)

    if node is WorldEnvironment and node.environment != null:
        node.environment.glow_enabled = effects_mode != "low"
        node.environment.glow_intensity = 0.35 if effects_mode == "medium" else (0.9 if graphics_quality == "ultra" else 0.7)

    if node is GeometryInstance3D:
        _set_material_texture_quality(node.material_override, texture_mode)

    if node is MeshInstance3D and node.mesh != null:
        for i in range(node.mesh.get_surface_count()):
            var surface_material: Material = node.get_surface_override_material(i)
            if surface_material == null:
                surface_material = node.mesh.surface_get_material(i)
            _set_material_texture_quality(surface_material, texture_mode)

    for child in node.get_children():
        _apply_graphics_to_node(child)


func _set_material_texture_quality(material: Material, quality: String) -> void:
    if not material is BaseMaterial3D:
        return

    match quality:
        "low":
            material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
        "medium":
            material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
        _:
            material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC


func t(key: String) -> String:
    var entry: Array = STR.get(key, [key, key])
    return entry[1] if profile["lang"] == "ru" else entry[0]


func get_int(key: String) -> int:
    return int(profile[key])


func level() -> int:
    return 1 + int(floor(get_int("kills") / 10.0))


func load_profile() -> void:
    if not FileAccess.file_exists(PROFILE_PATH):
        return
    var f := FileAccess.open(PROFILE_PATH, FileAccess.READ)
    if f == null:
        return
    var data = JSON.parse_string(f.get_as_text())
    if data is Dictionary:
        for key in data:
            if profile.has(key):
                profile[key] = data[key]


func save_profile() -> void:
    var f := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify(profile))


func record_match(score: int, shots: int, hits: int) -> void:
    profile["matches"] = get_int("matches") + 1
    profile["kills"] = get_int("kills") + score
    profile["shots"] = get_int("shots") + shots
    profile["hits"] = get_int("hits") + hits
    profile["best_score"] = maxi(get_int("best_score"), score)
    save_profile()


func start_arena() -> void:
    get_tree().change_scene_to_file("res://scenes/maps/test_arena.tscn")


func go_menu() -> void:
    get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
