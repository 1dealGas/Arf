# Arf Compiler,Exporter
extends Arf
class_name Arfc

class B2MNode:
	var init_bartime:float = 0
	var base_ms:float = 0
	var BPM:float = 0
	func _init(arg1:float,arg2:float):
		init_bartime = arg1
		BPM = arg2
class DTNode:
	var init_ms:int = 0
	var base:float = 0
	var scale:float = 1
	func _init(init_bartime:float,value:float):
		init_ms = Arfc.get_mstime(init_bartime)
		scale = value
	func _to_string():
		return "[%s,%s,%s]" % [init_ms,base,scale]
	func _to_arr() -> Array:
		return [init_ms,base,scale]

# Sorters.
static var a3:Array = []
static var b3:Array = []
static func B2MSorter(a:B2MNode,b:B2MNode) -> bool:
	assert(a.init_bartime!=b.init_bartime,Arf.ub%"BPM")
	if a.init_bartime < b.init_bartime: return true
	else: return false
static func DTSorter(a:DTNode,b:DTNode) -> bool:
	assert(a.init_ms!=b.init_ms,Arf.ub%"DTime")
	if a.init_ms < b.init_ms: return true
	else: return false
static func WGArraySorter(a:Array,b:Array) -> bool:
	a3 = a[2]
	b3 = b[2]
	assert( (a3 is Array and b3 is Array) and a3.size()==4 and b3.size()==4)
	# [x,y,t,easetype]
	if a3[2] <= b3[2]:
		if a3[1] <= b3[1]:
			if a3[0] <= b3[0]:
				assert(a[1] is float and b[1] is float)
				if a[1] <= b[1]: return true
				else: return false
			else: return false
		else: return false
	else: return false
static func HintSorter(a:SingleHint,b:SingleHint) -> bool:
	assert( not(a.bartime==b.bartime and a.x==b.x and a.y==b.y and a.zindex==b.zindex), "Completely Superposed Hints are Prohibited.")
	if a.bartime < b.bartime:
		if a.y <= b.y:
			if a.x <= b.x:
				if a.zindex <= b.zindex: return true
				else: return false
			else: return false
		else: return false
	else: return false



static var ArfResult:Dictionary
static func clear_Arfc() -> void:
	compiled = false
	has_DTime = false
	b2mList.resize(0)
	dtList.resize(0)
	ArfResult = {
		Aerials = "Arf",
		Info = {
			Traits = {},
			Madeby = Arf._Madeby,
			Init = 0,
			End = 0,
			Hints = 0
		},
		Wish = [],  # Contains Arrays like [3,Zindex,WishNode,WishNode,···]
		Hint = [],  # Contains SingleHint Objects.
		Index = {
			Scale = 512,
			Wish = [],
			Hint = [],
			Wgo = [],
			Hgo = [],
			Ago = [],
			Vecs = [],
			Tints = []
		}
	}

# Bartime -> mstime to fill all "time" in ArfResult.
const valuelimit := "DTime(mstime) value is limited in [0,512000]."
static var b2mList:Array[B2MNode]
static func make_b2mList() -> void:
	b2mList.resize(0)
	var bpmsize:= BPMList.size()
	for i in range(0,bpmsize,2):
		b2mList.append( B2MNode.new(BPMList[i],BPMList[i+1]) )
	b2mList.sort_custom(Arfc.B2MSorter)
	b2mList[0].base_ms = _Offset
	if bpmsize>2:
		for i in range(1,b2mList.size()):
			b2mList[i].base_ms = b2mList[i-1].base_ms + (240000.0/b2mList[i-1].BPM)*(b2mList[i].init_bartime-b2mList[i-1].init_bartime)
static func get_mstime(bartime:float) -> int:
	assert( b2mList.size()!=0 )
	var mstresult:float
	if bartime>=b2mList[-1].init_bartime:
		mstresult = b2mList[-1].base_ms + 240000.0/b2mList[-1].BPM*(bartime-b2mList[-1].init_bartime)
		assert(mstresult>=0 and mstresult<=512000, valuelimit)
		return int( mstresult )
	else:
		for i in range(0,b2mList.size()-1):
			if bartime>=b2mList[i].init_bartime and bartime<b2mList[i+1].init_bartime:
				mstresult = b2mList[i].base_ms + 240000.0/b2mList[i].BPM*(bartime-b2mList[i].init_bartime)
				assert(mstresult>=0 and mstresult<=512000, valuelimit)
				return int( mstresult )
		return 0
static func get_bartime(mstime:int) -> float:
	assert( b2mList.size()!=0 )
	if mstime>=b2mList[-1].base_ms:
		return b2mList[-1].init_bartime + (mstime-b2mList[-1].base_ms)*b2mList[-1].BPM/240000
	else:
		for i in range(0,b2mList.size()-1):
			if mstime>=b2mList[i].base_ms and mstime<b2mList[i+1].base_ms:
				return b2mList[i].init_bartime + (mstime-b2mList[i].base_ms)*b2mList[i].BPM/240000
		return 0

#Arf.Z
	#for i in range(0,16):
		#Z[i] = {
			#DTime = false,  #process_dtime(DTime:Array[float])
			#XScale = false,  #camnode_to_str(camnode:CamNode)
			#YScale = false,
			#Rotrad = false,
			#XDelta = false,
			#YDelta = false
		#}
# mstime -> DTime to modify all WishNodes' "time"s.
# DTime List is also compiled in ArfResult.Info.Traits for Runtime Usage.
static var has_DTime := false
static func detect_DTime() -> bool:
	has_DTime = false
	for i in range(0,16):
		if Arf.Z[i].DTime : has_DTime = true
	return has_DTime
#class DTNode:
	#var init_ms:int = 0
	#var base:float = 0
	#var scale:float = 1
	#func _init(init_bartime:float,value:float):
		#init_ms = Arfc.get_mstime(init_bartime)
		#scale = value
static var dtList:Array
static func make_dtList() -> void:
	assert(has_DTime)
	dtList.resize(16)
	dtList.fill(false)
	for i in range(0,16):
		if Arf.Z[i].DTime:
			var _original:Array[float] = Arf.Z[i].DTime
			var _new:Array[DTNode] = []
			var osize:= _original.size()
			for ii in range(0,osize,2):
				_new.append( DTNode.new(_original[ii],_original[ii+1]) )
			_new.sort_custom(Arfc.DTSorter)
			_new[0].base = _new[0].init_ms
			if osize>2:
				for ii in range(1,_new.size()):
					_new[ii].base = _new[ii-1].base + _new[ii-1].scale*(_new[ii].init_ms - _new[ii-1].init_ms)
			dtList[i] = _new
static func get_dtime(ms:int,zindex:float) -> float:
	assert(zindex>0 and zindex<17)
	assert(dtList.size()>0)  # Which indicates that dtList has been made correctly.
	assert(ms>=0 and ms<=512000, valuelimit)
	var _zindex := int(zindex)-1
	var dtresult:float
	if dtList[_zindex]:
		var _dtl:Array[DTNode] = dtList[_zindex]
		if ms<_dtl[0].init_ms:
			return ms
		elif ms>=_dtl[-1].init_ms:
			dtresult = _dtl[-1].base + _dtl[-1].scale * (ms - _dtl[-1].init_ms)
			assert(dtresult>=0 and dtresult<=512000, valuelimit)
			return dtresult
		else:
			for i in range(0,_dtl.size()-1):
				if ms>=_dtl[i].init_ms and ms<_dtl[i+1].init_ms:
					dtresult = _dtl[i].base + _dtl[i].scale*(ms - _dtl[i].init_ms)
					assert(dtresult>=0 and dtresult<=512000, valuelimit)
					return dtresult
			return ms
	else:
		return ms

static func detect_camera() -> bool:
	var flag := false
	var arfzi:Dictionary = {}
	for i in range(0,16):
		arfzi = Arf.Z[i]
		if arfzi.XScale or arfzi.YScale or arfzi.Rotrad or arfzi.XDelta or arfzi.YDelta :
			flag = true
	return flag


# When using _to_arr(), all bartime will be converted into mstime automatically,
# WishNodes' mstimes must be converted into DTime ###manually### .

# Sort:
# WishNode, Camera Arrays -> Arf
# BPMList, DTime Array, Arf.Wish, Arf.Hint -> Arfc

# Time Transformation:
# Bartime -> mstime: Automatic, when calling _to_arr()
# mstime -> DTime: Manual.
static var compiled := false
static func compile() -> void: #ArfResult doesn't contain custom objects.
	assert(Arf.Wish.size()>0, "Please Add at least 1 Wish in \"fumen.gd\".")
	assert(Arf.Hint.size()>0, "Please Add at least 1 Hint in \"fumen.gd\".")
	
	clear_Arfc()
	make_b2mList()
	
	# Compile Hints
	# 1.sort
	Arf.Hint.sort_custom(Arfc.HintSorter)
	# 2.do lots of _to_arr()
	var _h:Array = []
	var _i:int = 0
	_h.resize(Arf.Hint.size())
	for singlehint in Arf.Hint:
		_h[_i] = singlehint._to_arr()
		_i += 1
	# 3.update ArfResult.Info.Hints
	ArfResult.Hint = _h
	ArfResult.Info.Hints = _i
	
	# Compile WishGroups
	# 1.interpolate BPM intervals
	if b2mList.size()>1:
		for wishgroup in Arf.Wish:
			for bnode in Arfc.b2mList:
				if bnode.init_bartime>0:
					wishgroup.try_interpolate(bnode.init_bartime)
	# 2.do lots of _to_arr()
	var _g:Array[Array] = []
	_i = 0
	_g.resize(Arf.Wish.size())
	for wishgroup in Arf.Wish:
		_g[_i] = wishgroup._to_arr()
		_i += 1


	# Compile DTime-Related
	# 1.detect & make_dtList
	# 2.import dtList to ArfResult.Info.Traits.DTime
	# 3.modify ArfResult.Wish, do assertations
	detect_DTime()
	if has_DTime:
		make_dtList()
		var _d = []
		_d.resize(16)
		_d.fill(false)
		_i = 0
		for stuff in dtList:
			if stuff:
				_d[_i] = [2]
				for dtnode in stuff: _d[_i].append( (dtnode as DTNode)._to_arr() )
			_i += 1
		ArfResult.Info.Traits.DTime = _d
		
		_i = 0
		for wgarray in _g:
			_i = wgarray[1]  # Now _i is the ZIndex of current WishGroupArray.
			#for stuff in wgarray:
				#if stuff is Array:
					#assert(stuff.size()==4)  # [x,y,t,easetype]
					#stuff[2] = get_dtime(int(stuff[2]), _i)
			assert((wgarray as Array).size()>2)
			for i in range(2,(wgarray as Array).size()-1):
				assert(wgarray[i].size()==4)  # [x,y,t,easetype]
				wgarray[i][2] = get_dtime(int(wgarray[i][2]), _i)
				if i>2: assert(wgarray[i][2] > wgarray[i-1][2], "Inserting WishNode in Flashback Part is Prohibited.")

	# Sort ArfResult.Wish
	_g.sort_custom(Arfc.WGArraySorter)
	ArfResult.Wish = _g
	
	# Compile Info(Init,End,Traits.Camera)
	var timemin:int = 512000
	var timemax:int = 0
	for harray in ArfResult.Hint:
		#[x,y,mstime,zindex]
		if harray[2]>timemax: timemax = harray[2]
		if harray[2]<timemin: timemin = harray[2]
	var wgtime:int = 0
	var before:Array = []
	var after:Array = []
	for wgarray in ArfResult.Wish:
		for i in range(2,(wgarray as Array).size()-1):
			wgtime = wgarray[i][2]
			if wgtime>timemax: timemax = wgtime
			if wgtime<timemin: timemin = wgtime
			if i>2:
				before = wgarray[i-1]
				after = wgarray[i]
				if after[0]==before[0] and after[1]==before[1]: before[3]=0
			
			
	if timemin>512:
		ArfResult.Info.Init = int(timemin) - 512
	else:
		ArfResult.Info.Init = int(timemin)
	ArfResult.Info.End = int(timemax) + 512
	
	if detect_camera():
		var camall:Array = []
		var camloc
		camall.resize(16)
		camall.fill(false)
		for i in range(0,16):
			camloc = Arf.Z[i]
			if camloc.XScale or camloc.YScale or camloc.Rotrad or camloc.XDelta or camloc.YDelta:
				camall[i] = [false,false,false,false,false]
			if Arf.Z[i].XScale:
				camloc = Arf.Z[i].XScale
				camall[i][0] = [2]
				for camnode in camloc:
					camall[i][0].append( (camnode as Arf.CamNode)._to_arr() )
			if Arf.Z[i].YScale:
				camloc = Arf.Z[i].YScale
				camall[i][1] = [2]
				for camnode in camloc:
					camall[i][1].append( (camnode as Arf.CamNode)._to_arr() )
			if Arf.Z[i].Rotrad:
				camloc = Arf.Z[i].Rotrad
				camall[i][2] = [2]
				for camnode in camloc:
					camall[i][2].append( (camnode as Arf.CamNode)._to_arr() )
			if Arf.Z[i].XDelta:
				camloc = Arf.Z[i].XDelta
				camall[i][3] = [2]
				for camnode in camloc:
					camall[i][3].append( (camnode as Arf.CamNode)._to_arr() )
			if Arf.Z[i].YDelta:
				camloc = Arf.Z[i].YDelta
				camall[i][4] = [2]
				for camnode in camloc:
					camall[i][4].append( (camnode as Arf.CamNode)._to_arr() )
		ArfResult.Info.Traits.Camera = camall

	# Compile Index
	# 1.calculate the amount of index groups
	# Case: 6000 -> 6000/512=11 -> Size:12
	var widx:Array[Array] = []
	var hidx:Array[Array] = []
	@warning_ignore("integer_division")
	var idxsize = (int(timemax)+512)/512 + 1
	widx.resize(idxsize)
	hidx.resize(idxsize)
	for i in range(0,idxsize):
		widx[i] = []
		hidx[i] = []
	# 2.put WishGroup(s) and Hint(s) in
	for i in range(0,ArfResult.Hint.size()):
		var hg = ArfResult.Hint[i][2]
		@warning_ignore("integer_division")
		hidx[ int(hg)/512 ].append(i+1)
	for i in range(0,ArfResult.Wish.size()):
		assert((ArfResult.Wish[i] as Array).size()>3)
		@warning_ignore("integer_division")
		var init_group := int(ArfResult.Wish[i][2][2])/512
		@warning_ignore("integer_division")
		var end_group := int(ArfResult.Wish[i][-2][2])/512
		if init_group==end_group:
			widx[init_group].append(i+1)
		else:
			for j in range(init_group,end_group+1):
				widx[j].append(i+1)
	ArfResult.Index.Wish = widx
	ArfResult.Index.Hint = hidx
	# 3.calculate the size of other pools
	var _1size:int = 0
	for ig in widx:
		if ig.size()>_1size: _1size = ig.size()
	var _3size:int = 0
	if hidx.size()==0: pass
	elif hidx.size()==1: _3size = hidx[0].size()
	elif hidx.size()==2: _3size = hidx[0].size() + hidx[1].size()
	else:
		var sizeloc:int=0
		for i in range(1,hidx.size()-1):
			sizeloc = hidx[i-1].size() + hidx[i].size() + hidx[i+1].size()
			if sizeloc>_3size: _3size = sizeloc
	
	(ArfResult.Index.Wgo as Array).resize(_1size)
	(ArfResult.Index.Wgo as Array).fill(0)
	(ArfResult.Index.Hgo as Array).resize(_3size)
	(ArfResult.Index.Hgo as Array).fill(0)
	(ArfResult.Index.Ago as Array).resize(_3size)
	(ArfResult.Index.Ago as Array).fill(0)
	(ArfResult.Index.Vecs as Array).resize(_1size)
	(ArfResult.Index.Vecs as Array).fill("t()")
	(ArfResult.Index.Tints as Array).resize(_1size)
	(ArfResult.Index.Tints as Array).fill(0)
	
	compiled = true

const path := "user://export.ar"
const luahead := "local t,v,e=vmath.vector3,vmath.vector4,{} return "
static func size3(arr:Array) -> String:
	assert(arr.size()==3)
	return "t(%s,%s,%s)" % [Arf.num(arr[0]),Arf.num(arr[1]),Arf.num(arr[2])]
static func size4(arr:Array) -> String:
	assert(arr.size()==4)
	return "v(%s,%s,%s,%s)" % [Arf.num(arr[0]),Arf.num(arr[1]),Arf.num(arr[2]),Arf.num(arr[3])]
static func export() -> void:
	if not compiled: Arfc.compile()
	var exported:Dictionary = ArfResult.duplicate(true)
	# Remove wid Signal
	# use Arf.num(),size3(),size4() to convert all Numbers into String
	for wgarray in exported.Wish:
		(wgarray as Array).pop_back()
		assert((wgarray as Array).size()>2)
		wgarray[1] = Arf.num(wgarray[1])
		for i in range(2,(wgarray as Array).size()):
			wgarray[i] = Arfc.size4(wgarray[i])
	exported.Info.Init = Arf.num(exported.Info.Init)
	exported.Info.End = Arf.num(exported.Info.End)
	if "DTime" in exported.Info.Traits:
		var _dt_ = exported.Info.Traits.DTime
		for stuff in _dt_:
			if stuff:
				for i in range (1,(stuff as Array).size()):
					stuff[i] = Arfc.size3(stuff[i] as Array)
	if "Camera" in exported.Info.Traits:
		var _cam_ = exported.Info.Traits.Camera
		for zstuff in _cam_:
			if zstuff:
				for astuff in zstuff:
					if astuff:
						for i in range (1,(astuff as Array).size()):
							astuff[i] = Arfc.size3(astuff[i] as Array)
	var _hint_ = exported.Hint
	for i in range(0,(_hint_ as Array).size()):
		_hint_[i] = Arfc.size4(_hint_[i])

	# Get a JSON String
	var exported_str := JSON.stringify(exported,"",false,false)
	# Reformat JSON String
	exported_str = exported_str.replace("[","{")
	exported_str = exported_str.replace("]","}")
	exported_str = exported_str.replace(":","=")
	exported_str = exported_str.replace("\"","")
	exported_str = exported_str.replace("{}","e")
	exported_str = exported_str.replace("false","_")
	exported_str = exported_str.replace("Arf","\"Arf\"")
	exported_str = exported_str.replace(Arf._Madeby, "\""+Arf._Madeby+"\"")
	# Save the Result in a file
	var _file := FileAccess.open(path, FileAccess.WRITE_READ)
	_file.store_string(luahead+exported_str)
	_file.close()
	_file = null
	print("Arf from fumen.gd is exported to %s" % ProjectSettings.globalize_path(path))
