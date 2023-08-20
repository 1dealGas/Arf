# Arf Viewer
# This models after the implement of ArPlay in the Game "Aerials".
extends Node
class_name ArView

const _wish := preload("res://pragma/_wish.tscn")
const _hint := preload("res://pragma/_hint.tscn")

static var Camera:Array = []
static var DTime:Array = []
static var has:Array = []
static var Init:int = 0
static var End:int = 0
static var Wish:Array = []
static var Hint:Array = []
static var index_scale:int = 512
static var Windex:Array = []
static var Hindex:Array = []
static var Wgo:Array = []
static var Hgo:Array = []
static var Vecs:Array = []
static var Tints:Array = []
static var Wids:Array = []
static func clear_ArView():
	for obj in Wgo: (obj as Node).queue_free()
	for obj in Hgo: (obj as Node).queue_free()
	Camera.resize(0)
	DTime.resize(0)
	has.resize(0)
	Wish.resize(0)
	Hint.resize(0)
	Windex.resize(0)
	Hindex.resize(0)
	if Wgo.size()>0:
		for go in Wgo: go.queue_free()
		Wgo.resize(0)
	if Hgo.size()>0:
		for go in Hgo: go.queue_free()
		Hgo.resize(0)
	Vecs.resize(0)
	Tints.resize(0)
	Wids.resize(0)
	Init = 0
	End = 0
	index_scale = 0
	last_culled = -1
	last_hgo = -1

static var last_since:Array[int] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
static var last_to:Array[int] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
static var last_base:Array[float] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
static var last_ratio:Array[float] = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
static func ArDTime(nodes:Array=[], progress:int=2, zindex:int=1) -> float:
	if nodes.size()>0:
		var zn = nodes[zindex]
		if (zn) and (zn as Array).size()>1 and progress>=zn[1][0]:
			
			var ls := last_since[zindex]
			if progress>=ls and progress<last_to[zindex]:
				return last_base[zindex] + (progress-ls)*last_ratio[zindex]
			else:
				var znlen := (zn as Array).size()
				var poll_progress:int = zn[0]
				while poll_progress > 2 and progress < zn[poll_progress-1][0]:
					poll_progress -= 1
				var result = false
				while not(poll_progress>znlen or result):
					var p:Array = []
					if poll_progress<znlen: p=zn[poll_progress]
					if p.size()>0 and progress>=zn[poll_progress-1][0] and progress<p[0]:
						last_to[zindex] = p[0]
						p = zn[poll_progress-1]
						var sincems:int = p[0]
						var base:float = p[1]
						var ratio:float = p[2]
						result = base + (progress-sincems)*ratio
						last_since[zindex] = sincems
						last_base[zindex] = base
						last_ratio[zindex] = ratio
						zn[0] = poll_progress
					elif poll_progress==znlen:
						p = zn[poll_progress-1]
						var sincems:int = p[0]
						var base:float = p[1]
						var ratio:float = p[2]
						result = base + (progress-sincems)*ratio
						last_since[zindex] = sincems
						last_to[zindex] = 512000
						last_base[zindex] = base
						last_ratio[zindex] = ratio
						zn[0] = poll_progress
					else: poll_progress+=1
				if result: return result
				else: return 2
		else: return progress
	else:
		last_since.fill(0)
		last_to.fill(0)
		last_base.fill(0)
		last_ratio.fill(0)
		return -1

static func ArCamera(nodes:Array=[], progress:int=-1, zindex:int=1) -> Array:
	if progress>-1:
		var xscale:float = 1
		var yscale:float = 1
		var rotrad:float = 0
		var xdelta:float = 0
		var ydelta:float = 0
		zindex -= 1
		if nodes[zindex]:
			var zn:Array = nodes[zindex]
			if zn[0] and (zn[0] as Array).size()>1 and progress>=zn[0][1][0]:
				var znt:Array = zn[0]
				var zntlen:int = znt.size()
				if progress >= znt[-1][0]:
					xscale = znt[-1][1]
				else:
					var poll_progress:int = znt[0]
					var type_interpolated := false
					while poll_progress > 2 and progress < znt[poll_progress-1][0]:
						poll_progress -= 1
					while poll_progress != zntlen and not type_interpolated:
						if znt[poll_progress-1][0] <= progress and znt[poll_progress][0] > progress:
							var t0:float = znt[poll_progress-1][0]
							var v0:float = znt[poll_progress-1][1]
							var etype:int = znt[poll_progress-1][2]
							var dt:float = znt[poll_progress][0] - t0
							var dv:float = znt[poll_progress][1] - v0
							var ratio:float = (progress-t0)/dt
							if etype==0: xscale = v0 + dv*ratio
							else: xscale = v0 + dv*Arf.EASE(ratio, etype)
							type_interpolated = true
							znt[0] = poll_progress
						else: poll_progress +=1
			if zn[1] and (zn[1] as Array).size()>1 and progress>=zn[1][1][0]:
				var znt:Array = zn[1]
				var zntlen:int = znt.size()
				if progress >= znt[-1][0]:
					yscale = znt[-1][1]
				else:
					var poll_progress:int = znt[0]
					var type_interpolated := false
					while poll_progress > 2 and progress < znt[poll_progress-1][0]:
						poll_progress -= 1
					while poll_progress != zntlen and not type_interpolated:
						if znt[poll_progress-1][0] <= progress and znt[poll_progress][0] > progress:
							var t0:float = znt[poll_progress-1][0]
							var v0:float = znt[poll_progress-1][1]
							var etype:int = znt[poll_progress-1][2]
							var dt:float = znt[poll_progress][0] - t0
							var dv:float = znt[poll_progress][1] - v0
							var ratio:float = (progress-t0)/dt
							if etype==0: yscale = v0 + dv*ratio
							else: yscale = v0 + dv*Arf.EASE(ratio, etype)
							type_interpolated = true
							znt[0] = poll_progress
						else: poll_progress +=1
			if zn[2] and (zn[2] as Array).size()>1 and progress>=zn[2][1][0]:
				var znt:Array = zn[2]
				var zntlen:int = znt.size()
				if progress >= znt[-1][0]:
					rotrad = znt[-1][1]
				else:
					var poll_progress:int = znt[0]
					var type_interpolated := false
					while poll_progress > 2 and progress < znt[poll_progress-1][0]:
						poll_progress -= 1
					while poll_progress != zntlen and not type_interpolated:
						if znt[poll_progress-1][0] <= progress and znt[poll_progress][0] > progress:
							var t0:float = znt[poll_progress-1][0]
							var v0:float = znt[poll_progress-1][1]
							var etype:int = znt[poll_progress-1][2]
							var dt:float = znt[poll_progress][0] - t0
							var dv:float = znt[poll_progress][1] - v0
							var ratio:float = (progress-t0)/dt
							if etype==0: rotrad = v0 + dv*ratio
							else: rotrad = v0 + dv*Arf.EASE(ratio, etype)
							type_interpolated = true
							znt[0] = poll_progress
						else: poll_progress +=1
			if zn[3] and (zn[3] as Array).size()>1 and progress>=zn[3][1][0]:
				var znt:Array = zn[3]
				var zntlen:int = znt.size()
				if progress >= znt[-1][0]:
					xdelta = znt[-1][1]
				else:
					var poll_progress:int = znt[0]
					var type_interpolated := false
					while poll_progress > 2 and progress < znt[poll_progress-1][0]:
						poll_progress -= 1
					while poll_progress != zntlen and not type_interpolated:
						if znt[poll_progress-1][0] <= progress and znt[poll_progress][0] > progress:
							var t0:float = znt[poll_progress-1][0]
							var v0:float = znt[poll_progress-1][1]
							var etype:int = znt[poll_progress-1][2]
							var dt:float = znt[poll_progress][0] - t0
							var dv:float = znt[poll_progress][1] - v0
							var ratio:float = (progress-t0)/dt
							if etype==0: xdelta = v0 + dv*ratio
							else: xdelta = v0 + dv*Arf.EASE(ratio, etype)
							type_interpolated = true
							znt[0] = poll_progress
						else: poll_progress +=1
			if zn[4] and (zn[4] as Array).size()>1 and progress>=zn[4][1][0]:
				var znt:Array = zn[4]
				var zntlen:int = znt.size()
				if progress >= znt[-1][0]:
					ydelta = znt[-1][1]
				else:
					var poll_progress:int = znt[0]
					var type_interpolated := false
					while poll_progress > 2 and progress < znt[poll_progress-1][0]:
						poll_progress -= 1
					while poll_progress != zntlen and not type_interpolated:
						if znt[poll_progress-1][0] <= progress and znt[poll_progress][0] > progress:
							var t0:float = znt[poll_progress-1][0]
							var v0:float = znt[poll_progress-1][1]
							var etype:int = znt[poll_progress-1][2]
							var dt:float = znt[poll_progress][0] - t0
							var dv:float = znt[poll_progress][1] - v0
							var ratio:float = (progress-t0)/dt
							if etype==0: ydelta = v0 + dv*ratio
							else: ydelta = v0 + dv*Arf.EASE(ratio, etype)
							type_interpolated = true
							znt[0] = poll_progress
						else: poll_progress +=1
		return [xscale,yscale,rotrad,xdelta,ydelta]
	else:
		for zi in range(0,16):
			var zn = nodes[zi]
			if zn is Array:
				if zn[0] is Array: zn[0][0] = 2
				if zn[1] is Array: zn[1][0] = 2
				if zn[2] is Array: zn[2][0] = 2
				if zn[3] is Array: zn[3][0] = 2
				if zn[4] is Array: zn[4][0] = 2
	return []

static func refresh(arfroot:Node):
	
	ArView.clear_ArView()
	if not Arfc.compiled: return ArView
	
	var fm := Arfc.ArfResult.duplicate(true)
	var traits:Dictionary = fm.Info.Traits
	if "Camera" in traits:
		var cam_prim:Array = traits.Camera
		Camera.resize(16)
		Camera.fill(false)
		for i in range(0,16):
			if cam_prim[i]: Camera[i] = cam_prim[i]
	if "DTime" in traits:
		var dt_prim:Array = traits.DTime
		DTime.resize(16)
		DTime.fill(false)
		for i in range(0,16):
			if dt_prim[i]: DTime[i] = dt_prim[i]
		ArView.ArDTime()
		has.resize(16)
		has.fill(false)
		var w:Array = fm.Wish
		var h:Array = fm.Hint
		var zg:int = 0
		for g in range(0,w.size()):
			zg = int(w[g][1]) - 1
			has[zg] = true
		for hi in range(0,h.size()):
			zg = int(h[hi][3]) - 1
			has[zg] = true
	Init = fm.Info.Init
	End = fm.Info.End
	Wish = fm.Wish
	Hint = fm.Hint
	index_scale = fm.Index.Scale
	Windex = fm.Index.Wish
	Hindex = fm.Index.Hint
	Wgo = fm.Index.Wgo
	Hgo = fm.Index.Hgo
	Vecs = fm.Index.Vecs
	Tints = fm.Index.Tints
	if Camera.size()>0:
		for hint in Hint:
			var posx:float = hint[0]
			var posy:float = hint[1]
			var camarr := ArView.ArCamera(Camera,hint[2],hint[3])
			var xscale:float = camarr[0]
			var yscale:float = camarr[1]
			var rotrad:float = camarr[2]
			var xdelta:float = camarr[3]
			var ydelta:float = camarr[4]
			if rotrad > -0.01 and rotrad < 0.01:
				posx = 8 + (posx - 8) * xscale + xdelta
				posy = 4 + (posy - 4) * yscale + ydelta
			else:
				var dx:float = (posx - 8) * xscale
				var dy:float = (posy - 8) * yscale
				posx = 8 + dx*cos(rotrad) - dy*sin(rotrad) + xdelta
				posy = 4 + dx*sin(rotrad) + dy*cos(rotrad) + ydelta
			hint[0] = posx * 112.5 - 92.5
			hint[1] = 867.5 - posy * 112.5
			hint[3] = 0
		ArView.ArCamera(Camera)
	else:
		for hint in Hint:
			hint[0] = hint[0] * 112.5 - 92.5
			hint[1] = 867.5 - hint[1]*112.5
			hint[3] = 0
	Wids.resize(Wgo.size())
	for i in range(0,Vecs.size()):
		Vecs[i] = Vector3()
	for i in range(0,Wgo.size()):
		var new_wish = _wish.instantiate()
		(new_wish as CanvasItem).visible = false
		Wgo[i] = new_wish
		arfroot.add_child(new_wish)
	for i in range(0,Hgo.size()):
		var new_hint = _hint.instantiate()
		(new_hint as CanvasItem).visible = false
		Hgo[i] = new_hint
		arfroot.add_child(new_hint)
	return ArView

static var last_culled:int = -1
static var last_hgo:int = -1
static var current_interpolated := Vector4()
static var current_wid := ""
static func update(progress:int) -> void:
	if not Arfc.compiled: return
	if progress < Init or progress > End:
		for go in Wgo: go.visible = false
		for go in Hgo: go.visible = false
		last_culled = 0
		last_hgo = 0
		return
	if progress < 2: progress = 2
	var current_index_group:int = 0
	@warning_ignore("integer_division")
	current_index_group = int(progress/index_scale)
	if current_index_group < 0: current_index_group = 0
	var ip_index:int = 0
	var culled_index:int = 0
	if DTime.size()>0:
		var zip1:int = 1
		for zi in range(0,16):
			if has[zi]:
				zip1 = zi+2
				var dtime := ArView.ArDTime(DTime, progress, zi)
				if dtime < 2: dtime = 2
				var dgroup:int = int(dtime/index_scale)
				if dgroup < 0: dgroup = 0
				if (Windex.size() > dgroup+1) and Windex[dgroup].size() > 0:
					var group_id:int = 0
					var current_wish:Array = []
					var current_x0:float = 0
					var current_y0:float = 0
					var current_t0:float = 0
					var current_dx:float = 0
					var current_dy:float = 0
					var current_dt:float = 0
					var current_type:int = 0
					var interpolate_ratio:float = 0
					var current_indexes:Array = Windex[dgroup]
					for i in range(0,current_indexes.size()):
						group_id = current_indexes[i] - 1
						current_wish = Wish[group_id]
						var current_wish_len := current_wish.size() - 1  #Debug Signal "WID" inserted.
						var wish_interpolated := false
						if current_wish_len > 3 and current_wish[1] >= zi+1 and current_wish[1] < zip1:
							var poll_progress:int = current_wish[0]
							while poll_progress > 3 and current_wish[poll_progress-1][2] > dtime: poll_progress-=1
							while poll_progress != current_wish_len and not wish_interpolated:
								if current_wish[poll_progress-1][2] <= dtime and current_wish[poll_progress][2] > dtime:
									current_x0 = current_wish[poll_progress-1][0]
									current_y0 = current_wish[poll_progress-1][1]
									current_t0 = current_wish[poll_progress-1][2]
									current_type = current_wish[poll_progress-1][3]
									current_dx = current_wish[poll_progress][0] - current_x0
									current_dy = current_wish[poll_progress][1] - current_y0
									current_dt = current_wish[poll_progress][2] - current_t0
									interpolate_ratio = (dtime-current_t0) / current_dt
									if current_type == 0:
										current_interpolated.x = current_x0 + current_dx*interpolate_ratio
										current_interpolated.y = current_y0 + current_dy*interpolate_ratio
									else:
										var typex:int = 0
										var typey:int = 0
										@warning_ignore("integer_division")
										typex = current_type/10
										typey = current_type%10
										current_interpolated.x = current_x0 + current_dx*Arf.EASE(interpolate_ratio, typex)
										current_interpolated.y = current_y0 + current_dy*Arf.EASE(interpolate_ratio, typey)
									current_interpolated.z = current_wish[1]
									current_wid = current_wish[-1]
									if poll_progress == 3:
										if interpolate_ratio <= 0.237: current_interpolated.w = 2 + interpolate_ratio
										else: current_interpolated.w = 0
									elif poll_progress == current_wish_len-1 and interpolate_ratio >= 0.763:
										current_interpolated.w = 0
									wish_interpolated = true
									current_wish[0] = poll_progress
								else: poll_progress += 1
						if wish_interpolated:
							if ip_index == 0:
								Vecs[0].x = current_interpolated.x
								Vecs[0].y = current_interpolated.y
								Vecs[0].z = current_interpolated.z
								Tints[0] = current_interpolated.w
								Wids[0] = current_wid
								ip_index = 1
							else:
								var not_repeated := true
								var dz:int = 0
								for _i in range(0,ip_index+1):
									dz = int(Vecs[_i].z) - int(current_interpolated.z)
									if dz==0:
										var dx:float = Vecs[_i].x - current_interpolated.x
										var dy:float = Vecs[_i].y - current_interpolated.y
										if dx<0.0001 and dy<0.0001 and dx>-0.0001 and dy>-0.0001:
											Tints[_i] = 0
											not_repeated = false
											break
								if not_repeated:
									Vecs[ip_index].x = current_interpolated.x
									Vecs[ip_index].y = current_interpolated.y
									Vecs[ip_index].z = current_interpolated.z
									Tints[ip_index] = current_interpolated.w
									Wids[ip_index] = current_wid
									ip_index += 1
	else:
		if (Windex.size() > current_index_group+1) and Windex[current_index_group].size() > 0:
			var group_id:int = 0
			var current_wish:Array = []
			var current_x0:float = 0
			var current_y0:float = 0
			var current_t0:float = 0
			var current_dx:float = 0
			var current_dy:float = 0
			var current_dt:float = 0
			var current_type:int = 0
			var interpolate_ratio:float = 0
			var current_indexes:Array = Windex[current_index_group]
			for i in range(0,current_indexes.size()):
				group_id = current_indexes[i] - 1
				current_wish = Wish[group_id]
				var current_wish_len := current_wish.size() - 1
				var wish_interpolated := false
				if current_wish_len > 3:
					var poll_progress:int = current_wish[0]
					while poll_progress > 3 and current_wish[poll_progress-1][2] > progress: poll_progress -= 1
					while poll_progress != current_wish_len and not wish_interpolated:
						if current_wish[poll_progress-1][2] <= progress and current_wish[poll_progress][2] > progress:
							current_x0 = current_wish[poll_progress-1][0]
							current_y0 = current_wish[poll_progress-1][1]
							current_t0 = current_wish[poll_progress-1][2]
							current_type = current_wish[poll_progress-1][3]
							current_dx = current_wish[poll_progress][0] - current_x0
							current_dy = current_wish[poll_progress][1] - current_y0
							current_dt = current_wish[poll_progress][2] - current_t0
							interpolate_ratio = (progress-current_t0) / current_dt
							if current_type == 0:
								current_interpolated.x = current_x0 + current_dx*interpolate_ratio
								current_interpolated.y = current_y0 + current_dy*interpolate_ratio
							else:
								var typex:int = 0
								var typey:int = 0
								@warning_ignore("integer_division")
								typex = current_type/10
								typey = current_type%10
								current_interpolated.x = current_x0 + current_dx*Arf.EASE(interpolate_ratio, typex)
								current_interpolated.y = current_y0 + current_dy*Arf.EASE(interpolate_ratio, typey)
							current_interpolated.z = current_wish[1]
							current_wid = current_wish[-1]
							if poll_progress == 3:
								if interpolate_ratio <= 0.237:
									current_interpolated.w = 2 + interpolate_ratio
								else:
									current_interpolated.w = 0
							elif poll_progress == current_wish_len-1 and interpolate_ratio >= 0.763:
								current_interpolated.w = -2 - interpolate_ratio
							else:
								current_interpolated.w = 0
							wish_interpolated = true
							current_wish[0] = poll_progress
						else: poll_progress += 1
				if wish_interpolated:
					if ip_index == 0:
						Vecs[0].x = current_interpolated.x
						Vecs[0].y = current_interpolated.y
						Vecs[0].z = current_interpolated.z
						Tints[0] = current_interpolated.w
						Wids[0] = current_wid
						ip_index = 1
					else:
						var not_repeated := true
						var dz:int = 0
						for _i in range(0,ip_index):
							dz = int(Vecs[_i].z) - int(current_interpolated.z)
							if dz==0:
								var dx:float = Vecs[_i].x - current_interpolated.x
								var dy:float = Vecs[_i].y - current_interpolated.y
								if dx<0.0001 and dy<0.0001 and dx>-0.0001 and dy>-0.0001:
									Tints[_i] = 0
									not_repeated = false
									break
						if not_repeated:
							Vecs[ip_index].x = current_interpolated.x
							Vecs[ip_index].y = current_interpolated.y
							Vecs[ip_index].z = current_interpolated.z
							Tints[ip_index] = current_interpolated.w
							Wids[ip_index] = current_wid
							ip_index += 1
	for i in range(0,ip_index):
		var pos:Vector3 = Vecs[i]
		var ctint:float = Tints[i]
		var camarr:Array = [1,1,0,0,0]
		if Camera.size()>0:
			@warning_ignore("narrowing_conversion")
			camarr = ArCamera(Camera, progress, int(pos.z))
		var xscale:float = camarr[0]
		var yscale:float = camarr[1]
		var rotrad:float = camarr[2]
		var xdelta:float = camarr[3]
		var ydelta:float = camarr[4]
		if Camera.size()>0:
			if rotrad > -0.01 and rotrad < 0.01:
				pos.x = 8 + (pos.x-8) * xscale + xdelta
				pos.y = 4 + (pos.y-4) * yscale + ydelta
			else:
				var dx:float = (pos.x-8) * xscale
				var dy:float = (pos.y-4) * yscale
				pos.x = 8 + dx*cos(rotrad) - dy*sin(rotrad) + xdelta
				pos.y = 4 + dx*sin(rotrad) + dy*sin(rotrad) + ydelta
		pos.x = pos.x * 112.5
		pos.y = 960 - pos.y * 112.5
		if pos.x >= 66 and pos.x <= 1734 and pos.y >= 66 and pos.y <= 1014:
			pos.z = pos.z - int(pos.z)
			var currenthash_wish = Wgo[culled_index]
			var tintw:float = 1
			var expand_wish:float = 1
			if ctint >= 2:
				tintw = ctint - 1.999
				tintw = 1 - tintw / 0.237
				expand_wish = 1 + tintw*tintw/2
				tintw = 1 - tintw*tintw*tintw
			elif ctint <= -2:
				tintw = 3 + ctint
				tintw /= 0.237
				tintw = tintw*tintw*tintw
			currenthash_wish.ar_update(pos, tintw, expand_wish)
			currenthash_wish.wid(Wids[i])
			culled_index += 1
	if culled_index < last_culled:
		for i in range(culled_index, last_culled):
			Wgo[i].visible = false
	last_culled = culled_index
	var target:Array = []
	var chid:int = 0
	var chint:Array = []
	var dt:float = 0
	var hgo_index:int = 0
	for g in [-1,0,1]:
		var _t:int = current_index_group + g
		if _t > -1 and _t < Hindex.size(): target = Hindex[_t]
		if target.size() > 0:
			for _i in range(0,target.size()):
				chid = target[_i] - 1
				chint = Hint[chid]
				dt = progress - chint[2]
				var thisgo = false
				if dt <= 137 and dt >= 0:
					thisgo = Hgo[hgo_index]
					thisgo.position.x = chint[0]
					thisgo.position.y = chint[1]
					thisgo.z_index = -71
					thisgo.self_modulate.r = 0.73
					thisgo.self_modulate.g = 0.73
					thisgo.self_modulate.b = 0.73
					if hgo_index > last_hgo: thisgo.visible = true
					hgo_index += 1
				elif dt < 0 and dt >= -510:
					thisgo = Hgo[hgo_index]
					thisgo.position.x = chint[0]
					thisgo.position.y = chint[1]
					thisgo.z_index = -73
					thisgo.self_modulate.r = 0.2037
					thisgo.self_modulate.g = 0.2037
					thisgo.self_modulate.b = 0.2037
					if hgo_index > last_hgo: thisgo.visible = true
					hgo_index += 1
	if hgo_index - 1 < last_hgo:
		for i in range(hgo_index, last_hgo+1):
			Hgo[i].visible = false
	last_hgo = hgo_index - 1
