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
const invalid_verification := "Invalid verification. To get the valid verification, append \".p()\" in your last primitive WishGroup, and read the WID from the Debug Output."
const prim_not_fixed := "Make sure you complete all Primitive WishGroups. Call \"prim_complete(verification)\" then."
const repeated_tag := "Don't tag your fumen with \"prim_complete\" repeatedly."
const wish_not_exist := "This Wish doesn't exist in Bartime %.4f"
const req := "At least 2 Nodes are required to generate a Hint."
const ipnyi := "Non-linear Interpolation is not implemented yet. Node Bartime:%.4f WID:%s"
const ub := "Inserting multiple %s Nodes with the same bartime will cause Undefined Behaviors."
const Positive := "%s must be a positive value."
const notnegative := "%s must be a non-negative value."

static var _prim_complete:bool = false
static var LayerResults:Array[LayerResult]
static var current_zindex:int = 1

class SingleHint:
	var x:float
	var y:float
	var bartime:float
	var zindex:int
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
	
	var wid:String
	var nextdup:int = 1
	
	var zindex:float = 1.0
	var nodes:Array[WishNode]
	func n(Nx:float=0,Ny:float=0,Nbartime:float=0,Neasetype:int=0) -> WishGroup:
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
		assert(Nbartime>nodes[0].bartime and Nbartime<=nodes[-1].bartime, wish_not_exist%Nbartime)
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
				Arf.Hint.append(nh)
				break
		return self
	func try_interpolate(Nbartime:float) -> WishGroup:
		var nodenum := nodes.size()
		if nodenum<2: return self
		elif Nbartime<=nodes[0].bartime or Nbartime>nodes[-1].bartime: return self
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
			if trim and nodes[0].bartime<0:
				self.try_interpolate(0)
				var _nodes:Array[WishNode] = []
				for node in nodes:
					if node.bartime>=0: _nodes.append(node)
				nodes = _nodes
		return self
	func copy(dx:float,dy:float,dbt:float,number_of_times:int=1,trim:bool=true) -> WishGroup:
		if number_of_times>0:
			var _dz:float = self.nextdup/10000.0
			var zi:float = self.zindex + _dz
			print("Copied the Wish below for %i time(s). Call layer(%.4f,true) to acquire the copies."%[number_of_times,zi])
			self.p()
			for i in range(1,number_of_times+1):
				Arf.Wish.append(self._duplicate(_dz).move(i*dx,i*dy,i*dbt,trim))
		return self
	func r(at:float,radius:float=6,degree:float=90) -> WishGroup:
		var nodenum := nodes.size()
		if nodenum<2: return self
		assert(at>=0, notnegative%"Bartime" )
		var _at0:float = at - 0.0625*radius
		if _at0<0:
			_at0 = 0
			radius = at
		var _x0:float = 0
		var _y0:float = 0
		var _x1:float = 0
		var _y1:float = 0
		var has_at0 := false
		var has_at := false
		degree = fmod(degree, 360.0)
		if _at0<=nodes[0].bartime:
			_x0 = nodes[0].x
			_y0 = nodes[0].y
			has_at0 = true
		elif _at0>=nodes[-1].bartime:
			_x0 = nodes[-1].x
			_y0 = nodes[-1].y
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
			degree = degree/180 * PI
			_x0 += radius*cos( degree )
			_y0 += radius*sin( degree )
		return Arf._w(_x0,_y0,_at0,0,0.05).n(_x1,_y1,at).h(at)
		
	
	func _duplicate(dz:float=0) -> WishGroup:
		var ng := Arf.WishGroup.new()
		ng.wid = self.wid + "d" + str(self.nextdup)
		ng.zindex = self.zindex + clampf(dz,0,0.999999)
		var nodenum := self.nodes.size()
		if nodenum>0:
			for node in self.nodes:
				var newnode := WishNode.new()
				newnode.x = node.x
				newnode.y = node.y
				newnode.bartime = node.bartime
				newnode.easetype = node.easetype
				ng.nodes.append(newnode)
		self.nextdup += 1
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
		

static var nextlrid:int = 1
class LayerResult:
	var id:int
	var wish:Array[WishGroup]
	var hint:Array[SingleHint]
	func _init():
		self.id = Arf.nextlrid
		Arf.nextlrid += 1



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
	_prim_complete = false
	LayerResults.resize(0)
	current_zindex = 1
	nextlrid = 1

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

func prim_complete(verification:int) -> void:
	assert(Wish.size()==verification, invalid_verification)
	assert(not _prim_complete, repeated_tag)
	_prim_complete = true

func wid(id) -> WishGroup:
	assert(_prim_complete, prim_not_fixed)
	if (id is int):
		assert(id>0 and id<=Wish.size())
		return Wish[id-1]
	elif (id is String) and id.is_valid_int():
		id = id.to_int()
		assert(id>0 and id<=Wish.size())
		return Wish[id-1]
	else:
		for wishgroup in Arf.Wish:
			if wishgroup.wid == id: return wishgroup
		return null


func layer(z:float,strict:bool=false) -> LayerResult:
	assert(z>0 and z<17, str_zrange)
	var lyr := LayerResult.new()
	if strict:
		var dz:float = 0
		for wishgroup in Arf.Wish:
			dz = wishgroup.zindex - z
			if dz>=-0.000001 and dz<=0.000001: lyr.wish.append(wishgroup)
	else:
		z = int(z)
		for wishgroup in Arf.Wish:
			if wishgroup.zindex>=z and wishgroup.zindex<z+1: lyr.wish.append(wishgroup)
		for _hint in Arf.Hint:
			if _hint.zindex==z: lyr.hint.append(_hint)
	LayerResults.append(lyr)
	return lyr

func layerid(id:int) -> LayerResult:
	assert(_prim_complete, prim_not_fixed)
	assert(id>0 and id<=LayerResults.size())
	return LayerResults[id-1]

# Fumen Stuff (Pattern Part)
# Commonly, use w(),n(),h() only.
const DUAL_SCALE := 1.51
const DUAL_TYPE := 33
func dual(x:float,y:float,bartime:float,radius:float=3,degree:float=90,delta_degree:float=180) -> void:
	var _t0:float = bartime-radius*DUAL_SCALE
	if _t0<0:
		_t0 = 0
		radius = bartime/DUAL_SCALE
	degree = degree/180.0*PI
	delta_degree = degree + delta_degree/180.0*PI
	Arf._w(x+radius*cos(degree),y+radius*sin(degree),bartime-(radius*DUAL_SCALE)*0.0625,DUAL_TYPE).n(x,y,bartime).h(bartime)
	Arf._w(x+radius*cos(delta_degree),y+radius*sin(delta_degree),bartime-(radius*DUAL_SCALE)*0.0625,DUAL_TYPE,0.05).n(x,y,bartime)
