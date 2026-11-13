# MEXXA STRIKE (Godot 4.3) — Фаза 1

Цель Фазы 1: убедиться, что цепочка **Termux → GitHub → APK → телефон** работает, прежде чем
писать игру. Внутри: проект Godot, экспорт для Android (ARM64), тестовый экран и облачная сборка.

## Как собрать APK (всё с телефона)
1. Создайте на github.com **пустой** репозиторий `MexxaStrike` (без README): https://github.com/new
2. Создайте токен: https://github.com/settings/tokens/new?scopes=repo,workflow&description=termux
   (токен вставляйте только в Termux на запрос Password, никому его не показывайте).
3. Termux:
```
cd ~ && unzip -o ~/storage/downloads/MexxaStrike_Phase1_Godot.zip
cd ~/MexxaStrikeGodot
git init -b main
git add .
git -c user.name=me -c user.email=me@example.com commit -m "phase 1"
git remote add origin https://github.com/ВАШ_ЛОГИН/MexxaStrike.git
git push -u origin main
```
4. GitHub → репозиторий → вкладка **Actions** → «Build APK» (если не стартовала: Run workflow).
5. После зелёной галочки внизу запуска, в **Artifacts**, скачайте `MexxaStrike-apk`, распакуйте и установите APK.

## Критерии приёмки Фазы 1
- Сборка в Actions зелёная.
- APK устанавливается на Android 10+ (ARM64).
- Экран горизонтальный: название MEXXA STRIKE, версия Godot, модель телефона, GPU, FPS ≈ 60.
- При касании несколькими пальцами счётчик Touches показывает 2, 3, … (мультитач работает).

## Если сборка красная
Откройте красный шаг и пришлите последние 30-40 строк лога. Вероятные места: «Export debug APK»
(пути к Android SDK/ключу) и «Install Godot» (адрес скачивания).
