tool
extends Node
# STANDARDS
	# Images can only be pased to other objects as ImageData or base64 encoded
	

# TEXT2IMG ONLY CONFIGS
const T2I_ENABLE_HR = "enable_hr"
const T2I_FIRSTPHASE_WIDTH = "firstphase_width"
const T2I_FIRSTPHASE_HEIGHT = "firstphase_height"
const T2I_HR_SCALE = "hr_scale"
const T2I_HR_UPSCALER = "hr_upscaler"
const T2I_HR_SECOND_PASS_STEPS = "hr_second_pass_steps"
const T2I_HR_RESIZE_X = "hr_resize_x"
const T2I_HR_RESIZE_Y = "hr_resize_y"

# TEXT2IMAG AND IMG2IMG SHARED CONFIGS
const I_PROMPT = "prompt"
const I_NEGATIVE_PROMPT = "negative_prompt"
const I_SEED = "seed"
const I_CFG_SCALE = "cfg_scale"
const I_STEPS = "steps"
const I_WIDTH = "width"
const I_HEIGHT = "height"
const I_DENOISING_STRENGTH = "denoising_strength"
const I_SAMPLER_NAME = "sampler_name"
const I_BATCH_SIZE = "batch_size"
const I_N_ITER = "n_iter"
const I_RESTORE_FACES = "restore_faces"
const I_TILING = "tiling"
const I_OVERRIDE_SETTINGS = "override_settings"
const I_ALWAYS_ON_SCRIPTS = "alwayson_scripts"

# IMG2IMG ONLY CONFIGS
const I2I_INIT_IMAGES = "init_images"
const I2I_RESIZE_MODE = "resize_mode"
const I2I_IMAGE_CFG_SCALE = "image_cfg_scale"
const I2I_MASK = "mask"
const I2I_MASK_BLUR = "mask_blur"
const I2I_INPAINT_FULL_RES = "inpaint_full_res"
const I2I_INPAINTING_MASK_INVERT = "inpainting_mask_invert"

# STABLE DIFFUSION OPTIONS
const SDO_CLIP_SKIP = "CLIP_stop_at_last_layers"
const SDO_MODEL = "sd_model_checkpoint"
const SDO_MODEL_HASH = "sd_checkpoint_hash"
const SDO_ENSD = "eta_noise_seed_delta"

# OTHER IMAGE CONFIGS
const OI_PNG_INFO_IMAGE = "image"


# CONTROLNET CONFIGS
const CN_INPUT_IMAGE = "input_image"
const CN_MODULE = "module"
const CN_MODEL = "model"
const CN_WEIGHT = "weight"
const CN_RESIZE_MODE = "resize_mode"
const CN_LOWVRAM = "lowvram"
const CN_PROCESSOR_RES = "processor_res"
const CN_GUIDANCE_START = "guidance_start"
const CN_GUIDANCE_END = "guidance_end"
const CN_PIXEL_PERFECT = "pixel_perfect"
const CN_CONTROL_MODE = "control_mode"

# CONTROLNET RESIZE_MODE OPTIONS
const CN_RESIZE_CROP_TO_FIT = "Crop and Resize"
const CN_RESIZE_FILL_TO_FIT = "Resize and Fill"
const CN_RESIZE_SCALE_TO_FIT = "Just Resize"

# PREPROCESSOR ONLY CONFIGS
const PREP_ONLY_MODULE = "controlnet_module" # preprocessor to use. defaults to "none"
const PREP_ONLY_INPUT_IMAGES = "controlnet_input_images" # images to process. defaults to []
const PREP_ONLY_RESOLUTION = "controlnet_processor_res" # resolution. defaults to 512

# CONTROLNET PREPROCESSOR MODULES

const CNPREP_NONE = "none"
	# LINEART PREPROCESSORS
const CNPREP_LINEART_REALISTIC = "lineart"
const CNPREP_LINEART_COARSE = "lineart_coarse"
const CNPREP_LINEART_ANIME = "lineart_anime"
const CNPREP_CANNY = "canny"
const CNPREP_MLSD = "mlsd"
const CNPREP_SOFTEDGE_PIDINET_SAFE = "pidinet_safe"
const CNPREP_SOFTEDGE_HED_SAFE = "hed_safe"
	# DEPTH PREPROCESSORS
const CNPREP_DEPTH_MIDAS = "depth"
const CNPREP_DEPTH_LERES = "depth_leres"
const CNPREP_DEPTH_ZOE = "depth_zoe"
	# NORMAL MAP PREPROCESSORS
const CNPREP_NORMAL_BAE = "normal_bae"
const CNPREP_NORMAL_MAP = "normal_map"
	# SEGMENTATION PREPROCESSORS
const CNPREP_SEG_OFADE20K = "oneformer_ade20k"
const CNPREP_SEG_OFCOCO = "oneformer_coco"
const CNPREP_SEG_UFADE20K = "ufade20k"
	# OPENPOSE PREPROCESSORS
const CNPREP_OPENPOSE = "openpose"
const CNPREP_OPENPOSE_PLUS_FACE = "openpose_face"
const CNPREP_OPENPOSE_PLUS_HAND = "openpose_hand"
const CNPREP_OPENPOSE_ALL = "openpose_full"
	# SCRIBBLE PREPROCESSORS
const CNPREP_SCRIBBLE_HED = "scribble_hed"
const CNPREP_SCRIBBLE_PIDINET = "pidinet_scribble"
	# SHUFFLE PREPROCESSORS
const CNPREP_SHUFFLE = "shuffle"
	# COLOR/IMAGE FILTERS PREPROCESSORS
const CNPREP_COLOR_GRID_T2IA = "color"
const CNPREP_INVERT = "invert"
const CNPREP_THRESHOLD = "threshold"
	# CANCELED PREPROCESSORS (NOT USEFUL ENOUGH IN MY OPINION)
#const CNPREP_LINEART_ANIME_DENOISE = "lineart_anime_denoise" # lineart
#const CNPREP_LINEART_STANDARD = "lineart_standard" # lineart
#const CNPREP_SOFTEDGE_PIDINET = "pidinet" # lineart
#const CNPREP_SOFTEDGE_HED = "hed" # lineart
#const CNPREP_PIDINET_SKETCH_T2IA = "pidinet_sketch" # lineart
#const CNPREP_OPENPOSE_FACEONLY = "openpose_faceonly" # openpose
#const CNPREP_SCRIBBLE_XDOG = "scribble_xdog" # scribble
	# CANCELED PREPROCESSORS (DON'T KNOW WHAT THEY DO)
#const CNPREP_MEDIAPIPE_FACE = "mediapipe_face"
#const CNPREP_INPAINT = "inpaint"
#const CNPREP_TILE_RESAMPLE = "tile_resample"
#const CNPREP_CLIP_VISION_T2IA = "clip_vision"

# Controlnet types
const CN_TYPE_SHUFFLE = "shuffle" 
const CN_TYPE_TILE = "tile"
const CN_TYPE_DEPTH = "depth"
const CN_TYPE_CANNY = "canny"
const CN_TYPE_INPAINT = "inpaint"
const CN_TYPE_LINEART = "lineart"
const CN_TYPE_MLSD = "mlsd"
const CN_TYPE_NORMAL = "normal"
const CN_TYPE_OPENPOSE = "pose"
const CN_TYPE_SCRIBBLE = "scribble"
const CN_TYPE_SEG = "seg"
const CN_TYPE_SOFTEDGE = "softedge"
const CN_TYPE_IP2P = "ip2p"
const CN_TYPE_REFERENCE = "reference"
const CN_TYPE_COLOR = "color"

# ONLY AS FLAGS

const FLAG_BRUSH_SIZE = 'brush_size'
const FLAG_BRUSH_OPACITY = 'brush_opacity'
const FLAG_BRUSH_GREYSCALE_LIGHTNESS = 'brush_greyscale_lightness'
const FLAG_LINEART_INVERT_COLORS = 'lineart_invert_colors'
const FLAG_GRID_SIZE = 'grid_size'
const FLAG_SNAP_TO_GRID = 'snap_to_grid'
const FLAG_LOCK_PROPORTION_GEN_AREA = 'lock_proportion_gen_area'
const FLAG_LOCK_PROPORTION_TRANSFORM = 'lock_proportion_transform'
const FLAG_GRID_SNAP_GEN_AREA = 'grid_snap_gen_area'
const FLAG_GRID_SNAP_TRANSFORM = 'lgrid_snap_transform'
const FLAG_MAIN_CANVAS_GRID_SIZE = 'main_canvas_grid_size'
const FLAG_MAIN_CANVAS_SNAP_TO_GRID = 'main_canvas_snap_to_grid'
const FLAG_MAIN_CANVAS_HI_RES_FIX = 'main_canvas_hi_res_fix'
const FLAG_USE_MODIFIERS = 'use_modifiers'
const FLAG_DEPTH_PREPROCESSOR = 'depth_preprocessor'
const FLAG_LINEART_TYPE = 'lineart_type'
const FLAG_SCRIBBLE_TYPE = 'scribble_type'
const FLAG_COMPOSITION_PREPROCESSOR = 'composition_preprocessor'
const FLAG_NORMAL_MAP_PREPROCESSOR = 'normal_map_preprocessor'
const FLAG_PROMPT_MODE = 'prompt_mode'
const FLAG_GEN_AREA_PROPORTIONS = 'gen_area_proportions'
const FLAG_LAY_MODIFIERS_OPACITY = 'lay_modifiers_opacity'
const FLAG_OVERLAY_MODIFIERS_OPACITY = 'lay_over_modifiers_opacity'
const FLAG_UNDERLAY_MODIFIERS_OPACITY = 'lay_under_modifiers_opacity'
const FLAG_LAY_GEN_IMAGE_OPACITY = 'lay_gen_image_opacity'
const FLAG_LAY_GEN_MASK_OPACITY = 'lay_gen_mask_opacity'
const FLAG_HI_RES_TYPE = 'hi_res_type'
const FLAG_HI_RES_UPSCALER = 'hi_res_upscaler'
const FLAG_HI_RES_START_AT= 'hi_res_start_at'

# ROLES CONSTANTS
const ROLE_API = "API"
const ROLE_CANVAS = "Canvas"
const ROLE_GEN_AREA = "Generation area"
const ROLE_FILE_PICKER = "File picker"
const ROLE_DIALOGS = "Dialogs"
const ROLE_COLOR_PICKER_SERVICE = "File picker service"
const ROLE_STYLE_EDITOR = "Style editor"
const ROLE_MODEL_EDITOR = "Model editor"
const ROLE_MODEL_SELECTOR = "Model selector"
const ROLE_CONTROL_MAIN_CANVAS = "Canvas Control"
const ROLE_CONTROL_PNG_INFO = "Image Info Control"
const ROLE_CONTROL_LINEART = "Lineart Control"
const ROLE_CONTROL_COMPOSITION = "Composition Control"
const ROLE_CONTROL_SCRIBBLE = "Scribble Control"
const ROLE_CONTROL_POSE2D = "Pose 2D Control"
const ROLE_CONTROL_DEPTH = "Depth Control"
const ROLE_CONTROL_NORMAL_MAP = "Normal Map Control"
const ROLE_CONTROL_IMG2IMG = "Img2Img Control"
const ROLE_CONTROL_STYLING = "Styling Control"
const ROLE_CONTROL_REGION_PROMPT = "Regional Prompt Control"
const ROLE_CONTROL_REFERENCE = "Reference Control"
const ROLE_CONTROL_COLOR = "Reference Color Control"
const ROLE_PROMPTING_AREA = "Prompting area"
const ROLE_GENERATION_INTERFACE = "Generation interface"
const ROLE_ACTIVE_MODIFIER = "Active modifier"
const ROLE_ACTIVE_BOARD = "Active board"
const ROLE_MODIFIERS_AREA = "Modifiers area"
const ROLE_SP_IMAGE_VIEWER = "Specific image viewer"
const ROLE_TOOLBOX = "Toolbox"
const ROLE_SERVER_MANAGER = "Server Manager UI"
const ROLE_DIFFUSION_SERVER = "Diffusion Server"
const ROLE_SERVER_STATE_INDICATOR = "Server state indicator"
const ROLE_DESCRIPTION_BAR = "Description bar"
const ROLE_MENU_BAR = "Menu bar"
const ROLE_ABOUT_WINDOW = "About window"
const ROLE_LOCALE = "Locale"

# Server states
const SERVER_STATE_GENERATING = "GENERATING_IMAGE"
const SERVER_STATE_DOWNLOADING = "DOWNLOADING_MODEL"
const SERVER_STATE_PREPROCESSING = "PREPROCESSING_IMAGE"
const SERVER_STATE_READY = "SERVER_READY"
const SERVER_STATE_STARTING = "SERVER_STARTING"
const SERVER_STATE_PREPARING_DEPENDENCIES = "STATE_PREPARING_DEPENDENCIES"
const SERVER_STATE_PREPARING_PYTHON = "STATE_PREPARING_PYTHON"
const SERVER_STATE_INSTALLING = "STATE_INSTALLING"
const SERVER_STATE_LOADING = "STATE_LOADING"
const SERVER_STATE_SHUTDOWN = "STATE_SHUTDOWN"

# UI CONSTANTS
const UI_CURRENT_MODEL_THUMBNAIL_GROUP = "Current model thumbnails"
const UI_MINIMALIST_GROUP = "minimalist_ui"
const UI_ADVANCED_GROUP = "advanced_ui"
const UI_DROP_GROUP = "drop ui" # As in drag and drop
const UI_CANVAS_WITH_SHADOW_AREA = "canvas with shadow ui"
const UI_AI_PROCESS_ONGOING_GROUP = "ai loading group"
const UI_HAS_DESCRIPTION_GROUP = "has description group"
const MENU_SAVE = "SAVE"
const MENU_SAVE_AS = "SAVE_AS"
const MENU_SAVE_IMAGE = "SAVE_IMAGE"
const MENU_SAVE_IMAGE_AS = "SAVE_IMAGE_AS"
const MENU_SAVE_CANVAS = "SAVE_CANVAS"
const MENU_SAVE_CANVAS_AS = "SAVE_CANVAS_AS"
const MENU_SAVE_PREVIEW = "SAVE_PREVIEW"
const MENU_SAVE_PREVIEW_AS = "SAVE_PREVIEW_AS"
const MENU_SAVE_ACTIVE_IMAGE = "SAVE_ACTIVE_IMAGE"
const MENU_SAVE_ACTIVE_IMAGE_AS = "SAVE_ACTIVE_IMAGE_AS"
const MENU_EDIT = "EDIT"
const UI_CONTROL_RIGHT_CLICK = "UI_CONTROL_RIGHT_CLICK"
const UI_CONTROL_LEFT_CLICK = "UI_CONTROL_LEFT_CLICK"
const UI_CONTROL_MIDDLE_CLICK = "UI_CONTROL_MIDDLE_CLICK"
const UI_CONTROL_SCROLL_UP = "UI_CONTROL_SCROLL_UP"
const UI_CONTROL_SCROLL_DOWN = "UI_CONTROL_SCROLL_DOWN"
# Modifier area add button
const MENU_ADD_SCRIBBLE = "ADD_SCRIBBLE"
const MENU_ADD_REGIONAL_PROMPTING = "ADD_REGIONAL_PROMPTING"
# Modifier area delete button
const MENU_DELETE_ALL_MODIFIERS = "DELETE_ALL_MODIFIERS"
const MENU_DELETE_SELECTED_MODIFIERS = "DELETE_SELECTED_MODIFIERS"
const MENU_DELETE_ACTIVE_MODIFIERS = "DELETE_ACTIVE_MODIFIERS"
const MENU_DELETE_INACTIVE_MODIFIERS = "DELETE_INACTIVE_MODIFIERS"
const MENU_RESTORE_DELETED_MODIFIERS = "RESTORE_DELETED_MODIFIERS"
const MENU_DELETE = "DELETE"
# Modifier area other button
const MENU_ACTIVATE_ALL_MODIFIERS = "ACTIVATE_ALL_MODIFIERS"
const MENU_INACTIVATE_ALL_MODIFIERS = "INACTIVATE_ALL_MODIFIERS"
# Theme modulate groups
const THEME_MODULATE_GROUP_STYLE = "theme_modulate_by_style"
const THEME_MODULATE_GROUP_TYPE = "theme_modulate_by_type"
# Others
const IMG_INFO_PROMPT_MODE_REPLACE_PROMPT = "REPLACE_PROMPT"
const IMG_INFO_PROMPT_MODE_APPEND_PROMPT = "APPEND_PROMPT"
const TRY_PNG_INFO_IMAGE_CHECKED = "TRY_PNG_INFO_IMAGE_CHECKED"
const TRY_PNG_INFO_IMAGE_ALL = "TRY_PNG_INFO_IMAGE_ALL"
const COPY_CONFIG_DATA_RAW_TEXT = "COPY_CONFIG_DATA_RAW_TEXT"
const COPY_CONFIG_DATA_JSON = "COPY_CONFIG_DATA_JSON"
# Help descriptions
const HELP_DESC_MOVE_CAMERA = "HELP_DESC_MOVE_CAMERA"
const HELP_DESC_ZOOM_IN = "HELP_DESC_ZOOM_IN"
const HELP_DESC_ZOOM_OUT = "HELP_DESC_ZOOM_OUT"
const HELP_DESC_PAINT = "HELP_DESC_PAINT"
const HELP_DESC_ERASE = "HELP_DESC_ERASE"
const HELP_DESC_PAINT_INPAINT_MASK = "HELP_DESC_PAINT_INPAINT_MASK"
const HELP_DESC_ERASE_INPAINT_MASK = "HELP_DESC_ERASE_INPAINT_MASK"
const HELP_DESC_MOVE_AREA = "HELP_DESC_MOVE_AREA"
const HELP_DESC_MOVE_IMAGE = "HELP_DESC_MOVE_IMAGE"
const HELP_DESC_SAVE_OPTIONS_MENU = "HELP_DESC_SAVE_OPTIONS_MENU"
const HELP_DESC_IMAGE_GENERATED = "HELP_DESC_IMAGE_GENERATED"
const HELP_DESC_IMAGE_SAVED = "HELP_DESC_IMAGE_SAVED"
const HELP_DESC_SERVER_SHUTDOWN = "HELP_DESC_SERVER_SHUTDOWN"
const HELP_DESC_INFO_COPIED_CLIPBOARD = "HELP_DESC_INFO_COPIED_CLIPBOARD"
const HELP_DESC_IMAGE_GEN_FAILED = "HELP_DESC_IMAGE_GEN_FAILED"
const HELP_DESC_PREPROCESSOR_IN_PROCESS = "HELP_DESC_PREPROCESSOR_IN_PROCESS"
const HELP_DESC_IMAGE_PREPROCESSED = "HELP_DESC_IMAGE_PREPROCESSED"
const HELP_DESC_SAVE_FILE_LOADED = "HELP_DESC_SAVE_FILE_LOADED"

# themes colors go here
const MAIN_COLOR_A = 255
const ACCENT_COLOR_A = 254
const ACCENT_COLOR_AUX1_A = 253 # hover/focus
const TERMINATE_COLOR_A = 252 # quit/terminate
const TERMINATE_COLOR_AUX1_A = 251 # quit/terminate hover/focus
const OPPOSITE_COLOR_A = 250
const ACCENT_CONTRAST_TEXT_A = 249
const LABEL_FONT_COLOR_A = 245 
const LABEL_FONT_COLOR_INVERSE_A = 244
const POPUP_PANEL_COLOR_A = 225
#const PANEL_COLOR_A = 80  
const CONTRAST_GLASS_A = 135
const CONTRAST_GLASS_HOVER_A = 190
const ACCENT_GLASS_HOVER_A = 191
const ACCENT_GLASS_LOW_A = 80
const MATCHING_GLASS_A = 134
const MATCHING_GLASS_HOVER_A = 189

var GENERIC_LIGHT_PRESET: Dictionary = {
	MAIN_COLOR_A: make_color("fdfdfd", MAIN_COLOR_A),
	OPPOSITE_COLOR_A: make_color("191919", OPPOSITE_COLOR_A),
	POPUP_PANEL_COLOR_A: make_color("fdfdfd", POPUP_PANEL_COLOR_A),
	CONTRAST_GLASS_A: make_color("000000", CONTRAST_GLASS_A),
	CONTRAST_GLASS_HOVER_A: make_color("000000", CONTRAST_GLASS_HOVER_A),
	MATCHING_GLASS_A: make_color("ffffff", MATCHING_GLASS_A),
	MATCHING_GLASS_HOVER_A: make_color("ffffff", MATCHING_GLASS_HOVER_A),
	TERMINATE_COLOR_A: make_color("ba4343", TERMINATE_COLOR_A),
	TERMINATE_COLOR_AUX1_A: make_color("d35151", TERMINATE_COLOR_A),
}

var GENERIC_DARK_PRESET: Dictionary = {
	MAIN_COLOR_A: make_color("191919", MAIN_COLOR_A),
	OPPOSITE_COLOR_A: make_color("fdfdfd", OPPOSITE_COLOR_A),
	POPUP_PANEL_COLOR_A: make_color("191919", POPUP_PANEL_COLOR_A),
	CONTRAST_GLASS_A: make_color("e0e0e0", CONTRAST_GLASS_A),
	CONTRAST_GLASS_HOVER_A: make_color("e0e0e0", CONTRAST_GLASS_HOVER_A),
	MATCHING_GLASS_A: make_color("191919", MATCHING_GLASS_A),
	MATCHING_GLASS_HOVER_A: make_color("191919", MATCHING_GLASS_HOVER_A),
	TERMINATE_COLOR_A: make_color("ba4343", TERMINATE_COLOR_A),
	TERMINATE_COLOR_AUX1_A: make_color("d35151", TERMINATE_COLOR_A),
}

var THEME_BLUE_LIGHT_STYLE = {
	ACCENT_COLOR_A: make_color("1865be", ACCENT_COLOR_A),
	ACCENT_COLOR_AUX1_A: make_color("3e99fa", ACCENT_COLOR_AUX1_A),
	ACCENT_GLASS_LOW_A: make_color("3e99fa", ACCENT_GLASS_LOW_A),
	ACCENT_GLASS_HOVER_A: make_color("3e99fa", ACCENT_GLASS_HOVER_A),
	ACCENT_CONTRAST_TEXT_A: make_color("ffffff", ACCENT_CONTRAST_TEXT_A),
}
var THEME_BLUE_DARK_STYLE = {
	ACCENT_COLOR_A: make_color("006ee4", ACCENT_COLOR_A),
	ACCENT_COLOR_AUX1_A: make_color("43b0ff", ACCENT_COLOR_AUX1_A),
	ACCENT_GLASS_LOW_A: make_color("43b0ff", ACCENT_GLASS_LOW_A),
	ACCENT_GLASS_HOVER_A: make_color("43b0ff", ACCENT_GLASS_HOVER_A),
	ACCENT_CONTRAST_TEXT_A: make_color("ffffff", ACCENT_CONTRAST_TEXT_A),
}

var THEME_ORANGE_LIGHT_STYLE = {
	ACCENT_COLOR_A: make_color("e86d42", ACCENT_COLOR_A),
	ACCENT_COLOR_AUX1_A: make_color("ff9460", ACCENT_COLOR_AUX1_A),
	ACCENT_GLASS_LOW_A: make_color("ff9460", ACCENT_GLASS_LOW_A),
	ACCENT_GLASS_HOVER_A: make_color("ff9460", ACCENT_GLASS_HOVER_A),
	ACCENT_CONTRAST_TEXT_A: make_color("ffffff", ACCENT_CONTRAST_TEXT_A),
}
# f65923 fc7b3c
var THEME_ORANGE_DARK_STYLE = {
	ACCENT_COLOR_A: make_color("eb683f", ACCENT_COLOR_A),
	ACCENT_COLOR_AUX1_A: make_color("f78e4f", ACCENT_COLOR_AUX1_A),
	ACCENT_GLASS_LOW_A: make_color("f78e4f", ACCENT_GLASS_LOW_A),
	ACCENT_GLASS_HOVER_A: make_color("f78e4f", ACCENT_GLASS_HOVER_A),
	ACCENT_CONTRAST_TEXT_A: make_color("ffffff", ACCENT_CONTRAST_TEXT_A),
}

var THEME_PINK_LIGHT_STYLE = {
	ACCENT_COLOR_A: make_color("ff7c7c", ACCENT_COLOR_A),
	ACCENT_COLOR_AUX1_A: make_color("fd6161", ACCENT_COLOR_AUX1_A),
	ACCENT_GLASS_LOW_A: make_color("fd6161", ACCENT_GLASS_LOW_A),
	ACCENT_GLASS_HOVER_A: make_color("fd6161", ACCENT_GLASS_HOVER_A),
	ACCENT_CONTRAST_TEXT_A: make_color("ffffff", ACCENT_CONTRAST_TEXT_A),
}
var THEME_PINK_DARK_STYLE = {
	ACCENT_COLOR_A: make_color("ff7c7c", ACCENT_COLOR_A),
	ACCENT_COLOR_AUX1_A: make_color("ff5252", ACCENT_COLOR_AUX1_A),
	ACCENT_GLASS_LOW_A: make_color("ff5252", ACCENT_GLASS_LOW_A),
	ACCENT_GLASS_HOVER_A: make_color("ff5252", ACCENT_GLASS_HOVER_A),
	ACCENT_CONTRAST_TEXT_A: make_color("ffffff", ACCENT_CONTRAST_TEXT_A),
}

var THEME_RED_LIGHT_STYLE = {
	ACCENT_COLOR_A: make_color("c03737", ACCENT_COLOR_A),
	ACCENT_COLOR_AUX1_A: make_color("ff4646", ACCENT_COLOR_AUX1_A),
	ACCENT_GLASS_LOW_A: make_color("ff4646", ACCENT_GLASS_LOW_A),
	ACCENT_GLASS_HOVER_A: make_color("ff4646", ACCENT_GLASS_HOVER_A),
	ACCENT_CONTRAST_TEXT_A: make_color("ffffff", ACCENT_CONTRAST_TEXT_A),
}
var THEME_RED_DARK_STYLE = {
	ACCENT_COLOR_A: make_color("992626", ACCENT_COLOR_A),
	ACCENT_COLOR_AUX1_A: make_color("d23c3c", ACCENT_COLOR_AUX1_A),
	ACCENT_GLASS_LOW_A: make_color("d23c3c", ACCENT_GLASS_LOW_A),
	ACCENT_GLASS_HOVER_A: make_color("d23c3c", ACCENT_GLASS_HOVER_A),
	ACCENT_CONTRAST_TEXT_A: make_color("ffffff", ACCENT_CONTRAST_TEXT_A),
}


var THEME_LIGHT_TYPE = {
	LABEL_FONT_COLOR_A: make_color("232323", LABEL_FONT_COLOR_A),
	LABEL_FONT_COLOR_INVERSE_A: make_color("ffffff", LABEL_FONT_COLOR_INVERSE_A),
}
var THEME_DARK_TYPE = {
	LABEL_FONT_COLOR_A: make_color("ffffff", LABEL_FONT_COLOR_A),
	LABEL_FONT_COLOR_INVERSE_A: make_color("232323", LABEL_FONT_COLOR_INVERSE_A),
}

const DEFAULT_IMAGE_PATH = "res://qinti_default.png"
var default_image_data: ImageData = null
var default_image_obj: Texture 
var pc_data: PCData = PCData.new()


func _ready():
	default_image_obj = load(ProjectSettings.globalize_path(DEFAULT_IMAGE_PATH))
	default_image_data = ImageData.new("default_image")
	default_image_data.load_texture(default_image_obj)
	if not Engine.editor_hint:
		Director.set_up_locker(ROLE_SERVER_MANAGER)


func make_color(color_hex_code: String, alpha8: int) -> Color:
	var color = Color(color_hex_code)
	color.a8 = alpha8
	return color




