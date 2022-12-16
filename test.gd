extends Node

signal selected()

var pressed_correctly := false
var imgs = []
var current_path = null
var dir_path = null

# Called when the node enters the scene tree for the first time.
func _ready():
	$FileDialog.popup()
	$HBoxContainer/number.text = "None"


func _process(delta: float):
	pass


func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.is_pressed():
		var num_label = $HBoxContainer/number
		match event.scancode:
			KEY_1:
				num_label.text = "1"
				pressed_correctly = true
			KEY_2:
				num_label.text = "2"
				pressed_correctly = true
			KEY_3:
				num_label.text = "3"
				pressed_correctly = true
			KEY_4:
				num_label.text = "4"
				pressed_correctly = true
			KEY_5:
				num_label.text = "5"
				pressed_correctly = true
			KEY_6:
				num_label.text = "6"
				pressed_correctly = true
			KEY_7:
				num_label.text = "7"
				pressed_correctly = true
			KEY_ENTER:
				# 確定されたら
				if pressed_correctly:
					emit_signal("selected")
					pressed_correctly = false
					num_label.text = "None"
			_:
				num_label.text = "None"
				pressed_correctly = false
				print("Wrong key!!")


func find_all_at_path(dir_path: String, recursive: bool = true) -> Array:
	var found_files := [];
	var dir_queue := [dir_path];
	var dir: Directory;

	var file: String;
	while file or not dir_queue.empty():
		if file:
			if dir.current_is_dir() and recursive:
				dir_queue.append("%s/%s" % [dir.get_current_dir(), file]);
			elif file.ends_with(".JPG"):
				found_files.append("%s/%s.%s" % [dir.get_current_dir(), file.get_basename(), file.get_extension()]);
		else:
			if dir:
				dir.list_dir_end();

			if dir_queue.empty():
				break;

			# Open next dir.
			dir = Directory.new();
			dir.open(dir_queue.pop_front());
			dir.list_dir_begin(true, true);
		file = dir.get_next();

	return found_files;


func move_(texture: Image, to_dir: String):
	var dir = Directory.new()
	dir.change_dir(to_dir)
	for i in range(1, 8):
		dir.make_dir(str(i))



func _on_CenterContainer_mouse_entered():
	pass # Replace with function body.


func _on_FileDialog_dir_selected(dir: String):
	# ディレクトリを指定した時
	dir_path = dir
	var paths = find_all_at_path(dir_path)
	for p in paths:
		var image = Image.new()
		image.load(p)
		var texture = ImageTexture.new()
		texture.create_from_image(image)
		imgs.append(texture)
		$Panel/CenterContainer/TextureRect.texture = texture
		yield(self, "selected")
