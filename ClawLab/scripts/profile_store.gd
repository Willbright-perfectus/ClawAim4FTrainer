extends Node

const Schema = preload("res://scripts/config_schema.gd")
const PATH = "user://profiles.json"
var data = Schema.defaults()
var slots: Dictionary = {}
var history: Array = []
var status_message = ""

func _ready() -> void:
	load_store()
	apply_performance()

func load_store() -> void:
	slots.clear()
	history.clear()
	for path in [PATH, PATH + ".bak"]:
		if not FileAccess.file_exists(path):
			continue
		var parser = JSON.new()
		if parser.parse(FileAccess.get_file_as_string(path)) != OK:
			continue
		var raw = parser.data
		if raw is Dictionary and raw.get("active") is Dictionary:
			data = Schema.sanitize(raw.active)
			if raw.get("slots") is Dictionary:
				for key in raw.slots:
					slots[str(key).substr(0,64)] = Schema.sanitize(raw.slots[key])
			if raw.get("history") is Array:
				for item in raw.history.slice(0,100):
					if item is Dictionary:
						history.append(item)
			if path.ends_with(".bak"):
				status_message = "Recovered your settings from the backup."
			return
	if FileAccess.file_exists(PATH):
		status_message = "The settings file could not be read. Defaults were restored."

func save() -> bool:
	data = Schema.sanitize(data)
	var tmp = PATH + ".tmp"
	var f = FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		status_message = "Could not save settings. Check available storage."
		return false
	f.store_string(JSON.stringify({"version": 1, "active": data, "slots": slots, "history": history}, "\t"))
	f.flush()
	f.close()
	if FileAccess.file_exists(PATH):
		var backup_error = DirAccess.copy_absolute(PATH, PATH + ".bak")
		if backup_error != OK:
			status_message = "Could not create settings backup."
			return false
	var err = DirAccess.rename_absolute(tmp, PATH)
	if err != OK:
		status_message = "Settings could not be committed. Previous settings are safe."
		return false
	return true

func apply_performance() -> void:
	Engine.max_fps = int(data.performance.fps)
	get_viewport().scaling_3d_scale = float(data.performance.render_scale)

func save_slot(slot_name: String) -> bool:
	var clean = slot_name.strip_edges().substr(0,64)
	if clean.is_empty():
		return false
	data.profile_name = clean
	slots[clean] = data.duplicate(true)
	return save()

func export_text() -> String:
	return JSON.stringify(Schema.sanitize(data), "\t")

func import_text(content: String) -> String:
	if content.length() > 250000:
		return "Profile is too large. Maximum: 250 KB."
	var parser = JSON.new()
	if parser.parse(content) != OK:
		return "Invalid JSON: " + parser.get_error_message()
	if not parser.data is Dictionary or not parser.data.get("weapon") is Dictionary:
		return "This is not a ClawLab profile."
	if int(parser.data.get("schema_version", 0)) not in [1, Schema.VERSION]:
		return "Unsupported profile version. Use a ClawLab version 1 or 2 profile."
	data = Schema.sanitize(parser.data)
	if not save():
		return status_message
	apply_performance()
	return ""

func add_result(result: Dictionary) -> void:
	result["date"] = Time.get_datetime_string_from_system()
	result["profile"] = data.profile_name
	result["configuration"] = data.duplicate(true)
	result["signature"] = JSON.stringify(data).sha256_text().substr(0,12)
	history.push_front(result)
	if history.size() > 100:
		history.resize(100)
	save()
