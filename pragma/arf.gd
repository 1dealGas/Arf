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
const add_camnodes := "Please add CamNodes. Right: [t(init_time1,value1,easetype1),t(init_time2,value2,easetype2),···]"
const wish_not_exist := "This Wish doesn't exist in Bartime %.4f"
const req := "At least 2 Nodes are required to generate a Hint."
const ipnyi := "Non-linear Interpolation is not implemented yet. Node Bartime:%.4f WID:%s"
const ub := "Inserting multiple %s Nodes with the same bartime will cause Undefined Behaviors."
const Positive := "%s must be a positive value."
const notnegative := "%s must be a non-negative value."
const _haschild := "Wish(WID:%s) contains child Wish(es). Check whether there is a circular reference if any abnormality happens."

static var current_zindex:int = 1
static var _hispeed:float = 1
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
static func num(i:float) -> String:
	return str(float("%.6f"%i))
static func num2(i:float) -> float:
	return float("%.2f"%i)
static func WishNodeSorter(a:WishNode,b:WishNode) -> bool:
	assert(a.bartime!=b.bartime,ub%"Wish")
	if a.bartime < b.bartime: return true
	else: return false
static func CamNodeSorter(a:CamNode,b:CamNode) -> bool:
	assert(a.init_bartime!=b.init_bartime,Arf.ub%"Camera")
	if a.init_bartime < b.init_bartime: return true
	else: return false
func t(Ninitbt:float, Nvalue:float, Neasetype:int=0) -> CamNode:
	var _t:= CamNode.new()
	assert(Ninitbt>=0, notnegative%"Bartime")
	assert(Neasetype>=0, notnegative%"EaseType")
	_t.init_bartime = Ninitbt
	_t.value = Nvalue
	_t.easetype = Neasetype
	return _t
func c(base:int,numerator:int,denominator:int) -> float:
	assert(numerator<=denominator and denominator!=0)
	return float(base)+float(numerator)/float(denominator)

static var easecalc:float = 0
static func EASE(ratio:float,type:int) -> float:
	if type==1:
		easecalc = sqrt( 1 - ratio*ratio )
		return ( 1 - easecalc )
	elif type==2:
		easecalc = 1 - ratio
		return sqrt( 1 - easecalc*easecalc )
	elif type==3:
		return ratio*ratio
	elif type==4:
		easecalc = 1 - ratio
		return ( 1 - easecalc*easecalc )
	elif type==5:
		easecalc = ratio*ratio
		return ( easecalc*easecalc )
	elif type==6:
		easecalc = 1 - ratio
		return ( 1 - easecalc*easecalc )
	else:
		return ratio



# Chain Stuff
const pid := "Wish %s"
const pr := "(%.4f,%.4f,%.4f)--<%02d>--"
const pt := "(%.4f,%.4f,%.4f)"
const pz := " in Z%d: "
const pn := "No Node Included"
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
					@warning_ignore("integer_division")
					var ex := nodes[i].easetype/10
					var ey := nodes[i].easetype%10
					var interpolate_ratio := (Nbartime-nodes[i].bartime)/(nodes[i+1].bartime-nodes[i].bartime)
					var nh:=SingleHint.new()
					if ex==0 and ey==0:
						nh.x = x0 + dx*interpolate_ratio
						nh.y = y0 + dy*interpolate_ratio
					else:
						nh.x = x0 + dx*Arf.EASE(interpolate_ratio,ex)
						nh.y = y0 + dy*Arf.EASE(interpolate_ratio,ey)
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
					assert(nodes[i].easetype==0, ipnyi%[Nbartime,self.wid])
					var _x := nodes[i].x
					var _y := nodes[i].y
					var dx := nodes[i+1].x - _x
					var dy := nodes[i+1].y - _y
					var interpolate_ratio := (Nbartime-nodes[i].bartime)/(nodes[i+1].bartime-nodes[i].bartime)
					_x += dx*interpolate_ratio
					_y += dy*interpolate_ratio
					return self.n(_x,_y,Nbartime)
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
			print(_haschild % self.wid)
			for child in _child:
				child.move(dx,dy,dbt,trim)
		return self
	func copy(dx:float,dy:float,dbt:float,number_of_times:int=1,trim:bool=true) -> WishGroup:
		if number_of_times>0:
			print("\nCopied the Wish below for %d time(s)." % number_of_times)
			self.p()
			print()
			var _1st := self._duplicate().move(dx,dy,dbt,trim)
			if number_of_times > 1:
				print("Notice: Only the 1st copy result will be returned.")
				for i in range(2,number_of_times+1):
					self._duplicate().move(i*dx,i*dy,i*dbt,trim)
			return _1st
		else: return self
	func mirror_lr() -> WishGroup:
		var nodenum := nodes.size()
		if nodenum==0: return self
		else:
			for node in nodes:
				node.x = 16 - node.x
		var chnum := _childhints.size()
		if chnum==0: return self
		else:
			for hint in _childhints:
				hint.x = 16 - hint.x
		if _child.size()>0:
			print(_haschild % self.wid)
			for child in _child:
				child.mirror_lr()
		return self
	func mirror_ud() -> WishGroup:
		var nodenum := nodes.size()
		if nodenum==0: return self
		else:
			for node in nodes:
				node.y = 8 - node.y
		var chnum := _childhints.size()
		if chnum==0: return self
		else:
			for hint in _childhints:
				hint.y = 8 - hint.y
		if _child.size()>0:
			print(_haschild % self.wid)
			for child in _child:
				child.mirror_ud()
		return self
	func r(at:float,radius:float=6,degree:float=90) -> WishGroup:
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
			_t0 = nodes[-1].easetype
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
					else:
						_x0 = _x + dx*Arf.EASE(interpolate_ratio,_t)
						_y0 = _y + dy*Arf.EASE(interpolate_ratio,_t)
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
					else:
						_x1 = _x + dx*Arf.EASE(interpolate_ratio,_t)
						_y1 = _y + dy*Arf.EASE(interpolate_ratio,_t)
						has_at = true
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
		var _new := Arf._w(_x0,_y0,_at0,_t0,0.05).n(_x1,_y1,at).h(at)
		_child.append(_new)
		return _new
	func pivot(init_x:float,init_y:float,init_bt:float,at:float) -> WishGroup:
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
				var _new := Arf._w(init_x,init_y,init_bt).n(_x,_y,at).h(at)
				_child.append(_new)
				return _new
		return self
		
	
	func f(remain:float=0.9375) -> WishGroup:
		if nodes.size()>1:
			var _nt1:float = nodes[-1].bartime
			var _nt2:float = nodes[-2].bartime
			if _nt1-_nt2 >= remain: return self.try_interpolate(_nt1-remain)
			else: return self
		else: return self
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
		ng.wid = str(Arf.Wish.size())
		if _child.size()>0:
			print(_haschild % self.wid)
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
		var presult := pid%wid + pz%int(zindex)
		var nodenum := nodes.size()
		if nodenum>0:
			for i in range(0,nodenum-1):
				presult += pr%[nodes[i].x,nodes[i].y,nodes[i].bartime,nodes[i].easetype]
			presult += pt%[nodes[nodenum-1].x,nodes[nodenum-1].y,nodes[nodenum-1].bartime]
			print(presult)
		else:
			presult += pn
			print(presult)
		



# Fumen Stuff (Base Part)
static func _static_init() -> void:
	clear_Arf()
static func clear_Arf() -> void:
	_Offset = 0
	_Madeby = "··|··  Arf User"
	BPMList.resize(2)
	BPMList[0] = 0
	BPMList[1] = 180
	Wish.resize(0)
	Hint.resize(0)
	Z.resize(16)
	for i in range(0,16):
		Z[i] = {
			DTime = false,  #process_dtime(DTime:Array[float])
			XScale = false,  #camnode_to_str(camnode:CamNode)
			YScale = false,
			Rotrad = false,
			XDelta = false,
			YDelta = false
		}
	current_zindex = 1
	_hispeed = 1

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
	for i in range(2,arrsize,2):
		assert(arr[i]>0, Positive%"Non-initial Bartime in BPMList")
	for i in range(1,arrsize,2):
		assert(arr[i]>0, Positive%"BPM")
	BPMList = arr

func forz(z:int) -> void:
	assert(z>0 and z<17, str_zrange)
	current_zindex = z
func DTime(arr:Array[float]) -> void:
	var arrsize := arr.size()
	assert(arrsize%2==0, "Incorret DTimeList format. Right: [bartime1,value1,bartime2,value2,···]")
	if arrsize>1:
		for i in range(0,arrsize,2):
			assert(arr[i]>=0, notnegative%"Bartime")
		Z[current_zindex-1].DTime = arr
	else:
		Z[current_zindex-1].DTime = false
func XScale(arr:Array[CamNode]) -> void:
	assert(arr.size()>0, add_camnodes)
	arr.sort_custom(CamNodeSorter)
	Z[current_zindex-1].XScale = arr
func YScale(arr:Array[CamNode]) -> void:
	assert(arr.size()>0, add_camnodes)
	arr.sort_custom(CamNodeSorter)
	Z[current_zindex-1].YScale = arr
func Rotrad(arr:Array[CamNode]) -> void:
	assert(arr.size()>0, add_camnodes)
	arr.sort_custom(CamNodeSorter)
	Z[current_zindex-1].Rotrad = arr
func XDelta(arr:Array[CamNode]) -> void:
	assert(arr.size()>0, add_camnodes)
	arr.sort_custom(CamNodeSorter)
	Z[current_zindex-1].XDelta = arr
func YDelta(arr:Array[CamNode]) -> void:
	assert(arr.size()>0, add_camnodes)
	arr.sort_custom(CamNodeSorter)
	Z[current_zindex-1].YDelta = arr

func w(x:float,y:float,bartime:float,easetype:int=0,zdelta:float=0) -> WishGroup:
	return Arf._w(x,y,bartime,easetype,zdelta)
static func _w(x:float,y:float,bartime:float,easetype:int=0,zdelta:float=0) -> WishGroup:
	assert(zdelta>=0 and zdelta<1, "Current ZIndex Overrided")
	var _nw:=WishGroup.new()
	_nw.zindex = current_zindex + zdelta
	Wish.append(_nw)
	_nw.wid = str(Wish.size())
	return _nw.n(x,y,bartime,easetype)

func nw(z:int=-1,zdelta:float=0) -> WishGroup:
	var _nw:=WishGroup.new()
	if z==-1: _nw.zindex = current_zindex + zdelta
	else: _nw.zindex = clampi(z,1,16) + zdelta
	Wish.append(_nw)
	_nw.wid = str(Wish.size())
	return _nw
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

func wid(id) -> WishGroup:
	if id is int:
		assert(id>0 and id<=Wish.size())
		return Wish[id-1]
	elif id is String:
		if id.is_valid_int():
			id = id.to_int()
			assert(id>0 and id<=Wish.size())
			return Wish[id-1]
		else:
			for wishgroup in Arf.Wish:
				if wishgroup.wid == id: return wishgroup
			print("No WishGroup is tagged as WID %s . A new WishGroup will be created."%id)
			var _n := nw()
			_n.wid = id
			return _n
	else:
		assert(false, "Invalid id Value.")
		return null



# Fumen Stuff (Pattern Part)
# Commonly, use w(),n(),h() only.
const DUAL_SCALE := 5.6
const DUAL_TYPE := 0
func dual(x:float,y:float,bartime:float,radius:float=1.25,degree:float=90,delta_degree:float=180) -> WishGroup:
	var _t0:float = bartime-radius*DUAL_SCALE*0.0625
	if _t0<0:
		_t0 = 0
		radius = bartime*16/DUAL_SCALE
	degree = deg_to_rad(degree)
	delta_degree = degree + deg_to_rad(delta_degree)
	var a := Arf._w(x+radius*cos(degree),y+radius*sin(degree),_t0,DUAL_TYPE,0.01).n(x,y,bartime).h(bartime)
	var b := Arf._w(x+radius*cos(delta_degree),y+radius*sin(delta_degree),_t0,DUAL_TYPE).n(x,y,bartime)
	if DUAL_TYPE == 0:
		a.try_interpolate(_t0+0.09375).try_interpolate(bartime-0.000001)
		b.try_interpolate(_t0+0.09375).try_interpolate(bartime-0.000001)
	a._child.append(b)
	return a
func dual_without_hint(x:float,y:float,bartime:float,radius:float=1.25,degree:float=90,delta_degree:float=180) -> WishGroup:
	var _t0:float = bartime-radius*DUAL_SCALE*0.0625
	if _t0<0:
		_t0 = 0
		radius = bartime*16/DUAL_SCALE
	degree = deg_to_rad(degree)
	delta_degree = degree + deg_to_rad(delta_degree)
	var a := Arf._w(x+radius*cos(degree),y+radius*sin(degree),_t0,DUAL_TYPE,0.01).n(x,y,bartime).h(bartime)
	var b := Arf._w(x+radius*cos(delta_degree),y+radius*sin(delta_degree),_t0,DUAL_TYPE).n(x,y,bartime)
	if DUAL_TYPE == 0:
		a.try_interpolate(_t0+0.09375).try_interpolate(bartime-0.000001)
		b.try_interpolate(_t0+0.09375).try_interpolate(bartime-0.000001)
	a._child.append(b)
	return a
func pop(x:float,y:float,bartime:float,radius:float=1.25) -> WishGroup:
	randomize()
	var _degree:float = randf_range(0,360)
	randomize()
	var _delta:float = randf_range(60,180)
	return dual(x,y,bartime,radius,_degree,_delta)
func lp(bartime:float) -> WishGroup:
	randomize()
	var _x:float = randf_range(3,13)
	randomize()
	var _y:float = randf_range(1,7)
	randomize()
	var _degree:float = randf_range(0,360)
	#randomize()
	#var _delta:float = randf_range(60,180)
	return dual(_x,_y,bartime,1.25,_degree,180)

func runto(x:float,y:float,bartime:float,radius:float=1.25,degree:float=90) -> WishGroup:
	var _t0:float = bartime-radius*DUAL_SCALE*0.0625
	if _t0<0:
		_t0 = 0
		radius = bartime*16/DUAL_SCALE
	degree = deg_to_rad(degree)
	var a := Arf._w(x+radius*cos(degree),y+radius*sin(degree),_t0,DUAL_TYPE,0.01).n(x,y,bartime)
	var b := Arf._w(x,y,_t0).n(x,y,bartime).try_interpolate(_t0+0.09375).h(bartime)
	if DUAL_TYPE == 0: a.try_interpolate(_t0+0.09375).try_interpolate(bartime-0.000001)
	b._child.append(a)
	return b
func iw(x:float,y:float,bartime:float,radius:float=6,degree:float=90) -> WishGroup:
	var _t0:float = bartime-radius*0.0625/_hispeed
	if _t0<0:
		_t0 = 0
		radius = bartime*16
	degree = deg_to_rad(degree)
	var a := Arf._w(x+radius*cos(degree),y+radius*sin(degree),_t0,0,0.01).n(x,y,bartime)
	var b := Arf._w(x,y,_t0).n(x,y,bartime).h(bartime)
	b._child.append(a)
	return b
