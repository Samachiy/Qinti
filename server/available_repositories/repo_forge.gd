extends AutoWebUI_Repo

class_name Forge_Repo


func _init(path: String, repo_data: RepoData).(path, repo_data):
	pass


func prepare_files():
	yield(Python.get_tree(), "idle_frame")
	_disable_auto_launch()
