# res://scripts/weapons/weapon_data.gd
# Данные оружия (аналог ScriptableObject из Unity — здесь это Resource).
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export var category: String = ""
@export var damage: float = 20.0
@export var fire_interval: float = 0.1     # секунды между выстрелами
@export var magazine_size: int = 30
@export var reload_time: float = 2.0
@export var spread_deg: float = 1.0        # разброс (градусы)
@export var pellets: int = 1               # дробинок за выстрел (дробовик > 1)
@export var automatic: bool = true
@export var max_range: float = 100.0
@export var recoil_deg: float = 1.0        # подброс камеры за выстрел
@export var color: Color = Color(0.8, 0.8, 0.8)
