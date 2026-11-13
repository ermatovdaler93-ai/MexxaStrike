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
