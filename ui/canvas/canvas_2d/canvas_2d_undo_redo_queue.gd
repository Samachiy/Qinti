extends Reference

class_name Canvas2DUndoQueue

# When moving an action out of the undoredo queue, we usually need to move nodes 
# into the permanent viewport. This causes the canvas to blink, and once the 
# undoredo queue is full, it will blink on every single stroke,
# hence, we make the merge cue, 
var cursor = -1
var undoredo_actions = []
var undoredo_limit = 4
var merge_queue = []
var merge_limit = 20


func _init(undo_limit: int):
	undoredo_limit = undo_limit
	if OS.has_feature("standalone"):
		undoredo_limit = 20
		merge_limit = 20
	else:
		undoredo_limit = 4
		merge_limit = 4


func undo():
	var action: Canvas2DUndoAction
	if cursor >= 0 and cursor < undoredo_actions.size():
		action = undoredo_actions[cursor]
		action.undo()
		cursor -= 1


func redo():
	var action: Canvas2DUndoAction
	if cursor + 1 >= 0 and cursor + 1 < undoredo_actions.size():
		action = undoredo_actions[cursor + 1]
		action.redo()
		cursor += 1


func add(layer: Control):
	if cursor + 1 < undoredo_actions.size():
		# Here, we are trimming the redo actions that are not gonna be used
		# (If cursor is not the last entry, and we want to add a new one, 
		# the new entry will replace all next redos, for a new edit path 
		# has been taken)
		delete_after_cursor_position()
	
	var action = Canvas2DUndoAction.new(layer)
	undoredo_actions.append(action)
	cursor += 1
	
	if cursor == undoredo_limit:
		# if limit is -1, this 'if' will never activate, effectively having an infinite limit
		merge_last()
		cursor -= 1
	return action


func merge_last():
	if not undoredo_actions.empty():
		merge_queue.append(undoredo_actions.pop_front())
	
	if merge_queue.size() >= merge_limit:
		for action in merge_queue:
			action.merge()
		
		merge_queue = []


func delete_after_cursor_position():
	var action: Canvas2DUndoAction
	for i in range(cursor + 1, undoredo_actions.size()):
		action = undoredo_actions[i]
		action.destroy()
	
	undoredo_actions.resize(cursor + 1)


func flush():
	for action in undoredo_actions:
		action.merge()
	
	cursor = -1
	undoredo_actions = []
	merge_queue = []


func reset():
	while cursor >= 0:
		undo()


func restore():
	while cursor + 1 < undoredo_actions.size():
		redo()
