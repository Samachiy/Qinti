extends Node

 

# server_name: [repo_link, recommended_ver, all_versions_array, args, amd_args]
var servers: Dictionary = {
	# We use a new pc data since system overrides may take place
	"Automatic1111": RepoData.new(PCData.new() 
			).set_start_script_linux("webui.sh", "--api"
			).set_start_script_windows("webui.bat", "--api"
			).set_start_args_amd("--precision full --no-half"
			).set_url("https://github.com/AUTOMATIC1111/stable-diffusion-webui.git"
			).set_api(AutoWebUI_API
			).set_class(AutoWebUI_Repo
			).set_versions("v1.7.0", [
					"v1.8.0", "v1.7.0", 
					"v1.6.1", "v1.6.0", 
					"v1.5.2", "v1.5.0", 
					"v1.4x.1", "v1.4.0", 
					"v1.3.2", "v1.3.1", "v1.3.0", 
					"v1.2.1", "v1.2.0"]
			).set_readme_title("# Stable Diffusion web UI"
			).set_id("Automatic1111"
			).enable_install(true),
	"Forge": RepoData.new(PCData.new() 
			).set_start_script_linux("webui.sh", "--api"
			).set_start_script_windows("webui.bat", "--api"
			).set_start_args_amd("--precision full --no-half"
			).set_url("https://github.com/lllyasviel/stable-diffusion-webui-forge.git"
			).set_api(AutoWebUI_API
			).set_class(Forge_Repo
			).set_versions("main", []
			).set_readme_title("# Stable Diffusion WebUI Forge"
			).set_id("Forge"
			).enable_install(true),
	"SD.Next": RepoData.new(PCData.new()
			).set_start_script_linux("webui.sh", "--docs"
			).set_start_script_windows("webui.bat", "--docs"
			).set_start_args_amd("--use-rocm"
			).set_url("https://github.com/vladmandic/automatic.git"
			).set_api(AutoWebUI_API
			).set_class(AutoWebUI_Repo
			).set_versions("00281e15d2f4d50b53fa892bae4e1cfa56e7ecd6", [], true
			).set_readme_title("# SD.Next"
			).set_id("SD.Next"
			).enable_install(false),
}

var repo: LocalRepo = null setget set_repo
var backend: String = ''


signal repository_changed(local_repo)


# GENERAL USE FUNCTIONS


func _ready():
	if repo == null:
		Cue.new(Consts.ROLE_SERVER_MANAGER, "show_installation_window").execute_or_store()


func set_repo(local_repo: LocalRepo):
	repo = local_repo
	if local_repo != null:
		emit_signal("repository_changed", repo)


# CHECK GRAPHICS CARD INFO
# Windows: wmic path win32_VideoController get name
# Linux: lspci | grep -i vga
#
# Example outputs:
#	00:02.0 VGA compatible controller: Intel Corporation UHD Graphics 630 (Mobile) (rev ...
#	01:00.0 VGA compatible controller: NVIDIA Corporation TU117M [GeForce GTX 1650 Mobile ...
#	2d:00.0 VGA compatible controller: Advanced Micro Devices, Inc. [AMD/ATI] Navi 21 [Radeon ...

# WINDOWS FUNCTIONS

# install git script: https://gist.github.com/patmigliaccio/c3fba12e4b6a62db70ad3ef791e29302
# install python without ui: https://silentinstallhq.com/python-3-10-silent-install-how-to-guide/

