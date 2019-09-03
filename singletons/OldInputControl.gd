extends Node

const SWIPE_RELATIVE_LENGHT = 5.4 # the minimum length event.relative should be to be considered a swipe
const HOLD_TIME = 0.5
const SWIPE_TIME = 0.1
const TAP_TIME = 0.2

# States
enum {STATE_NONE, STATE_TOUCH, STATE_MOVE, STATE_SWIPPING, STATE_SWIPE, STATE_HOLD,
		STATE_TAPPING, STATE_TAP, STATE_DOUBLE_TOUCH, STATE_DOUBLE_TAP,
		STATE_DOUBLE_HOLD}

# Inputs
enum {INPUT_SWIPE, INPUT_MOVE, INPUT_SWIPPING, INPUT_HOLD, INPUT_TAP,
		INPUT_DOUBLE_TAP, INPUT_TOUCH, INPUT_DOUBLE_TOUCH, INPUT_DOUBL_HOLD
		INPUT_RELEASE, INPUT_DOUBLE_HOLD}

signal input_event(event)

onready var timer = Timer.new()

var state = STATE_NONE setget set_state
var last_state = STATE_NONE # update at change_state
var status = {
	index = -1,
	touching = false,
	touch_start = Vector2(),
	swipe_start = Vector2(),
	position = Vector2(),
	relative = Vector2(),
}

func _ready():
	pause_mode = PAUSE_MODE_PROCESS
	
	add_child(timer)
	timer.wait_time = 0.2
	timer.one_shot = true
	timer.connect('timeout', self, '_on_Timer_timeout')

func _unhandled_input(event: InputEvent):
	if event is InputEventScreenDrag:
		if not event.index == status.index: return
		
		status.position = event.position
		status.relative = event.relative
		
		### MOVE
		if event.relative.length() < SWIPE_RELATIVE_LENGHT:
			match state:
				STATE_TOUCH:
					change_state(STATE_MOVE)
				STATE_MOVE:
					change_state(STATE_MOVE)
				STATE_DOUBLE_TOUCH:
					change_state(STATE_MOVE)
		
		### MOVE FAST
		else:
			# The swipe_start is defined here and reset at the timeout STATE_SWIPPING
			if not status.swipe_start: status.swipe_start = event.position
			
			match state:
				STATE_TOUCH:
					change_state(STATE_SWIPPING)
				STATE_MOVE:
					change_state(STATE_SWIPPING)
				STATE_SWIPPING:
					change_state(STATE_SWIPPING)
				
	elif event is InputEventScreenTouch:
		status.position = event.position
		
		### TOUCH SCREEN
		if event.is_pressed():
			# Touching with another finger will only change the tracked finger
			status.index = event.index
			status.touch_start = event.position
			
			match state:
				STATE_NONE:
					change_state(STATE_TOUCH)
				STATE_TAPPING:
					change_state(STATE_DOUBLE_TOUCH)
				STATE_TOUCH:
					change_state(STATE_TOUCH) # If anyone need to knoe that the tracked finger changed
		
		### RELEASE
		else:
			# Only consider the currently tracked finger
			if not event.index == status.index: return
			
			status.touching = false
			
			match state:
				STATE_TOUCH:
					if last_state == STATE_NONE:
						change_state(STATE_TAPPING)
					else: # last_state should be STATE_HOLD
						change_state(STATE_NONE)
						
				STATE_DOUBLE_TOUCH:
					if last_state == STATE_TAPPING:
						change_state(STATE_DOUBLE_TAP)
					else: # last_state should be STATE_DOUBLE_HOLD
						change_state(STATE_NONE)
				
				STATE_SWIPPING:
					change_state(STATE_SWIPE)
				STATE_MOVE:
					change_state(STATE_NONE)
			
			status.swipe_start = Vector2()

func _on_Timer_timeout():
	match state:
		STATE_TOUCH:
			change_state(STATE_HOLD)
		STATE_SWIPPING:
			change_state(STATE_MOVE)
			status.swipe_start = Vector2()
		STATE_TAPPING:
			change_state(STATE_TAP)
		STATE_DOUBLE_TOUCH:
			change_state(STATE_DOUBLE_HOLD)

func set_state(value):
	change_state(value)

func change_state(new_state : int, silent := false):
	last_state = state
	state = new_state
	
	# The possibility of changing state without sending signals or starting timers
	if silent: return
	
	match new_state:
		STATE_TOUCH:
			timer.start(HOLD_TIME)
			emit_signal("input_event", Event.new(INPUT_TOUCH, status.position))
		STATE_MOVE:
			emit_signal("input_event", Event.new(INPUT_MOVE, status.position, (status.position - status.touch_start).normalized(), status.relative))
		STATE_SWIPPING:
			timer.start(SWIPE_TIME)
			emit_signal("input_event", Event.new(INPUT_SWIPPING, status.position, (status.position - status.touch_start).normalized(), status.relative))
		STATE_HOLD:
			emit_signal("input_event", Event.new(INPUT_HOLD, status.position))
			change_state(STATE_TOUCH, true)
		STATE_SWIPE:
			var direction = (status.position - status.swipe_start).normalized()
			# Should not send direction as an empty vector
			if direction: emit_signal("input_event", Event.new(INPUT_SWIPE, status.position, direction))
			change_state(STATE_NONE)
		STATE_TAPPING:
			timer.start(TAP_TIME)
		STATE_TAP:
			emit_signal("input_event", Event.new(INPUT_TAP, status.position))
			change_state(STATE_NONE)
		STATE_DOUBLE_TOUCH:
			timer.start(HOLD_TIME)
			emit_signal("input_event", Event.new(INPUT_DOUBLE_TOUCH, status.position))
		STATE_DOUBLE_TAP:
			emit_signal("input_event", Event.new(INPUT_DOUBLE_TAP, status.position))
			change_state(STATE_NONE)
		STATE_DOUBLE_HOLD:
			emit_signal("input_event", Event.new(INPUT_DOUBLE_HOLD, status.position))
			change_state(STATE_DOUBLE_TOUCH, true)
		STATE_NONE:
			emit_signal("input_event", Event.new(INPUT_RELEASE, status.position))

class Event:
	var type : int
	var position : Vector2
	var relative : Vector2
	var direction : Vector2
	
	func _init(type:int, position:Vector2, direction:Vector2 = Vector2(), relative:Vector2 = Vector2()):
		self.type = type
		self.position = position
		self.direction = direction
		self.relative = relative
		
		return self