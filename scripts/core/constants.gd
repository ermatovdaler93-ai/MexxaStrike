# res://scripts/core/constants.gd
# Единое место для имён, портов и значений проекта.
# Использование: const C = preload("res://scripts/core/constants.gd"); C.DEFAULT_PORT
class_name MexxaConst
extends RefCounted

const GAME_NAME := "MEXXA STRIKE"
const ANDROID_PACKAGE_ID := "com.mexxa.strike"

const TARGET_FPS := 60

# Сеть (используется в Фазе 7)
const DEFAULT_PORT := 7777      # игровой порт ENet (UDP)
const DISCOVERY_PORT := 47777   # порт UDP-обнаружения хостов в LAN
const MAX_PLAYERS := 10

# Версия формата сохранений профиля (Фаза 9)
const SAVE_FORMAT_VERSION := 1
