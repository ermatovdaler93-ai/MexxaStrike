# MEXXA STRIKE — архитектура (Godot 4.3)

## Соответствие исходному ТЗ (Unity → Godot)
| В ТЗ (Unity) | В этом проекте (Godot) |
|---|---|
| C#, MonoBehaviour | GDScript, Node-скрипты |
| ScriptableObject | `Resource` (`WeaponData`, `MapData`, `ModeData`, файлы `.tres`) |
| Netcode for GameObjects + Unity Transport | High-level Multiplayer API: `ENetMultiplayerPeer`, `MultiplayerSpawner`, `MultiplayerSynchronizer`, RPC |
| NavMesh | `NavigationRegion3D` + `NavigationAgent3D` |
| URP, пресеты качества | Renderer Compatibility/Mobile, пресеты LOW/MEDIUM/HIGH в `settings` |
| Input System, виртуальный джойстик | `InputEventScreenTouch/Drag`, собственные Control-узлы джойстика и зоны обзора |
| JSON-профиль | `user://profile.json` с полем `version` |

## Структура проекта
```
res://
├─ project.godot, export_presets.cfg, icon.svg
├─ scripts/  core  player  weapons  bots  net  ui  maps  audio  save  settings
├─ scenes/   boot  menu  lobby  maps(mexxa_city, neon_arena, desert_base)  players  weapons  bots  ui
├─ resources/ weapons  maps  modes
└─ assets/   audio  textures  models  fonts
```
Правило зависимостей: `core` ничего не знает о верхних слоях; `ui` и `net` не вызывают друг друга
напрямую, а общаются через сигналы автозагружаемых сервисов.

## Мультиплеер (план Фазы 7)
- Хост = сервер (peer id 1) + игрок. Порт `7777` (UDP), до 10 игроков.
- **Host-authoritative:** урон, смерти, счёт, таймеры и исход раундов считает только хост;
  клиент отправляет «намерения» (ввод, выстрел) через RPC, хост их проверяет.
- Синхронизация позиции/здоровья/счёта — `MultiplayerSynchronizer`; спавн игроков — `MultiplayerSpawner`.
- Обнаружение хостов в LAN: UDP-broadcast на порту `47777` (`PacketPeerUDP`), запасной вариант —
  ввод IP вручную. Интернет и внешние серверы не нужны. Разрешения Android (`INTERNET`,
  `ACCESS_WIFI_STATE`, `CHANGE_WIFI_MULTICAST_STATE`) добавляются в export preset в Фазе 7.
- Дубликаты игроков: идентификатор выдаёт хост по peer id; повторное подключение отклоняется.

## Честные ограничения
- Модели, текстуры, анимации и звук я не рисую вручную. Карты и оружие будут собираться из
  примитивов кодом (меши, CSG, материалы), звуки — генерироваться или браться из бесплатных CC0-наборов.
  Графика получится стилизованной, но не уровня AAA.
- Я не могу запустить Godot у себя: каждую фазу проверяет сборка в Actions и ваш телефон.
  Пока вы не подтвердите успешную сборку и запуск, фаза считается непроверенной.
- Версия Godot закреплена на 4.3 (я знаю её лучше всего). Обновление до 4.7 возможно позже.
