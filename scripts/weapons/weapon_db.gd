# res://scripts/weapons/weapon_db.gd
# Список оружия MEXXA STRIKE (аркадные характеристики, всё вымышленное).
extends RefCounted

const WD = preload("res://scripts/weapons/weapon_data.gd")


static func all() -> Array:
    var list: Array = []
    list.append(_make("mx47", "MX-47", "Assault rifle", 22.0, 0.11, 30, 2.1, 1.2, 1, true, 120.0, 0.8, Color(0.95, 0.5, 0.1)))
    list.append(_make("mx90", "MX-90", "SMG", 14.0, 0.07, 35, 1.8, 2.2, 1, true, 70.0, 0.5, Color(0.2, 0.8, 0.9)))
    list.append(_make("mxr4", "MX-R4", "Sniper rifle", 90.0, 1.1, 5, 2.8, 0.05, 1, false, 250.0, 3.0, Color(0.6, 0.4, 0.9)))
    list.append(_make("mxeagle", "MX-Eagle", "Pistol", 34.0, 0.28, 12, 1.5, 0.8, 1, false, 80.0, 1.6, Color(0.85, 0.85, 0.9)))
    list.append(_make("mx12", "MX-12", "Shotgun", 11.0, 0.9, 6, 2.6, 4.5, 8, false, 40.0, 3.0, Color(0.9, 0.25, 0.25)))
    return list


static func _make(id: String, display_name: String, category: String, damage: float,
        interval: float, mag: int, reload_time: float, spread: float, pellets: int,
        automatic: bool, max_range: float, recoil: float, color: Color):
    var w = WD.new()
    w.id = id
    w.display_name = display_name
    w.category = category
    w.damage = damage
    w.fire_interval = interval
    w.magazine_size = mag
    w.reload_time = reload_time
    w.spread_deg = spread
    w.pellets = pellets
    w.automatic = automatic
    w.max_range = max_range
    w.recoil_deg = recoil
    w.color = color
    return w
