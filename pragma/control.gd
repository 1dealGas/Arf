extends AudioStreamPlayer
const FMPATH := "res://〈Fumen〉.gd"
const TIMESTR := "%d · %d"
const BTSTR := "%s · %s"
const _5 := "%.4f"
const _arf := preload("res://pragma/arf.gd")  # to Avoid the bug of "_super_implicit_constructor()"
const su50 := "scrollup_50ms"
const sd50 := "scrolldown_50ms"
const su500 := "scrollup_500ms"
const sd500 := "scrolldown_500ms"
const _fps := "( %d fps )"

# Variables
var _05x:bool = false
var audio_barl:float = 0
var audio_length:int = 0
var current_progress:int = 0
var fmgd_current_update:int = 0
var fmgd_last_update:int = 0
var tempot := [0,0]
var timet := [0,0]

# Reloader
func reload() -> void:
	_arf.clear_Arf()
	load(FMPATH).new().fumen()
	Arfc.compile()
	ArView.refresh(self).update(current_progress)
	if stream!=null:
		audio_barl = Arfc.get_bartime(audio_length)
		tempot[1] = audio_barl
		$Tempo.text = BTSTR % tempot

# A Wrapper of seek()
func _seek(prgms:float,prg_unknown:bool=true) -> void:
	stream_paused = false
	seek(prgms/1000.0)
	stream_paused = true
	if prg_unknown:
		var _t:float = Arfc.get_bartime(current_progress)
		ArView.update(current_progress)
		timet[0] = current_progress
		tempot[0] = _t
		$Time.text = TIMESTR % timet
		$Tempo.text = BTSTR % tempot
		$Hint1.text = _5 % (_t)
		$Hint2.text = _5 % (_t+0.0625)
		$Hint3.text = _5 % (_t+0.125)
		$Hint4.text = _5 % (_t+0.1875)
		$Hint5.text = _5 % (_t+0.25)
		$Hint6.text = _5 % (_t+0.3125)
		$Hint7.text = _5 % (_t+0.375)

# Init
func _enter_tree() -> void:
	if stream==null:
		stream = load("res://〈Audio〉.ogg")
	if stream!= null:
		audio_length = int(stream.get_length()*1000)
		timet[1] = audio_length
		$Time.text = TIMESTR % timet
		play()
		stream_paused = true
		print("")
	else:
		print("\nPlease Set the Audio Stream before Viewing Your Work.")

# File Listener
func _physics_process(_delta:float) -> void:
	fmgd_current_update = FileAccess.get_modified_time(FMPATH)
	if fmgd_current_update != fmgd_last_update and stream != null:
		reload()
		fmgd_last_update = fmgd_current_update
		print("\n〈fumen〉.gd Updated in %s" % Time.get_time_string_from_system())

# Updater
var last_progress:float = -1
func _process(_delta:float) -> void:
	$FPS.text = _fps % Performance.get_monitor(Performance.TIME_FPS)
	if stream!=null and not stream_paused:
		@warning_ignore("narrowing_conversion")
		current_progress = (get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()) * 1000
		if current_progress > audio_length-100:
			stream_paused = true
			$PlayButton.button_pressed = false
		if current_progress != last_progress:
			var _t:float = Arfc.get_bartime(current_progress)
			ArView.update(current_progress)
			timet[0] = current_progress
			tempot[0] = _t
			$Time.text = TIMESTR % timet
			$Tempo.text = BTSTR % tempot
			$Hint1.text = _5 % (_t)
			$Hint2.text = _5 % (_t+0.0625)
			$Hint3.text = _5 % (_t+0.125)
			$Hint4.text = _5 % (_t+0.1875)
			$Hint5.text = _5 % (_t+0.25)
			$Hint6.text = _5 % (_t+0.3125)
			$Hint7.text = _5 % (_t+0.375)
			last_progress = current_progress

# Input
const SCROLL_SCALE:float = 23.7
func _unhandled_input(event:InputEvent) -> void:
	if stream == null or not(stream_paused): return
	if event is InputEventPanGesture:
		current_progress = clampi(current_progress+event.delta.y*SCROLL_SCALE,10,audio_length-100)
		_seek(current_progress)
	elif event.is_action_pressed(su500):
		current_progress = clampi(current_progress+500,10,audio_length-100)
		_seek(current_progress)
	elif event.is_action_pressed(sd500):
		current_progress = clampi(current_progress-500,10,audio_length-100)
		_seek(current_progress)
	elif event.is_action_pressed(su50):
		current_progress = clampi(current_progress+50,10,audio_length-100)
		_seek(current_progress)
	elif event.is_action_pressed(sd50):
		current_progress = clampi(current_progress-50,10,audio_length-100)
		_seek(current_progress)
	

# Button
func _on_export_button_button_up() -> void:
	if stream != null: Arfc.export()
	else:
		reload()
		Arfc.export()
func _on_play_button_toggled(toggled_on:bool) -> void:
	if stream != null:  stream_paused = not(toggled_on)
func _on_spd_button_button_up() -> void:
	if _05x:
		$SpdButton.text = "1x"
		AudioServer.set_playback_speed_scale(1)
		_05x = false
	else:
		$SpdButton.text = "0.5x"
		AudioServer.set_playback_speed_scale(0.5)
		_05x = true
func _on_time_button_button_up() -> void:
	if stream!=null and stream_paused and $LineEdit.text.is_valid_float():
		current_progress = clampi(int($LineEdit.text.to_float()),0,audio_length-100)
		_seek(current_progress)
func _on_tempo_button_button_up() -> void:
	if stream!=null and stream_paused and $LineEdit.text.is_valid_float():
		var prg := clampf($LineEdit.text.to_float(),0,audio_barl-0.125)
		var prgms := Arfc.get_mstime(prg)
		_seek(prgms,false)
		current_progress = prgms
		ArView.update(prgms)
		current_progress = prgms
		timet[0] = prgms
		tempot[0] = prg
		$Time.text = TIMESTR % timet
		$Tempo.text = BTSTR % tempot
		$Hint1.text = _5 % (prg)
		$Hint2.text = _5 % (prg+0.0625)
		$Hint3.text = _5 % (prg+0.125)
		$Hint4.text = _5 % (prg+0.1875)
		$Hint5.text = _5 % (prg+0.25)
		$Hint6.text = _5 % (prg+0.3125)
		$Hint7.text = _5 % (prg+0.375)
