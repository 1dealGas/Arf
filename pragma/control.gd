extends AudioStreamPlayer
const FMPATH := "res://〈Fumen〉.gd"
const TIMESTR := "%d · %d"
const BTSTR := "%s · %s"
const _arf := preload("res://pragma/arf.gd")  # to Avoid the bug of "_super_implicit_constructor()"
const su50 := "scrollup_50ms"
const sd50 := "scrolldown_50ms"
const su500 := "scrollup_500ms"
const sd500 := "scrolldown_500ms"

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
func _seek(prg:float) -> void:
	stream_paused = false
	seek(prg/1000.0)
	stream_paused = true

# Init
func _enter_tree() -> void:
	if stream!= null:
		audio_length = int(stream.get_length()*1000)
		timet[1] = audio_length
		$Time.text = TIMESTR % timet
		play()
		stream_paused = true
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
func _process(_delta:float) -> void:
	if stream!=null and not stream_paused:
		@warning_ignore("narrowing_conversion")
		current_progress = (get_playback_position() + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency()) * 1000
		ArView.update(current_progress)
		timet[0] = current_progress
		tempot[0] = Arfc.get_bartime(current_progress)
		$Time.text = TIMESTR % timet
		$Tempo.text = BTSTR % tempot

# Input
const SCROLL_SCALE:float = 23.7
func _unhandled_input(event:InputEvent) -> void:
	if stream == null or not(stream_paused): return
	if event is InputEventPanGesture:
		current_progress = clampi(current_progress+event.delta.y*SCROLL_SCALE,0,audio_length)
		_seek(current_progress)
		ArView.update(current_progress)
		timet[0] = current_progress
		tempot[0] = Arfc.get_bartime(current_progress)
		$Time.text = TIMESTR % timet
		$Tempo.text = BTSTR % tempot
	elif event.is_action_pressed(su500):
		current_progress = clampi(current_progress+500,0,audio_length)
		_seek(current_progress)
		ArView.update(current_progress)
		timet[0] = current_progress
		tempot[0] = Arfc.get_bartime(current_progress)
		$Time.text = TIMESTR % timet
		$Tempo.text = BTSTR % tempot
	elif event.is_action_pressed(sd500):
		current_progress = clampi(current_progress-500,0,audio_length)
		_seek(current_progress)
		ArView.update(current_progress)
		timet[0] = current_progress
		tempot[0] = Arfc.get_bartime(current_progress)
		$Time.text = TIMESTR % timet
		$Tempo.text = BTSTR % tempot
	elif event.is_action_pressed(su50):
		current_progress = clampi(current_progress+50,0,audio_length)
		_seek(current_progress)
		ArView.update(current_progress)
		timet[0] = current_progress
		tempot[0] = Arfc.get_bartime(current_progress)
		$Time.text = TIMESTR % timet
		$Tempo.text = BTSTR % tempot
	elif event.is_action_pressed(sd50):
		current_progress = clampi(current_progress-50,0,audio_length)
		_seek(current_progress)
		ArView.update(current_progress)
		timet[0] = current_progress
		tempot[0] = Arfc.get_bartime(current_progress)
		$Time.text = TIMESTR % timet
		$Tempo.text = BTSTR % tempot
	

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
		var prg := clampi(int($LineEdit.text.to_float()),0,audio_length)
		_seek(prg)
		ArView.update(prg)
		timet[0] = prg
		tempot[0] = Arfc.get_bartime(prg)
		current_progress = prg
		$Time.text = TIMESTR % timet
		$Tempo.text = BTSTR % tempot
func _on_tempo_button_button_up() -> void:
	if stream!=null and stream_paused and $LineEdit.text.is_valid_float():
		var prg := clampf($LineEdit.text.to_float(),0,audio_barl)
		var prgms := Arfc.get_mstime(prg)
		_seek(prgms)
		current_progress = prgms
		ArView.update(prgms)
		current_progress = prgms
		timet[0] = prgms
		tempot[0] = prg
		$Time.text = TIMESTR % timet
		$Tempo.text = BTSTR % tempot
