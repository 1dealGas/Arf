# Arf Base Module
extends Node
class_name Arf


########  Result  ########
static var _Offset:int = 0
static var _Madeby:="Arf User"
static var BPMList:Array[float] = [0,180]
static var Wish:Array[WishGroup]
static var Hint:Array[SingleHint]
static var Z:Array[Dictionary]  #Arrays related to ZIndex.
########  Result  ########



# Base Stuff
const str_zrange := "\"z\" must be an interger in [1,16]."
const add_camnodes := "Please add CamNodes. Right: [c(init_time1,value1,easetype1),c(init_time2,value2,easetype2),···]"
const wish_not_exist := "This Wish doesn't exist in Bartime %.4f"
const req := "At least 2 Nodes are required to generate a Hint."
const ipnyi := "Line %d: Non-linear&Non-Partial Interpolation is not implemented yet."
const ub := "Inserting multiple %s Nodes with the same bartime will cause Undefined Behaviors."
const Positive := "%s must be a positive value."
const notnegative := "%s must be a non-negative value."

static var current_zindex:int = 1
static var _hispeed:float = 1
static var _INVALID_WG := WishGroup.new()
static var names:Dictionary = {}
func Hispeed(hi:float) -> void:
	_hispeed = clampf(hi,0.001,512000)

class SingleHint:
	var x:float = 37
	var y:float = 37
	var bartime:float = 0
	var zindex:int = 1
	func _to_arr() -> Array:
		return [x,y,Arfc.get_mstime(bartime),zindex]
class WishNode:
	var x:float
	var y:float
	var bartime:float
	var easetype:int
	func _to_arr() -> Array:
		return [x,y,Arfc.get_mstime(bartime),easetype]
class CamNode:
	var init_bartime:float = 0
	var value:float = 0
	var easetype:int = 0
	func _to_arr() -> Array:
		return [Arfc.get_mstime(init_bartime),value,easetype]
static func num(i_:float) -> String:
	return str(float("%.6f"%i_))
static func num2(i_:float) -> float:
	return float("%.2f"%i_)
static func WishNodeSorter(a:WishNode,b:WishNode) -> bool:
	assert(a.bartime!=b.bartime,ub%"Wish")
	if a.bartime < b.bartime: return true
	else: return false
static func CamNodeSorter(a:CamNode,b:CamNode) -> bool:
	assert(a.init_bartime!=b.init_bartime,Arf.ub%"Camera")
	if a.init_bartime < b.init_bartime: return true
	else: return false
func c(Ninitbt:float, Nvalue:float, Neasetype:int=0) -> CamNode:
	var _t:= CamNode.new()
	assert(Ninitbt>=0, notnegative%"Bartime")
	assert(Neasetype>=0, notnegative%"EaseType")
	assert(Neasetype<7, "EaseType of Camera Nodes must be ArEase.Cam_* or 0.")
	_t.init_bartime = Ninitbt
	_t.value = Nvalue
	_t.easetype = Neasetype
	return _t
func t(base:int,numerator:int,denominator:int) -> float:
	assert(numerator<=denominator and denominator!=0)
	return float(base)+float(numerator)/float(denominator)


# Chain Stuff
const pid := "Wish %s"
const pr := "(%.4f,%.4f,%.4f)--<%02d>--"
const pt := "(%.4f,%.4f,%.4f)"
const pz := " in Z%d: "
const pn := "No Node Included"
static var cp:Array[int] = [0,0]
class WishGroup:
	
	var _child:Array[WishGroup] = []
	var _childhints:Array[SingleHint] = []
	var wid:String
	
	var zindex:float = 1.0
	var nodes:Array[WishNode]
	func n(Nx:float,Ny:float,Nbartime:float,Neasetype:int=0) -> WishGroup:
		var newnode:= WishNode.new()
		newnode.x = Nx
		newnode.y = Ny
		newnode.bartime = Nbartime
		newnode.easetype = Neasetype
		nodes.append(newnode)
		nodes.sort_custom(Arf.WishNodeSorter)
		return self
	func h(Nbartime:float) -> WishGroup:
		var nodenum := nodes.size()
		assert(nodenum>1, req)
		assert(Nbartime>=nodes[0].bartime and Nbartime<=nodes[-1].bartime, wish_not_exist%Nbartime)
		if Nbartime == nodes[0].bartime:
			var nh := SingleHint.new()
			nh.x = nodes[0].x
			nh.y = nodes[0].y
			nh.bartime = nodes[0].bartime
			nh.zindex = int(self.zindex)
			self._childhints.append(nh)
			Arf.Hint.append(nh)
			return self
		elif Nbartime == nodes[-1].bartime:
			var nh := SingleHint.new()
			nh.x = nodes[-1].x
			nh.y = nodes[-1].y
			nh.bartime = nodes[-1].bartime
			nh.zindex = int(self.zindex)
			self._childhints.append(nh)
			Arf.Hint.append(nh)
			return self
		else:
			for i in range(0,nodenum-1):
				if Nbartime>nodes[i].bartime and Nbartime<=nodes[i+1].bartime:
					var x0 := nodes[i].x
					var y0 := nodes[i].y
					var dx := nodes[i+1].x - x0
					var dy := nodes[i+1].y - y0
					var et:int = nodes[i].easetype
					var interpolate_ratio := (Nbartime-nodes[i].bartime)/(nodes[i+1].bartime-nodes[i].bartime)
					var nh:=SingleHint.new()
					if et == 0:
						nh.x = x0 + dx*interpolate_ratio
						nh.y = y0 + dy*interpolate_ratio
					elif et > 1048575:
						var PE:Array[float] = ArEase.PartialEASE(interpolate_ratio,et)
						nh.x = x0 + dx*PE[0]
						nh.y = y0 + dy*PE[1]
					else:
						@warning_ignore("integer_division")
						var ex := et/10
						var ey := et%10
						nh.x = x0 + dx*ArEase.EASE(interpolate_ratio,ex)
						nh.y = y0 + dy*ArEase.EASE(interpolate_ratio,ey)
					nh.bartime = Nbartime
					nh.zindex = int(self.zindex)
					self._childhints.append(nh)
					Arf.Hint.append(nh)
					break
			return self
	func try_interpolate(Nbartime:float) -> WishGroup:
		var nodenum := nodes.size()
		if nodenum<2: return self
		elif Nbartime<nodes[0].bartime or Nbartime>=nodes[-1].bartime: return self
		else:
			for i in range(0,nodenum-1):
				if Nbartime>=nodes[i].bartime and Nbartime<nodes[i+1].bartime:
					if nodes[i].easetype == 0 :
						var _x := nodes[i].x
						var _y := nodes[i].y
						var dx := nodes[i+1].x - _x
						var dy := nodes[i+1].y - _y
						var interpolate_ratio := (Nbartime-nodes[i].bartime)/(nodes[i+1].bartime-nodes[i].bartime)
						_x += dx*interpolate_ratio
						_y += dy*interpolate_ratio
						return self.n(_x,_y,Nbartime)
					elif nodes[i].easetype > 1048575 :
						var _x := nodes[i].x
						var _y := nodes[i].y
						var _et := nodes[i].easetype
						var dx := nodes[i+1].x - _x
						var dy := nodes[i+1].y - _y
						var interpolate_ratio := (Nbartime-nodes[i].bartime)/(nodes[i+1].bartime-nodes[i].bartime)
						var _t := ArEase.PartialEASE(interpolate_ratio, _et)
						_x += dx * _t[0]
						_y += dy * _t[1]
						nodes[i].easetype = ArEase.split_pe_former(_et, interpolate_ratio)
						return self.n( _x, _y, Nbartime, ArEase.split_pe_latter(_et, interpolate_ratio) )
					else:
						assert(false, ipnyi % get_stack()[1].line)
						return self
		return self
	func move(dx:float,dy:float,dbt:float,trim:bool=true) -> WishGroup:
		var nodenum := nodes.size()
		if nodenum==0: return self
		else:
			for node in nodes:
				node.x += dx
				node.y += dy
				node.bartime += dbt
			for hint in _childhints:
				hint.x += dx
				hint.y += dy
				hint.bartime += dbt
			if trim and nodes[0].bartime<0:
				self.try_interpolate(0)
				var _nodes:Array[WishNode] = []
				for node in nodes:
					if node.bartime>=0: _nodes.append(node)
				nodes = _nodes
		if _child.size()>0:
			for child in _child:
				child.move(dx,dy,dbt,trim)
		return self
	func copy(dx:float,dy:float,dbt:float,number_of_times:int=1,trim:bool=true) -> WishGroup:
		if number_of_times>0:
			Arf.cp[0] = get_stack()[1].line
			Arf.cp[1] = number_of_times
			print("Line %d: Copied the Wish below for %d time(s)." % Arf.cp)
			self.p()
			print()
			var _1st := self._duplicate().move(dx,dy,dbt,trim)
			if number_of_times > 1:
				print("Line %d: Only the 1st copy result will be returned." % Arf.cp[0] )
				for i in range(2,number_of_times+1):
					self._duplicate().move(i*dx,i*dy,i*dbt,trim)
			return _1st
		else: return self
	func mirror_lr() -> WishGroup:
		if nodes.size() != 0:
			for node in nodes:
				node.x = 16 - node.x
		if _childhints.size() != 0:
			for hint in _childhints:
				hint.x = 16 - hint.x
		if _child.size()>0:
			for child in _child:
				child.mirror_lr()
		return self
	func mirror_ud() -> WishGroup:
		if nodes.size() != 0:
			for node in nodes:
				node.y = 8 - node.y
		if _childhints.size() != 0:
			for hint in _childhints:
				hint.y = 8 - hint.y
		if _child.size()>0:
			for child in _child:
				child.mirror_ud()
		return self
	func r(at:float,radius:float=6.637,degree:float=90,nohint:bool=false) -> WishGroup:
		var nodenum := nodes.size()
		if nodenum<2: return self
		assert(at>=0, notnegative%"Bartime" )
		var _at0:float = at - 0.0625*radius/Arf._hispeed
		if _at0<0:
			_at0 = 0
			radius = at
		var _x0:float = 0
		var _y0:float = 0
		var _t0:int = 0
		var _x1:float = 0
		var _y1:float = 0
		var has_at0 := false
		var has_at := false
		degree = fmod(degree, 360.0)
		if _at0<=nodes[0].bartime:
			_x0 = nodes[0].x
			_y0 = nodes[0].y
			_t0 = nodes[0].easetype
			has_at0 = true
		elif _at0>=nodes[-1].bartime:
			_x0 = nodes[-1].x
			_y0 = nodes[-1].y
			_t0 = nodes[-2].easetype
			has_at0 = true
		else:
			for i in range(0,nodenum-1):
				if _at0>=nodes[i].bartime and _at0<nodes[i+1].bartime:
					var _x := nodes[i].x
					var _y := nodes[i].y
					var _t := nodes[i].easetype
					var dx := nodes[i+1].x - _x
					var dy := nodes[i+1].y - _y
					var interpolate_ratio := (_at0-nodes[i].bartime)/(nodes[i+1].bartime-nodes[i].bartime)
					if _t == 0:
						_x0 = _x + dx*interpolate_ratio
						_y0 = _y + dy*interpolate_ratio
						has_at0 = true
					elif _t > 1048575:
						var PE:Array[float] = ArEase.PartialEASE(interpolate_ratio,_t)
						_x0 = _x + dx * PE[0]
						_y0 = _y + dy * PE[1]
						_t0 = _t
						has_at0 = true
					else:
						@warning_ignore("integer_division")
						var _tx:int = _t/10
						var _ty:int = _t%10
						_x0 = _x + dx*ArEase.EASE(interpolate_ratio,_tx)
						_y0 = _y + dy*ArEase.EASE(interpolate_ratio,_ty)
						_t0 = _t
						has_at0 = true
		if at<=nodes[0].bartime:
			_x1 = nodes[0].x
			_y1 = nodes[0].y
			has_at = true
		elif at>=nodes[-1].bartime:
			_x1 = nodes[-1].x
			_y1 = nodes[-1].y
			has_at = true
		else:
			for i in range(0,nodenum-1):
				if at>=nodes[i].bartime and at<nodes[i+1].bartime:
					var _x := nodes[i].x
					var _y := nodes[i].y
					var _t := nodes[i].easetype
					var dx := nodes[i+1].x - _x
					var dy := nodes[i+1].y - _y
					var interpolate_ratio := (at-nodes[i].bartime)/(nodes[i+1].bartime-nodes[i].bartime)
					if _t == 0:
						_x1 = _x + dx*interpolate_ratio
						_y1 = _y + dy*interpolate_ratio
						has_at = true
					elif _t > 1048575:
						var PE:Array[float] = ArEase.PartialEASE(interpolate_ratio,_t)
						_x1 = _x + dx * PE[0]
						_y1 = _y + dy * PE[1]
						has_at = true
					else:
						@warning_ignore("integer_division")
						var _tx:int = _t/10
						var _ty:int = _t%10
						_x1 = _x + dx*ArEase.EASE(interpolate_ratio,_tx)
						_y1 = _y + dy*ArEase.EASE(interpolate_ratio,_ty)
						has_at = true
					break
		assert(has_at0 and has_at, "Failed to Insert a to-be-received Wish.")
		if is_equal_approx(degree,0):
			_x0 += radius
		elif is_equal_approx(degree,90):
			_y0 += radius
		elif is_equal_approx(degree,180):
			_x0 -= radius
		elif is_equal_approx(degree,270):
			_y0 -= radius
		else:
			degree = deg_to_rad(degree)
			_x0 += radius*cos( degree )
			_y0 += radius*sin( degree )
		var _new := Arf._w(_x0,_y0,_at0,_t0,0.05).n(_x1,_y1,at)
		var _lineid := str( get_stack()[1].line )
		if not nohint: _new.h(at)
		_child.append(_new.tag(_lineid))
		return self
	func pivot(init_x:float,init_y:float,init_bt:float,at:float) -> WishGroup:
		var _lineid := str( get_stack()[1].line )
		assert(init_bt>=0 and at>=0, notnegative%"Bartime" )
		assert(init_bt<at, "Initial Bartime must be smaller than the collision Bartime \"at\".")
		var nodenum:int = nodes.size()
		assert(nodenum>1, "Wish(WID:%s) must be interpolatable to Create a Pivot Wish." % self.wid )
		for i in range(0,nodenum-2):
			if at>=nodes[i].bartime and at<nodes[i+1].bartime:
				var _x := nodes[i].x
				var _y := nodes[i].y
				var dx := nodes[i+1].x - _x
				var dy := nodes[i+1].y - _y
				var interpolate_ratio := (at-nodes[i].bartime)/(nodes[i+1].bartime-nodes[i].bartime)
				_x += dx*interpolate_ratio
				_y += dy*interpolate_ratio
				var _new := Arf._w(init_x,init_y,init_bt).n(_x,_y,at).h(at).tag(_lineid)
				_child.append(_new)
				return _new
		return self
		
	
	func _duplicate() -> WishGroup:
		var ng := Arf.WishGroup.new()
		var nodenum := self.nodes.size()
		if nodenum>0:
			for node in self.nodes:
				var newnode := WishNode.new()
				newnode.x = node.x
				newnode.y = node.y
				newnode.bartime = node.bartime
				newnode.easetype = node.easetype
				ng.nodes.append(newnode)
		var chnum := self._childhints.size()
		if chnum>0:
			for hint in self._childhints:
				var newhint := SingleHint.new()
				newhint.x = hint.x
				newhint.y = hint.y
				newhint.bartime = hint.bartime
				newhint.zindex = hint.zindex
				ng._childhints.append(newhint)
				Arf.Hint.append(newhint)
		Arf.Wish.append(ng)
		ng.zindex = self.zindex
		ng.wid = str(Arf.Wish.size())
		ng.tag("D")
		if _child.size()>0:
			for child in _child:
				ng._child.append(child._duplicate())
		return ng
	func _to_arr() -> Array:
		var arr:Array = [3]
		arr.append(self.zindex)
		assert(nodes.size()>0, "Empty WishGroup is not Allowed. WID:%s"%self.wid)
		for node in self.nodes:
			arr.append(node._to_arr())
		arr.append(self.wid)
		return arr
	func p() -> void:
		var presult := pid%wid.get_slice(" #",0) + pz%int(zindex)
		var nodenum := nodes.size()
		if nodenum>0:
			for i in range(0,nodenum-1):
				presult += pr%[nodes[i].x,nodes[i].y,nodes[i].bartime,nodes[i].easetype]
			presult += pt%[nodes[nodenum-1].x,nodes[nodenum-1].y,nodes[nodenum-1].bartime]
			print(presult)
		else:
			presult += pn
			print(presult)
	func name(NAME:String) -> WishGroup:
		var _name:String = NAME.strip_edges()
		if Arf.names.has(_name):
			print("Line %d: Attempting to Shadow an existing Wish." % get_stack()[1].line )
			Arf._g(_name).p()
			return self
		else:
			var _w:String = self.wid.strip_edges()
			if Arf.names.has(_w): Arf.names.erase(_w)
			self.wid = NAME
			Arf.names[_name] = self
			return self
	func tag(TAG:String) -> WishGroup:
		if not Arf._show_line_id: return self
		if self._child.size() > 0:
			for child in self._child:
				child.tag("C")
		return self.name(self.wid.get_slice(" ",0) + " #" + TAG)
		



# Fumen Stuff (Base Part)
static var _show_line_id := true
static func clear_Arf(s:bool) -> void:
	_Offset = 0
	_Madeby = "··|··  Arf User"
	BPMList.resize(2)
	BPMList[0] = 0
	BPMList[1] = 180
	Wish.resize(0)
	Hint.resize(0)
	Z.resize(16)
	for i_ in range(0,16):
		Z[i_] = {
			DTime = false,  #process_dtime(DTime:Array[float])
			XScale = false,  #camnode_to_str(camnode:CamNode)
			YScale = false,
			Rotrad = false,
			XDelta = false,
			YDelta = false
		}
	current_zindex = 1
	_hispeed = 1
	_INVALID_WG = WishGroup.new()
	names = {}
	_show_line_id = s

func Madeby(author:String) -> void:
	assert(author.begins_with("·") or author.begins_with("|"), "Please Append the Tier Tag before the Author. Right:\"··|··  Arf User\"")
	_Madeby = author

func Offset(ms:int) -> void:
	_Offset = ms
func BPM(arr:Array[float]) -> void:
	# BPMList will be sorted in Arfc.make_b2mList()
	var arrsize := arr.size()
	assert(arrsize>1 and arrsize%2==0, "Incorret BPMList format. Right: [bartime1,value1,bartime2,value2,···]")
	assert(arr[0]==0, "The init bartime of the first BPM definition in BPMList must be 0.")
	for i_ in range(2,arrsize,2):
		assert(arr[i_]>0, Positive%"Non-initial Bartime in BPMList")
	for i_ in range(1,arrsize,2):
		assert(arr[i_]>0, Positive%"BPM")
	BPMList = arr

func forz(z:int) -> void:
	assert(z>0 and z<17, str_zrange)
	current_zindex = z
func DTime(arr:Array[float]) -> void:
	var arrsize := arr.size()
	assert(arrsize%2==0, "Incorret DTimeList format. Right: [bartime1,value1,bartime2,value2,···]")
	if arrsize>1:
		for i_ in range(0,arrsize,2): assert(arr[i_]>=0, notnegative%"Bartime")
		Z[current_zindex-1].DTime = arr
	else: Z[current_zindex-1].DTime = false
func XScale(arr:Array[CamNode]) -> void:
	if arr.size()>0:
		arr.sort_custom(CamNodeSorter)
		Z[current_zindex-1].XScale = arr
	else: Z[current_zindex-1].XScale = false
func YScale(arr:Array[CamNode]) -> void:
	if arr.size()>0:
		arr.sort_custom(CamNodeSorter)
		Z[current_zindex-1].YScale = arr
	else: Z[current_zindex-1].YScale = false
func Rotrad(arr:Array[CamNode]) -> void:
	if arr.size()>0:
		arr.sort_custom(CamNodeSorter)
		Z[current_zindex-1].Rotrad = arr
	else: Z[current_zindex-1].Rotrad = false
func XDelta(arr:Array[CamNode]) -> void:
	if arr.size()>0:
		arr.sort_custom(CamNodeSorter)
		Z[current_zindex-1].XDelta = arr
	else: Z[current_zindex-1].XDelta = false
func YDelta(arr:Array[CamNode]) -> void:
	if arr.size()>0:
		arr.sort_custom(CamNodeSorter)
		Z[current_zindex-1].YDelta = arr
	else: Z[current_zindex-1].YDelta = false

func w(x:float,y:float,bartime:float,easetype:int=0,zdelta:float=0) -> WishGroup:
	return Arf._w(x,y,bartime,easetype,zdelta).tag( str(get_stack()[1].line) )
static func _w(x:float,y:float,bartime:float,easetype:int=0,zdelta:float=0) -> WishGroup:
	assert(zdelta>=0 and zdelta<1, "Current ZIndex Overrided")
	var _nw:=WishGroup.new()
	_nw.zindex = current_zindex + zdelta
	Wish.append(_nw)
	_nw.wid = str(Wish.size())
	return _nw.n(x,y,bartime,easetype).tag( str(get_stack()[2].line) )

# The manual method to create Wishes is deprecated.
#func nw(z:int=-1,zdelta:float=0) -> WishGroup:
	#var _nw:=WishGroup.new()
	#var _lineid := str( get_stack()[1].line )
	#if z==-1: _nw.zindex = current_zindex + zdelta
	#else: _nw.zindex = clampi(z,1,16) + zdelta
	#Wish.append(_nw)
	#_nw.wid = str(Wish.size())
	#return _nw.tag(_lineid)
# The manual method to generate Hints is deprecated.
#static func h(Nx:float,Ny:float,Nbartime:float,z:int=-1) -> SingleHint:
	#var nh:=SingleHint.new()
	#nh.x = Nx
	#nh.y = Ny
	#nh.bartime = Nbartime
	#if z==-1: nh.zindex = current_zindex
	#else: nh.zindex = clampi(z,1,16)
	#Hint.append(nh)
	#return nh

func g(id) -> WishGroup: return Arf._g(id)
static func _g(id) -> WishGroup:
	if id is int:
		assert(id>0 and id<=Wish.size())
		return Wish[id-1]
	elif id is String:
		id = id.strip_edges()
		if names.has(id): return names[id]
		else:
			print("Line %d : Attempting to Get a Nonexist WishGroup." % get_stack()[1].line )
			return _INVALID_WG
	else:
		print("Line %d : Attempting to Get a Nonexist WishGroup." % get_stack()[1].line )
		return _INVALID_WG



# Fumen Stuff (Pattern Part)
# Commonly, use w(),n(),h() only.
const DUAL_TYPE := 0
func dual(x:float,y:float,bartime:float,degree:float=90,delta_degree:float=180,radius:float=2) -> WishGroup:
	var _t0:float = bartime - 0.375/_hispeed
	var _lineid := str( get_stack()[1].line )
	if _t0 < 0:
		_t0 = 0
		#radius = 6*_hispeed*bartime/0.375
		radius *= bartime * _hispeed / 0.375
	degree = deg_to_rad(degree)
	delta_degree = degree + deg_to_rad(delta_degree)
	var a := Arf._w(x+radius*cos(degree),y+radius*sin(degree),_t0,DUAL_TYPE,0.01).n(x,y,bartime).h(bartime).tag(_lineid)
	var b := Arf._w(x+radius*cos(delta_degree),y+radius*sin(delta_degree),_t0,DUAL_TYPE).n(x,y,bartime).tag(_lineid)
	#if DUAL_TYPE == 0:
		#a.try_interpolate(_t0+0.09375).try_interpolate(bartime-0.0001)
		#b.try_interpolate(_t0+0.09375).try_interpolate(bartime-0.0001)
	a._child.append(b)
	return a
func dual_without_hint(x:float,y:float,bartime:float,degree:float=90,delta_degree:float=180,radius:float=2) -> WishGroup:
	var _t0:float = bartime - 0.375/_hispeed
	var _lineid := str( get_stack()[1].line )
	if _t0 < 0:
		_t0 = 0
		#radius = 6*_hispeed*bartime/0.375
		radius *= bartime * _hispeed / 0.375
	degree = deg_to_rad(degree)
	delta_degree = degree + deg_to_rad(delta_degree)
	var a := Arf._w(x+radius*cos(degree),y+radius*sin(degree),_t0,DUAL_TYPE,0.01).n(x,y,bartime).tag(_lineid)
	var b := Arf._w(x+radius*cos(delta_degree),y+radius*sin(delta_degree),_t0,DUAL_TYPE).n(x,y,bartime).tag(_lineid)
	#if DUAL_TYPE == 0:
		#a.try_interpolate(_t0+0.09375).try_interpolate(bartime-0.0001)
		#b.try_interpolate(_t0+0.09375).try_interpolate(bartime-0.0001)
	a._child.append(b)
	return a
func pop(x:float,y:float,bartime:float,radius:float=2) -> WishGroup:
	var _lineid := str( get_stack()[1].line )
	seed( int(x+y+bartime+radius) )
	var _degree:float = randf_range(0,360)
	seed( int(x*y*bartime*radius) )
	var _delta:float = randf_range(60,120)
	return dual(x,y,bartime,_degree,_delta,radius).tag(_lineid)
func lp(bartime:float) -> WishGroup:
	var _lineid := str( get_stack()[1].line )
	seed( int(bartime*bartime) )
	var _x:float = randf_range(3,13)
	seed( int(bartime+bartime) )
	var _y:float = randf_range(1,7)
	seed( int(bartime*bartime+bartime) )
	var _degree:float = randf_range(0,360)
	seed( int(bartime) )
	var _delta:float = randf_range(60,180)
	return dual(_x,_y,bartime,_degree,_delta,2).tag(_lineid)

const RUNTO_TYPE := 0
func runto(x:float,y:float,bartime:float,degree:float=90,radius:float=4) -> WishGroup:
	var _t0:float = bartime-radius*0.09375/_hispeed
	var _lineid := str( get_stack()[1].line )
	if _t0<0:
		_t0 = 0
		radius = bartime*16
	degree = deg_to_rad(degree)
	var a := Arf._w(x+radius*cos(degree),y+radius*sin(degree),_t0,RUNTO_TYPE,0.01).n(x,y,bartime).tag(_lineid)
	var b := Arf._w(x,y,_t0).n(x,y,bartime).try_interpolate(_t0+0.09375).h(bartime).tag(_lineid)
	if RUNTO_TYPE == 0: a.try_interpolate(_t0+0.09375).try_interpolate(bartime-0.000001)
	b._child.append(a)
	return b
func iw(x:float,y:float,bartime:float,easetype:int=0,radius:float=6.37,degree:float=90) -> WishGroup:
	var _t0:float = bartime - radius*0.0625/_hispeed
	if _t0<0:
		_t0 = 0
		radius = bartime * _hispeed / 16
	degree = deg_to_rad(degree)
	var a := Arf._w(x+radius*cos(degree),y+radius*sin(degree),_t0,easetype,0.01).n(x,y,bartime).tag("C")
	var b := Arf._w(x,y,_t0).n(x,y,bartime).h(bartime)
	b._child.append(a)
	return b
