class_name RuntimeWorkloadExperimentUI
extends CanvasLayer

signal run_requested
signal stop_requested
signal export_requested

var _body: VBoxContainer
var _title: Label
var _setup: Label
var _status: Label
var _progress: ProgressBar
var _run_button: Button
var _stop_button: Button
var _export_button: Button
var _results: Label
var _details: Label
var _details_button: Button


func configure(title: String, setup_text: String, mode_labels: Array[String], mode_descriptions: Array[String]) -> void:
	_build(title, setup_text, mode_labels, mode_descriptions)
	get_viewport().size_changed.connect(_update_responsive_layout)
	_update_responsive_layout()


func set_ready(message: String = "Ready to run 12 automated measurements.") -> void:
	_status.text = message
	_progress.value = 0
	_run_button.disabled = false
	_stop_button.disabled = true
	_export_button.disabled = true


func set_running(completed: int, total: int, mode_label: String, repetition: int, live_text: String) -> void:
	_progress.max_value = total
	_progress.value = completed
	_status.text = "%d / %d runs  •  %s  •  Run %d/3\n%s" % [completed, total, mode_label, repetition, live_text]
	_run_button.disabled = true
	_stop_button.disabled = false
	_export_button.disabled = true


func set_complete(completed: int, total: int, success: bool, message: String) -> void:
	_progress.max_value = total
	_progress.value = completed
	_status.text = ("Experiment Complete!  %d / %d runs completed" % [completed, total]) if success else message
	_run_button.disabled = false
	_stop_button.disabled = true
	_export_button.disabled = not success


func set_results(summary: String, details: String) -> void:
	_results.text = summary
	_details.text = details


func _build(title_text: String, setup_text: String, mode_labels: Array[String], mode_descriptions: Array[String]) -> void:
	layer = 20
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	margin.add_child(scroll)

	var outer := PanelContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_theme_stylebox_override("panel", _style(Color("07121c"), Color("40566a"), 18))
	scroll.add_child(outer)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 16)
	outer_margin.add_theme_constant_override("margin_top", 14)
	outer_margin.add_theme_constant_override("margin_right", 16)
	outer_margin.add_theme_constant_override("margin_bottom", 16)
	outer.add_child(outer_margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	outer_margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	_title = Label.new()
	_title.text = title_text
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 25)
	header.add_child(_title)
	var collapse := Button.new()
	collapse.text = "▴"
	collapse.custom_minimum_size = Vector2(52, 48)
	header.add_child(collapse)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 12)
	root.add_child(_body)
	collapse.pressed.connect(func() -> void:
		_body.visible = not _body.visible
		collapse.text = "▴" if _body.visible else "▾"
	)

	var setup_card := _card()
	var setup_box := _card_box(setup_card)
	setup_box.add_child(_section("EXPERIMENT SETUP"))
	_setup = Label.new()
	_setup.text = setup_text
	_setup.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_setup.add_theme_font_size_override("font_size", 17)
	setup_box.add_child(_setup)
	_body.add_child(setup_card)

	var modes_card := _card()
	var modes_box := _card_box(modes_card)
	modes_box.add_child(_section("WORKLOAD MODES"))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for index in mode_labels.size():
		var mode_card := PanelContainer.new()
		mode_card.add_theme_stylebox_override("panel", _style(Color("0a1b29"), _mode_color(index), 10))
		var mode_margin := MarginContainer.new()
		mode_margin.add_theme_constant_override("margin_left", 10)
		mode_margin.add_theme_constant_override("margin_top", 9)
		mode_margin.add_theme_constant_override("margin_right", 10)
		mode_margin.add_theme_constant_override("margin_bottom", 9)
		mode_card.add_child(mode_margin)
		var mode_box := VBoxContainer.new()
		mode_margin.add_child(mode_box)
		var heading := Label.new()
		heading.text = "%s  %s" % [String.chr(65 + index), mode_labels[index]]
		heading.add_theme_color_override("font_color", _mode_color(index))
		heading.add_theme_font_size_override("font_size", 17)
		heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mode_box.add_child(heading)
		var description := Label.new()
		description.text = mode_descriptions[index]
		description.add_theme_font_size_override("font_size", 15)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mode_box.add_child(description)
		grid.add_child(mode_card)
	modes_box.add_child(grid)
	_body.add_child(modes_card)

	var run_card := _card()
	var run_box := _card_box(run_card)
	run_box.add_child(_section("RUN EXPERIMENT"))
	_run_button = Button.new()
	_run_button.text = "▶  Run Experiment"
	_run_button.custom_minimum_size = Vector2(0, 56)
	_run_button.add_theme_font_size_override("font_size", 19)
	_run_button.pressed.connect(func() -> void: run_requested.emit())
	run_box.add_child(_run_button)
	_progress = ProgressBar.new()
	_progress.max_value = 12
	_progress.show_percentage = false
	_progress.custom_minimum_size = Vector2(0, 18)
	run_box.add_child(_progress)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.add_theme_font_size_override("font_size", 17)
	run_box.add_child(_status)
	_stop_button = Button.new()
	_stop_button.text = "■  Stop Experiment"
	_stop_button.custom_minimum_size = Vector2(0, 50)
	_stop_button.pressed.connect(func() -> void: stop_requested.emit())
	run_box.add_child(_stop_button)
	_body.add_child(run_card)

	var results_card := _card()
	var results_box := _card_box(results_card)
	results_box.add_child(_section("RESULTS SUMMARY"))
	_results = Label.new()
	_results.text = "Results will appear after runs complete."
	_results.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_results.add_theme_font_size_override("font_size", 17)
	results_box.add_child(_results)
	_export_button = Button.new()
	_export_button.text = "⇩  Export Evidence (JSON)"
	_export_button.custom_minimum_size = Vector2(0, 54)
	_export_button.pressed.connect(func() -> void: export_requested.emit())
	results_box.add_child(_export_button)
	_details_button = Button.new()
	_details_button.text = "Experiment Details & Logs  ▾"
	results_box.add_child(_details_button)
	_details = Label.new()
	_details.visible = false
	_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_details.add_theme_font_size_override("font_size", 15)
	results_box.add_child(_details)
	_details_button.pressed.connect(func() -> void:
		_details.visible = not _details.visible
		_details_button.text = "Experiment Details & Logs  ▴" if _details.visible else "Experiment Details & Logs  ▾"
	)
	_body.add_child(results_card)


func _card() -> PanelContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", _style(Color("061019"), Color("31465a"), 12))
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)
	return card


func _card_box(card: PanelContainer) -> VBoxContainer:
	return card.get_child(0).get_child(0) as VBoxContainer


func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 17)
	label.add_theme_color_override("font_color", Color("69a7ff"))
	return label


func _style(background: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(background, 0.94)
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(radius)
	return style


func _mode_color(index: int) -> Color:
	match index:
		0: return Color("5dde72")
		1: return Color("f1c232")
		2: return Color("49a9ef")
		_: return Color("9d6cff")


func _update_responsive_layout() -> void:
	if _title == null:
		return
	var width := get_viewport().get_visible_rect().size.x
	_title.add_theme_font_size_override("font_size", 22 if width < 700.0 else 28)
