extends TutorialOrganizer


const TUT1 = "t1_basic_intro"
const TUT1_WELCOME = "TUT1_WELCOME"
const TUT1_PARAMETERS = "TUT1_PARAMETERS"
const TUT1_ADVAN_PARAMETERS = "TUT1_ADVAN_PARAMETERS"
const TUT1_TOOLS = "TUT1_TOOLS"
const TUT1_PROMPT = "TUT1_PROMPT" 
const TUT1_GEN_BUTTON = "TUT1_GEN_BUTTON" 
var t1_basic_intro = [
	TUT1_WELCOME,
	TUT1_PARAMETERS,
	TUT1_ADVAN_PARAMETERS,
	TUT1_TOOLS,
	TUT1_PROMPT,
	TUT1_GEN_BUTTON,
]

const TUT2 = "t2_first_generation"
const TUT2_APPLY_GENERATION = "TUT2_APPLY_GENERATION"
const TUT2_MOVE_EDIT_GENERATION = "TUT2_MOVE_EDIT_GENERATION"
const TUT2_SAVE_GENERATION = "TUT2_SAVE_GENERATION"
const TUT2_SAVE_IMAGE_VIEWER = "TUT2_SAVE_IMAGE_VIEWER"
var t2_first_generation = [
	TUT2_APPLY_GENERATION,
	TUT2_MOVE_EDIT_GENERATION,
	TUT2_SAVE_GENERATION,
	TUT2_SAVE_IMAGE_VIEWER,
]

const TUT3 = "t3_recent_image_drag"
const TUT3_LOAD_IMAGE_DRAG = "TUT3_LOAD_IMAGE_DRAG"
const TUT3_CONTROL_NET_DRAG = "TUT3_CONTROL_NET_DRAG"
const TUT3_PREVIEW_DRAG = "TUT3_PREVIEW_DRAG"
var t3_recent_image_drag = [
	TUT3_LOAD_IMAGE_DRAG,
	TUT3_CONTROL_NET_DRAG,
	TUT3_PREVIEW_DRAG,
]

const TUT4 = "t4_modifier_intro"
const TUT4_CHANGE_MODIFIER = "TUT4_CHANGE_MODIFIER"
const TUT4_MODIFIER_HELP = "TUT4_MODIFIER_HELP"
const TUT4_TUTORIALS = "TUT4_TUTORIALS"
const TUT4_FINISH = "TUT4_FINISH"
var t4_modifier_intro = [
	TUT4_CHANGE_MODIFIER,
	TUT4_MODIFIER_HELP,
	TUT4_TUTORIALS,
	TUT4_FINISH,
]

const TUT5 = "t5_lora_lycoris_ti"
const TUT5_OPENING = "TUT5_OPENING"
const TUT5_NAVIGATION = "TUT5_NAVIGATION"
const TUT5_SEARCH = "TUT5_SEARCH"
const TUT5_LOAD = "TUT5_LOAD"
const TUT5_PARAMETERS = "TUT5_PARAMETERS"
const TUT5_DEFAULTS = "TUT5_DEFAULTS"
const TUT5_NEW_MODELS = "TUT5_NEW_MODELS"
var t5_lora_lycoris_ti = [
	TUT5_OPENING,
	TUT5_NAVIGATION,
	TUT5_SEARCH,
	TUT5_LOAD,
	TUT5_PARAMETERS,
	TUT5_DEFAULTS,
	TUT5_NEW_MODELS,
]

const TUT6 = "t6_models" 
const TUT6_OPENING = "TUT6_OPENING"
const TUT6_SELECTING = "TUT6_SELECTING"
const TUT6_SEARCH = "TUT6_SEARCH"
const TUT6_NEW_MODELS = "TUT6_NEW_MODELS"
var t6_models = [
	TUT6_OPENING,
	TUT6_SELECTING,
	TUT6_SEARCH,
	TUT6_NEW_MODELS,
]

const TUT7 = "t7_log_and_status" 
const TUT7_OPENING = "TUT7_OPENING"
var t7_log_and_status = [
	TUT7_OPENING,
]

const TUT8 = "t8_opening_saving_img" 
const TUT8_SAVING_RECENT = "TUT2_SAVE_GENERATION"
const TUT8_CANVAS = "TUT8_CANVAS"
const TUT8_ACTIVE_IMAGE = "TUT8_ACTIVE_IMAGE"
const TUT8_PREVIEW = "TUT8_PREVIEW"
const TUT8_LOAD = "TUT8_LOAD"
var t8_opening_saving_img = [
	TUT8_SAVING_RECENT,
	TUT8_CANVAS,
	TUT8_ACTIVE_IMAGE,
	TUT8_PREVIEW,
	TUT8_LOAD,
]

const TUT9 = "t9_inpainting"
const TUT9_DEFINITION = "TUT9_DEFINITION"
const TUT9_TOOLS = "TUT9_TOOLS"
const TUT9_MASK = "TUT9_MASK"
const TUT9_ERASER = "TUT9_ERASER"
const TUT9_DENOISING = "TUT9_DENOISING"
var t9_inpainting = [
	TUT9_DEFINITION,
	TUT9_TOOLS,
	TUT9_MASK,
	TUT9_ERASER,
	TUT9_DENOISING,
]

const TUT10 = "t10_outpainting" 
const TUT10_DEFINITION = "TUT10_DEFINITION"
const TUT10_TOOL = "TUT10_TOOL"
const TUT10_EXTEND = "TUT10_EXTEND"
const TUT10_DENOISING = "TUT10_DENOISING"
var t10_outpainting = [
	TUT10_DEFINITION,
	TUT10_TOOL,
	TUT10_EXTEND,
	TUT10_DENOISING,
]

const TUTM0_CONTROLNET_WEIGHT = "TUTM0_CONTROLNET_WEIGHT"
const TUTM0_MOD_VISIBILITY = "TUTM0_MOD_VISIBILITY"
const TUTM0_MOD_VISIBILITY_CONFIG = "TUTM0_MOD_VISIBILITY_CONFIG"

const TUTM1 = "tm1_image_info" 
const TUTM1_DESCRIPTION = "TUTM1_DESCRIPTION"
const TUTM1_DETAILS = "TUTM1_DETAILS"
const TUTM1_DESC_BOX = "TUTM1_DESC_BOX"
const TUTM1_COPY = "TUTM1_COPY"
var tm1_image_info = [
	TUTM1_DESCRIPTION,
	TUTM1_DETAILS,
	TUTM1_DESC_BOX,
	TUTM1_COPY,
]

const TUTM2 = "tm2_lineart"
const TUTM2_DESCRIPTION = "TUTM2_DESCRIPTION"
const TUTM2_USE = "TUTM2_USE"
const TUTM2_TYPES = "TUTM2_TYPES"
const TUTM2_EXTRA_TYPES = "TUTM2_EXTRA_TYPES"
var tm2_lineart = [
	TUTM2_DESCRIPTION,
	TUTM2_USE,
	TUTM2_TYPES,
	TUTM2_EXTRA_TYPES,
	TUTM0_CONTROLNET_WEIGHT,
	TUTM0_MOD_VISIBILITY,
	TUTM0_MOD_VISIBILITY_CONFIG,
]

const TUTM3 = "tm3_composition"
const TUTM3_DESCRIPTION = "TUTM3_DESCRIPTION"
var tm3_composition = [
	TUTM3_DESCRIPTION,
	TUTM0_CONTROLNET_WEIGHT,
	TUTM0_MOD_VISIBILITY,
	TUTM0_MOD_VISIBILITY_CONFIG,
]

const TUTM4 = "tm4_scribble" 
const TUTM4_DESCRIPTION = "TUTM4_DESCRIPTION"
var tm4_scribble = [
	TUTM4_DESCRIPTION,
	TUTM0_CONTROLNET_WEIGHT,
	TUTM0_MOD_VISIBILITY,
	TUTM0_MOD_VISIBILITY_CONFIG,
]

const TUTM5 = "tm5_depth"
const TUTM5_DESCRIPTION = "TUTM5_DESCRIPTION"
var tm5_depth = [
	TUTM5_DESCRIPTION,
	TUTM0_CONTROLNET_WEIGHT,
	TUTM0_MOD_VISIBILITY,
	TUTM0_MOD_VISIBILITY_CONFIG,
]

const TUTM6 = "tm6_normal_map"
const TUTM6_DESCRIPTION = "TUTM6_DESCRIPTION"
var tm6_normal_map = [
	TUTM6_DESCRIPTION,
	TUTM0_CONTROLNET_WEIGHT,
	TUTM0_MOD_VISIBILITY,
	TUTM0_MOD_VISIBILITY_CONFIG,
]

const TUTM7 = "tm7_image_to_image"
const TUTM7_DESCRIPTION = "TUTM7_DESCRIPTION"
const TUTM7_WEIGHT = "TUTM7_WEIGHT"
var tm7_image_to_image = [
	TUTM7_DESCRIPTION,
	TUTM7_WEIGHT,
	TUTM0_MOD_VISIBILITY,
	TUTM0_MOD_VISIBILITY_CONFIG,
]

const TUTM8 = "tm8_pose"
const TUTM8_DESCRIPTION = "TUTM8_DESCRIPTION"
const TUTM8_FACE_HANDS = "TUTM8_FACE_HANDS"
var tm8_pose = [
	TUTM8_DESCRIPTION,
	TUTM8_FACE_HANDS,
	TUTM0_CONTROLNET_WEIGHT,
	TUTM0_MOD_VISIBILITY,
	TUTM0_MOD_VISIBILITY_CONFIG,
]

const TUTM9 = "tm9_styling"
const TUTM9_DESCRIPTION = "TUTM9_DESCRIPTION"
const TUTM9_STRENGHT = "TUTM9_STRENGHT"
const TUTM9_IS_NEGATIVE = "TUTM9_IS_NEGATIVE"
const TUTM9_EXTRA = "TUTM9_EXTRA"
const TUTM9_EXTRA_SLIDER = "TUTM9_EXTRA_SLIDER"
var tm9_styling = [
	TUTM9_DESCRIPTION,
	TUTM9_STRENGHT,
	TUTM9_IS_NEGATIVE,
	TUTM9_EXTRA,
	TUTM9_EXTRA_SLIDER,
]

const TUTM10 = "tm10_reference"
const TUTM10_DESCRIPTION = "TUTM10_DESCRIPTION"
const TUTM10_EMPTY_SPACE_IS_WHITE = "TUTM10_EMPTY_SPACE_IS_WHITE"
const TUTM10_EMPTY_SPACE_ADVICE = "TUTM10_EMPTY_SPACE_ADVICE"
var tm10_reference = [
	TUTM10_DESCRIPTION,
	TUTM10_EMPTY_SPACE_IS_WHITE,
	TUTM10_EMPTY_SPACE_ADVICE,
	TUTM0_CONTROLNET_WEIGHT,
	TUTM0_MOD_VISIBILITY,
	TUTM0_MOD_VISIBILITY_CONFIG,
]

const TUTM11 = "tm11_color"
const TUTM11_DESCRIPTION = "TUTM11_DESCRIPTION"
var tm11_color = [
	TUTM11_DESCRIPTION,
	TUTM0_CONTROLNET_WEIGHT,
]

var removable_tutorials: Array = [
	TUT1, TUT2, TUT3, TUT4
]

enum flag_states{
	NORMAL,
	FORCE_RUN,
	FORCE_SKIP,
}
var flag_state = flag_states.NORMAL

func _ready():
	if OS.has_feature("standalone"):
		flag_state = flag_states.NORMAL


func run_with_const(const_id: String, use_flag: bool):
	# Automatically loads the steps if we pass the const name of the tutorial. 
	# Example: TUT1
	var id = get(const_id)
	if id == null:
		l.g("Can't prepare tutorial with const: " + const_id)
		return
	
	run_with_name(id, use_flag)


func run_with_name(id: String, use_flag: bool, prerequisite_tutorials: Array = []):
	# Automatically loads the steps if we pass the name of the tutorial as described in the const. 
	# Example: t1_basic_intro
	var steps = get(id)
	if steps == null:
		l.g("Can't prepare tutorial stepps with const: " + steps)
		return
	
	if not should_run(id, use_flag):
		return
	
	if not Flags.has(prerequisite_tutorials):
		return
	
	if is_tutorial_running():
		return
	
	yield(get_tree(), "idle_frame")
	prepare(id, steps)
	yield(get_tree(), "idle_frame")
	start(id)


func should_run(id: String, flag: bool):
	match flag_state:
		flag_states.NORMAL:
			if flag:
				return not Flag.new(id).exists()
			else:
				return true
		flag_states.FORCE_RUN:
			return true 
		flag_states.FORCE_SKIP:
			return false


func is_tutorial_running():
	return Cue.new(TutorialDisplay.DEFAULT_ROLE, "is_running").execute()


func reset():
	reset_by_flags(removable_tutorials)
