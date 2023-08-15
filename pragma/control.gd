extends AudioStreamPlayer
const FMPATH := "res://〈Fumen〉.gd"
const TIMESTR := "%d · %d"
const BTSTR := "%s · %s"

# Button Logics
var _05x:bool = false
func _on_export_button_button_up(): Arfc.export()
func _on_spd_button_button_up():
	if _05x:
		$SpdButton.text = "1x"
		AudioServer.set_playback_speed_scale(1)
		_05x = false
	else:
		$SpdButton.text = "0.5x"
		AudioServer.set_playback_speed_scale(0.5)
		_05x = true
func _on_play_button_toggled(toggled_on:bool): if stream!=null: stream_paused = not toggled_on
func _on_time_button_button_up():
	if stream!=null and stream_paused and $LineEdit.text.is_valid_float():
		var prg := clampi(int($LineEdit.text.to_float()),0,audio_length)
		play( (prg-delta)/1000.0 )
		stream_paused = true
func _on_tempo_button_button_up():
	if stream!=null and stream_paused and $LineEdit.text.is_valid_float():
		var prg := clampf($LineEdit.text.to_float(),0,audio_barl)
		var prgms := Arfc.get_mstime(prg)
		play( (prgms-delta)/1000.0 )
		stream_paused = true


# Initial Works
var audio_length:int = 0
var audio_barl:float = 0
func _enter_tree():
	fmgd_last_update = FileAccess.get_modified_time(FMPATH)
	load(FMPATH).new().fumen()
	Arfc.compile()
	ArView.refresh(self)
	if stream!=null:
		var _time:float = Arfc.get_mstime(0)
		audio_length = int(stream.get_length()*1000)
		audio_barl = Arfc.get_bartime(audio_length)
		@warning_ignore("narrowing_conversion")
		play(_time/1000.0)
		stream_paused = true
	else:
		print("\nPlease Set the Audio Stream before Viewing Your Work.")

# Viewer Updater
var last_audio_time:int = -1
var current_audio_time:int = -1
var delta:float = 0
func _process(_delta) -> void:
	delta = _delta*1000
	current_audio_time = int(get_playback_position()*1000)
	if current_audio_time != last_audio_time:
		@warning_ignore("narrowing_conversion")
		ArView.update(current_audio_time + AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency())
		$Time.text = TIMESTR%[current_audio_time,audio_length]
		$Tempo.text = BTSTR%[Arfc.get_bartime(current_audio_time),audio_barl]
		last_audio_time = current_audio_time
	

# Listener of fumen.gd
var fmgd_current_update:int = 0
var fmgd_last_update:int = 0
func _physics_process(_delta) -> void:
	fmgd_current_update = FileAccess.get_modified_time(FMPATH)
	if fmgd_current_update != fmgd_last_update:
		Arf.clear_Arf()
		load(FMPATH).new().fumen()
		Arfc.compile()
		ArView.refresh(self)
		fmgd_last_update = fmgd_current_update
		print("〈fumen〉.gd Updated in %s" % Time.get_time_string_from_system() )
