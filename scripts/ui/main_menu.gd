# res://scripts/ui/main_menu.gd
# Главное меню: 7 кнопок слева (PLAY, OFFLINE, LAN, SETTINGS, WEAPONS, PROFILE, ABOUT),
# справа — панель с содержимым выбранного раздела. Интерфейс строится кодом.
# Языки: English (основной) и Русский — переключатель в разделе SETTINGS.
extends Control

const WeaponDB = preload("res://scripts/weapons/weapon_db.gd")
const ORANGE := Color(1.0, 0.48, 0.08)
const BG := Color(0.035, 0.055, 0.085)
const CARD := Color(0.075, 0.105, 0.15)
const CARD_HOVER := Color(0.12, 0.15, 0.20)
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
    bg.color = BG
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(bg)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 22)
    add_child(margin)

    var row := HBoxContainer.new()
    row.add_theme_constant_override("separation", 22)
    margin.add_child(row)

    var left := VBoxContainer.new()
    left.custom_minimum_size = Vector2(340.0, 0.0)
    left.add_theme_constant_override("separation", 10)
    row.add_child(left)

    var brand := _label("MEXXA STRIKE", 46, ORANGE)
    brand.add_theme_color_override("font_shadow_color", Color(1.0, 0.35, 0.02, 0.35))
    brand.add_theme_constant_override("shadow_offset_x", 2)
    brand.add_theme_constant_override("shadow_offset_y", 2)
    left.add_child(brand)
    left.add_child(_label("NEON ORANGE EDITION", 16, Color(0.72, 0.78, 0.86)))
    for id in ITEMS:
        var b := _button(Game.t(id))
        b.pressed.connect(_on_item.bind(id))
        if id == "play":
            _style_button(b, true)
        left.add_child(b)

    var panel := PanelContainer.new()
    panel.add_theme_stylebox_override("panel", _panel_style())
    panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
    row.add_child(panel)

    var scroll := ScrollContainer.new()
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    panel.add_child(scroll)

    _content = VBoxContainer.new()
    _content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _content.add_theme_constant_override("separation", 16)
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

    _content.add_child(_label(Game.t("performance"), 26, ORANGE))

    var fps_label := _label("%s: %d" % [Game.t("fps_limit"), int(Game.profile.get("fps_limit", 60))], 24)
    _content.add_child(fps_label)

    var fps := OptionButton.new()
    fps.add_item("30 FPS", 30)
    fps.add_item("60 FPS", 60)
    fps.add_item("90 FPS", 90)
    _select_option_id(fps, int(Game.profile.get("fps_limit", 60)))
    fps.custom_minimum_size = Vector2(0.0, 54.0)
    fps.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _style_button(fps, false)
    fps.item_selected.connect(_on_fps_selected.bind(fps, fps_label))
    _content.add_child(fps)

    var quality_label := _label("%s: %s" % [Game.t("graphics_quality"), str(Game.profile.get("graphics_quality", "medium")).to_upper()], 24)
    _content.add_child(quality_label)

    var quality := OptionButton.new()
    for item in ["low", "medium", "high", "ultra"]:
        quality.add_item(item.to_upper())
    _select_option_text(quality, str(Game.profile.get("graphics_quality", "medium")).to_upper())
    quality.custom_minimum_size = Vector2(0.0, 54.0)
    quality.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _style_button(quality, false)
    quality.item_selected.connect(_on_quality_selected.bind(quality, quality_label))
    _content.add_child(quality)

    _content.add_child(_label("ADVANCED GRAPHICS", 26, ORANGE))

    _add_graphics_option("Resolution Scale", "resolution_scale", [
        ["50%", 0.5],
        ["75%", 0.75],
        ["100%", 1.0]
    ])

    _add_graphics_option("Shadows", "shadows", [
        ["OFF", "off"],
        ["LOW", "low"],
        ["HIGH", "high"]
    ])

    _add_graphics_option("Anti-Aliasing", "anti_aliasing", [
        ["OFF", "off"],
        ["MSAA 2X", "msaa2"],
        ["MSAA 4X", "msaa4"],
        ["MSAA 8X (HEAVY)", "msaa8"]
    ])

    _add_graphics_option("Effects", "effects", [
        ["LOW", "low"],
        ["MEDIUM", "medium"],
        ["HIGH", "high"]
    ])

    _add_graphics_option("Texture Filtering", "texture_quality", [
        ["LOW", "low"],
        ["MEDIUM", "medium"],
        ["HIGH", "high"]
    ])

    var show_fps := CheckButton.new()
    show_fps.text = Game.t("show_fps")
    show_fps.button_pressed = bool(Game.profile.get("show_fps", true))
    show_fps.custom_minimum_size = Vector2(0.0, 54.0)
    show_fps.add_theme_font_size_override("font_size", 24)
    show_fps.toggled.connect(_on_show_fps_toggled)
    _content.add_child(show_fps)

    var lang := _button("%s: %s" % [Game.t("language"), "RU" if Game.profile["lang"] == "ru" else "EN"])
    lang.pressed.connect(_on_language)
    _content.add_child(lang)


func _add_graphics_option(title: String, key: String, choices: Array) -> void:
    var current_value = Game.profile.get(key, choices[0][1])
    var selected_text := str(choices[0][0])

    var label := _label("%s: %s" % [title, selected_text], 22)
    _content.add_child(label)

    var option := OptionButton.new()
    option.custom_minimum_size = Vector2(0.0, 54.0)
    option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    _style_button(option, false)

    var selected_index := 0
    for i in range(choices.size()):
        var choice = choices[i]
        option.add_item(str(choice[0]))
        option.set_item_metadata(i, choice[1])
        if choice[1] == current_value:
            selected_index = i
            selected_text = str(choice[0])

    option.select(selected_index)
    label.text = "%s: %s" % [title, selected_text]
    option.item_selected.connect(_on_graphics_option_selected.bind(option, key, label, title))
    _content.add_child(option)


func _on_graphics_option_selected(index: int, option: OptionButton, key: String, label: Label, title: String) -> void:
    Game.profile[key] = option.get_item_metadata(index)
    Game.apply_performance_settings()
    Game.save_profile()
    label.text = "%s: %s" % [title, option.get_item_text(index)]


func _select_option_id(option: OptionButton, wanted: int) -> void:
    for i in range(option.item_count):
        if option.get_item_id(i) == wanted:
            option.select(i)
            return


func _select_option_text(option: OptionButton, wanted: String) -> void:
    for i in range(option.item_count):
        if option.get_item_text(i) == wanted:
            option.select(i)
            return


func _on_fps_selected(index: int, option: OptionButton, label: Label) -> void:
    var fps_value := option.get_item_id(index)
    Game.profile["fps_limit"] = fps_value
    Game.apply_performance_settings()
    Game.save_profile()
    label.text = "%s: %d" % [Game.t("fps_limit"), fps_value]


func _on_quality_selected(index: int, option: OptionButton, label: Label) -> void:
    var quality := option.get_item_text(index).to_lower()
    Game.apply_graphics_preset(quality)
    label.text = "%s: %s" % [Game.t("graphics_quality"), quality.to_upper()]
    call_deferred("_show_panel", "settings")


func _on_show_fps_toggled(enabled: bool) -> void:
    Game.profile["show_fps"] = enabled
    Game.save_profile()


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
    b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    b.add_theme_font_size_override("font_size", 24)
    _style_button(b, false)
    return b


func _panel_style() -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = CARD
    style.border_color = Color(1.0, 0.48, 0.08, 0.8)
    style.set_border_width_all(2)
    style.set_corner_radius_all(18)
    style.content_margin_left = 24.0
    style.content_margin_right = 24.0
    style.content_margin_top = 22.0
    style.content_margin_bottom = 22.0
    return style


func _style_button(button: Button, primary: bool) -> void:
    var normal := StyleBoxFlat.new()
    normal.bg_color = ORANGE if primary else CARD
    normal.border_color = ORANGE
    normal.set_border_width_all(2 if primary else 1)
    normal.set_corner_radius_all(12)
    normal.content_margin_left = 16.0
    normal.content_margin_right = 16.0
    normal.content_margin_top = 10.0
    normal.content_margin_bottom = 10.0

    var hover := normal.duplicate() as StyleBoxFlat
    hover.bg_color = Color(1.0, 0.60, 0.18) if primary else CARD_HOVER
    var pressed := normal.duplicate() as StyleBoxFlat
    pressed.bg_color = Color(0.82, 0.32, 0.02) if primary else Color(0.12, 0.18, 0.25)
    var disabled := normal.duplicate() as StyleBoxFlat
    disabled.bg_color = Color(0.12, 0.14, 0.17)

    button.add_theme_stylebox_override("normal", normal)
    button.add_theme_stylebox_override("hover", hover)
    button.add_theme_stylebox_override("pressed", pressed)
    button.add_theme_stylebox_override("disabled", disabled)
    button.add_theme_color_override("font_color", Color(0.06, 0.07, 0.09) if primary else Color.WHITE)
    button.add_theme_color_override("font_hover_color", Color(0.04, 0.05, 0.07) if primary else ORANGE)
    button.add_theme_color_override("font_pressed_color", Color.WHITE)
