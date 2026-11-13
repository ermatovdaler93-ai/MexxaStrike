# res://scripts/ui/main_menu.gd
# Главное меню: 7 кнопок слева (PLAY, OFFLINE, LAN, SETTINGS, WEAPONS, PROFILE, ABOUT),
# справа — панель с содержимым выбранного раздела. Интерфейс строится кодом.
# Языки: English (основной) и Русский — переключатель в разделе SETTINGS.
extends Control

const WeaponDB = preload("res://scripts/weapons/weapon_db.gd")
const ORANGE := Color(1.0, 0.55, 0.1)
const ITEMS := ["play", "offline", "lan", "settings", "weapons", "profile", "about"]

var _content: VBoxContainer
var _current := "offline"


func _ready() -> void:
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build()
    _show_panel(_current)


func _notification(what: int) -> void:
    # Кнопка «Назад» на Android в главном меню закрывает игру
    if what == NOTIFICATION_WM_GO_BACK_REQUEST:
        get_tree().quit()


func _build() -> void:
    for c in get_children():
        remove_child(c)
        c.queue_free()

    var bg := ColorRect.new()
    bg.color = Color(0.04, 0.05, 0.08)
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 28)
    add_child(margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 28)
    margin.add_child(row)

    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(380.0, 0.0)
    left.add_theme_constant_override("separation", 8)
    row.add_child(left)

    left.add_child(_label("MEXXA STRIKE", 54, ORANGE))
    for id in ITEMS:
        var b := _button(Game.t(id))
        b.pressed.connect(_on_item.bind(id))
        left.add_child(b)

    var panel := PanelContainer.new()
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_child(panel)

    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    panel.add_child(scroll)

    _content = VBoxContainer.new()
    _content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _content.add_theme_constant_override("separation", 14)
    scroll.add_child(_content)


func _on_item(id: String) -> void:
    if id == "play":
        Game.start_arena()
        return
    _show_panel(id)


func _show_panel(id: String) -> void:
    _current = id
    for c in _content.get_children():
        _content.remove_child(c)
        c.queue_free()
    match id:
        "offline":
            _panel_offline()
        "lan":
            _content.add_child(_label(Game.t("lan"), 40, ORANGE))
            _content.add_child(_label(Game.t("lan_desc"), 26))
        "settings":
            _panel_settings()
        "weapons":
            _panel_weapons()
        "profile":
            _panel_profile()
        "about":
            _content.add_child(_label(Game.t("about"), 40, ORANGE))
            _content.add_child(_label(Game.t("about_text"), 26))


# ---------------------------------------------------------------- панели

func _panel_offline() -> void:
    _content.add_child(_label(Game.t("offline"), 40, ORANGE))
    _content.add_child(_label(Game.t("offline_desc"), 26))
    var value := _label("%s: %d" % [Game.t("targets"), Game.target_count], 28)
    _content.add_child(value)
    var slider := HSlider.new()
    slider.min_value = 3
    slider.max_value = 10
    slider.step = 1
    slider.value = Game.target_count
    slider.custom_minimum_size = Vector2(0.0, 50.0)
    slider.value_changed.connect(_on_targets_changed.bind(value))
    _content.add_child(slider)
    var start := _button(Game.t("start"))
    start.pressed.connect(Game.start_arena)
    _content.add_child(start)


func _on_targets_changed(v: float, label: Label) -> void:
    Game.target_count = int(v)
    label.text = "%s: %d" % [Game.t("targets"), Game.target_count]


func _panel_settings() -> void:
    _content.add_child(_label(Game.t("settings"), 40, ORANGE))
    var sens := float(Game.profile["sensitivity"])
    var value := _label("%s: %.2f" % [Game.t("sensitivity"), sens], 28)
    _content.add_child(value)
    var slider := HSlider.new()
    slider.min_value = 0.3
    slider.max_value = 2.5
    slider.step = 0.05
    slider.value = sens
    slider.custom_minimum_size = Vector2(0.0, 50.0)
    slider.value_changed.connect(_on_sens_changed.bind(value))
    _content.add_child(slider)

    var lang := _button("%s: %s" % [Game.t("language"), "RU" if Game.profile["lang"] == "ru" else "EN"])
    lang.pressed.connect(_on_language)
    _content.add_child(lang)


func _on_sens_changed(v: float, label: Label) -> void:
    Game.profile["sensitivity"] = v
    label.text = "%s: %.2f" % [Game.t("sensitivity"), v]
    Game.save_profile()


func _on_language() -> void:
    Game.profile["lang"] = "en" if Game.profile["lang"] == "ru" else "ru"
    Game.save_profile()
    _build()
    _show_panel(_current)


func _panel_weapons() -> void:
    _content.add_child(_label(Game.t("weapons"), 40, ORANGE))
    for w in WeaponDB.all():
        var rpm := int(round(60.0 / w.fire_interval))
        var pellets := "" if w.pellets == 1 else " x%d" % w.pellets
        var text := "%s - %s\n%s %d%s | %s %d rpm | %s %d | %s %.1f s" % [
            w.display_name, w.category,
            Game.t("dmg"), int(w.damage), pellets,
            Game.t("rate"), rpm,
            Game.t("mag"), w.magazine_size,
            Game.t("reload"), w.reload_time]
        _content.add_child(_label(text, 24))


func _panel_profile() -> void:
    _content.add_child(_label(Game.t("profile"), 40, ORANGE))
    _content.add_child(_label(Game.t("nickname"), 26))
    var edit := LineEdit.new()
    edit.text = str(Game.profile["nickname"])
    edit.max_length = 16
    edit.custom_minimum_size = Vector2(0.0, 56.0)
    edit.add_theme_font_size_override("font_size", 28)
    edit.text_submitted.connect(_on_nick_submitted)
    edit.focus_exited.connect(_on_nick_focus_lost.bind(edit))
    _content.add_child(edit)

    var shots := Game.get_int("shots")
    var acc := 0.0
    if shots > 0:
        acc = 100.0 * Game.get_int("hits") / shots
    _content.add_child(_label("%s: %d" % [Game.t("level"), Game.level()], 28))
    _content.add_child(_label("%s: %d" % [Game.t("kills"), Game.get_int("kills")], 28))
    _content.add_child(_label("%s: %.0f%%" % [Game.t("accuracy"), acc], 28))
    _content.add_child(_label("%s: %d" % [Game.t("matches"), Game.get_int("matches")], 28))
    _content.add_child(_label("%s: %d" % [Game.t("best"), Game.get_int("best_score")], 28))


func _on_nick_submitted(text: String) -> void:
    _save_nick(text)


func _on_nick_focus_lost(edit: LineEdit) -> void:
    _save_nick(edit.text)


func _save_nick(text: String) -> void:
    var clean := text.strip_edges()
    if clean == "":
        clean = "Player"
    Game.profile["nickname"] = clean
    Game.save_profile()


# ---------------------------------------------------------------- помощники UI

func _label(text: String, font_size: int, color: Color = Color.WHITE) -> Label:
    var l := Label.new()
    l.text = text
    l.add_theme_font_size_override("font_size", font_size)
    l.add_theme_color_override("font_color", color)
    l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    return l


func _button(text: String) -> Button:
    var b := Button.new()
    b.text = text
    b.custom_minimum_size = Vector2(0.0, 62.0)
    b.add_theme_font_size_override("font_size", 28)
    return b
