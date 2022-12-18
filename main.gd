extends Node

signal selected()

@onready var _texture_rect: TextureRect = get_node("%TextureRect")
@onready var _num_to_dir_label: RichTextLabel = get_node("%NumToDir")
@onready var _selected_dir_label: Label = get_node("%SelectedDir")
@onready var _num_separate_dir: SpinBox = get_node("%NumSeparate")
@onready var _num_remain_label: Label = get_node("%NumRemain")
@onready var _num_max_label: Label = get_node("%NumMax")
@onready var _dialog_container: VBoxContainer = get_node("%DialogContainer")
@onready var _progress_bar: ProgressBar = get_node("%ProgressBar")
@onready var _directory: LineEdit = get_node("%Directory")
@onready var _extension: OptionButton = get_node("%Extensions")
@onready var _start_find_button: Button = get_node("%StartFind")
@onready var _reset_result_button: Button = get_node("%ResetResult")
@onready var _start_sorting_button: Button = get_node("%StartSorting")
@onready var _scroll_container: ScrollContainer = $Panel/GridContainer/Display/Panel/VBoxContainer/PanelContainer/ScrollContainer
@onready var _select_directory_button: Button = get_node("%SelectDirectory")
@onready var _image_window: Window = $Window

var _img_paths: Array[String] = []
var _num_separate := 7
var _num_to_dir := -1
var _dir_path = null
var _pressed_correctly := false
var _is_sort_started := false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.keycode:
			KEY_1:
				_pressed_correctly = _num_separate >= 1
				if _pressed_correctly:
					_num_to_dir = 1
				
			KEY_2:
				_pressed_correctly = _num_separate >= 2
				if _pressed_correctly:
					_num_to_dir = 2
				
			KEY_3:
				_pressed_correctly = _num_separate >= 3
				if _pressed_correctly:
					_num_to_dir = 3
				
			KEY_4:
				_pressed_correctly = _num_separate >= 4
				if _pressed_correctly:
					_num_to_dir = 4
				
			KEY_5:
				_pressed_correctly = _num_separate >= 5
				if _pressed_correctly:
					_num_to_dir = 5
				
			KEY_6:
				_pressed_correctly = _num_separate >= 6
				if _pressed_correctly:
					_num_to_dir = 6
				
			KEY_7:
				_pressed_correctly = _num_separate >= 7
				if _pressed_correctly:
					_num_to_dir = 7
			
			KEY_8:
				_pressed_correctly = _num_separate >= 8
				if _pressed_correctly:
					_num_to_dir = 8
			
			KEY_9:
				_pressed_correctly = _num_separate >= 9
				if _pressed_correctly:
					_num_to_dir = 9
			
			# 確定されたら
			KEY_ENTER:
				if _pressed_correctly:
					selected.emit()
					_pressed_correctly = false
			# それ以外
			_:
				_pressed_correctly = false
				_num_to_dir = -1
		
		
		if _num_to_dir > 0 and _pressed_correctly and _is_sort_started:
			_num_to_dir_label.text = "[color=yellow]" + str(_num_to_dir) + "[/color]"
			_num_to_dir_label.text += "  enter(return)キーを押して確定"
		elif _is_sort_started:
			_num_to_dir_label.text = "[color=red]数字キーを押してください[/color]"
		else:
			_num_to_dir_label.text = "[color=red]振り分けを開始してください[/color]"


# 指定の拡張子のパスを見つける
func find_all_at_path(dir_path: String, extension: String, ignore_directories=[], recursive: bool=true, ) -> Array:
	var found_files := []
	var dir_queue := [dir_path]
	var dir: DirAccess

	var file: String
	while (not file.is_empty()) or (not dir_queue.is_empty()):
		if file:
			if dir.current_is_dir() and recursive and not ignore_directories.has(file):
				dir_queue.append("%s/%s" % [dir.get_current_dir(), file])
			elif file.ends_with(extension):
				found_files.append("%s/%s.%s" % [dir.get_current_dir(), file.get_basename(), file.get_extension()])
		else:
			if dir:
				dir.list_dir_end()

			if dir_queue.is_empty():
				break

			# Open next dir.
			dir = DirAccess.open(dir_queue.pop_front())
			if dir:
				dir.list_dir_begin()
		file = dir.get_next() if dir else ""
	return found_files


# dialog_boxにメッセージを追加する
func _add_message(message: String, bbcode_enabled=false):
	var label = RichTextLabel.new()
	label.fit_content_height = true
	label.bbcode_enabled = bbcode_enabled
	label.text = message
	_dialog_container.add_child(label)
	await get_tree().process_frame
	_scroll_container.call_deferred("ensure_control_visible", label)
	
	# 増え過ぎたら消す
	if _scroll_container.get_child_count() > 1024 * 4:
		_scroll_container.get_child(0).queue_free()


# 外部のディレクトリからテクスチャを取得する
func load_external_texture(path: String) -> ImageTexture:
	var image = Image.new()
	image.load(path)
	var texture = ImageTexture.create_from_image(image)
	return texture


# プロパティの表示を変更する
func enable_set_find_property(enable: bool=true):
	_extension.visible = enable
	var extension_lock = get_node("%ExtensionLock")
	extension_lock.visible = !enable
	extension_lock.text = _extension.text
	
	_num_separate_dir.visible = enable
	var num_separate_lock = get_node("%NumSeparateLock")
	num_separate_lock.visible = !enable
	num_separate_lock.text = _num_separate_dir.text
	
	_start_find_button.disabled = !enable
	_reset_result_button.disabled = enable


# プロパティリストの表示を更新する
func _update_property_list():
	_num_max_label.text = str(_img_paths.size())
	_num_remain_label.text = str(_img_paths.size())


# ディレクトリを指定した時に呼び出される
func _on_FileDialog_dir_selected(dir: String):
	_dir_path = dir
	_selected_dir_label.text = dir
	_directory.text = dir


# ディレクトリ検索ボタンが押されたら
func _on_select_directory_pressed() -> void:
	$FileDialog.popup()


# 振り分け開始ボタンが押されたら
func _on_start_sorting_pressed() -> void:
	_is_sort_started = true
	_num_to_dir_label.text = "[color=red]数字キーを押してください[/color]"
	_num_max_label.text = str(_img_paths.size())
	_num_remain_label.text = str(_img_paths.size())
	get_viewport().gui_release_focus()
	_start_sorting_button.disabled = true
	_select_directory_button.disabled = true
	
	var num_dir := roundi(_num_separate_dir.value)
	var dir := DirAccess.open(_dir_path)
	
	# 振り分け先のディレクトリを作成する
	for i in range(1, num_dir + 1):
		if dir.make_dir(str(i)) == OK:
			_add_message("Created directory %s" % dir.get_current_dir() + "/" + str(i))
		else: 
			_add_message("[color=red]Failed creating directory[/color] %s" % dir.get_current_dir() + "/" + str(i), true)
	
	var size = _img_paths.size()
	
	# ソート作業開始
	while(true):
		var img_path = _img_paths.pop_back()
		if img_path != null:
			var texture = load_external_texture(img_path)
			_add_message("[color=yellow]Sorting:[/color] %s" % img_path, true)
			if texture != null:
				_texture_rect.texture = texture
				# キーが押されるまで待つ
				await self.selected
				_texture_rect.texture = null
				var target_dir = dir.get_current_dir() + "/" + str(_num_to_dir) + "/" + img_path.get_file()
				# コピーに成功したら
				img_path
				if DirAccess.copy_absolute(img_path, target_dir) == OK:
					_add_message(
						"[color=green]Copied:[/color] %s/[color=green]%s[/color]" % [target_dir.get_base_dir(), img_path.get_file()], true)
					# 元のファイルを削除する
					if DirAccess.remove_absolute(img_path) == OK:
						_add_message("[color=red]Removed:[/color] %s[color=red][s]/%s[/s][/color]" % [img_path.get_base_dir(), img_path.get_file()], true)
				# 失敗したら
				else:
					_add_message("[color=red]Failed to copy:[/color] %s%s" % [img_path, target_dir], true)
			_num_remain_label.text = str(_img_paths.size())
			_progress_bar.ratio = float(size - _img_paths.size()) / size
		else:
			break
		
	_start_sorting_button.disabled = false
	_select_directory_button.disabled = false


# 分割数入力フォームに入力されてenterが押されたら
func _on_num_separate_text_submitted(new_text: String) -> void:
	get_viewport().gui_release_focus()
	var num_separate = get_node_or_null("%NumSeparate") as LineEdit
	if new_text.is_valid_int():
		var num = new_text.to_int()
		if num > 0 and num < 10:
			_num_separate = num
			return
	num_separate.text = "7"


# ディレクトリ入力フォームに入力されてenterが押されたら
func _on_directory_edit_text_submitted(new_text: String) -> void:
	_dir_path = new_text
	get_viewport().gui_release_focus()


# 検索開始ボタンが押されたら
func _on_start_find_pressed() -> void:
	var extension = _extension.text
	_dir_path = _directory.text
	# 指定したファイル検索で無視するディレクトリを指定する
	var dir_ignore = []
	for i in range(_num_separate):
		dir_ignore.append(str(i))
	
	if _img_paths.is_empty():
		# 特定の拡張子がついたファイルを検索する
		_img_paths = find_all_at_path(_dir_path, extension, dir_ignore)
		if not _img_paths.is_empty():
			_start_sorting_button.disabled = false
		
		# 検索結果が1件でもあれば
		if not _img_paths.is_empty():
			_add_message("[color=yellow]検索結果: %d (対象: %s)\n at: %s[/color]" % [_img_paths.size(), extension, _dir_path], true)
			enable_set_find_property(false)
		# 1つもなかったら
		else:
			_add_message("検索結果: 0 (対象: %s)\n at: %s" % [extension, _dir_path])
		# プロパティのリストを更新する
		_update_property_list()
		get_viewport().gui_release_focus()
	# (本来は呼ばれないはず)
	# 振り分けるためのファイルが残っていたら
	else:
		_add_message("[color=red]振り分けが残っています (残り: %d)[/color]" % _img_paths.size(), true)


# 画像が表示されているウィンドウの大きさが変更されたときn
func _on_window_size_changed() -> void:
	if _texture_rect:
		_texture_rect.size = _image_window.size


# ウィンドウの位置を戻すボタンが押されたら
func _on_return_image_window_pressed() -> void:
	_image_window.position = Vector2i(30, 340)
	_image_window.size = Vector2i(580, 600)
	_image_window.popup()


# リセットボタンが押されたら
func _on_reset_result_pressed() -> void:
	_reset_result_button.disabled = true
	_start_find_button.disabled = false
	_img_paths.clear()
	_update_property_list()
	enable_set_find_property(true)
	_start_sorting_button.disabled = true


# 分割する数が変更されたら
func _on_num_separate_box_value_changed(value: float) -> void:
	get_viewport().gui_release_focus()
	var num_separate = get_node_or_null("%NumSeparate") as LineEdit
	var num = roundf(value)
	if num > 0 and num < 10:
		_num_separate = num
