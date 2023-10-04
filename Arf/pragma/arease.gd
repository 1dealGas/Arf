extends Node
class_name ArEase

enum {
	xLinear_yLinear = 0,
	xLinear_yInCirc = 1,
	xLinear_yOutCirc = 2,
	xLinear_yInQuad = 3,
	xLinear_yOutQuad = 4,
	xLinear_yInQuart = 5,
	xLinear_yOutQuart = 6,
	xInCirc_yLinear = 10,
	xInCirc_yInCirc = 11,
	xInCirc_yOutCirc = 12,
	xInCirc_yInQuad = 13,
	xInCirc_yOutQuad = 14,
	xInCirc_yInQuart = 15,
	xInCirc_yOutQuart = 16,
	xOutCirc_yLinear = 20,
	xOutCirc_yInCirc = 21,
	xOutCirc_yOutCirc = 22,
	xOutCirc_yInQuad = 23,
	xOutCirc_yOutQuad = 24,
	xOutCirc_yInQuart = 25,
	xOutCirc_yOutQuart = 26,
	xInQuad_yLinear = 30,
	xInQuad_yInCirc = 31,
	xInQuad_yOutCirc = 32,
	xInQuad_yInQuad = 33,
	xInQuad_yOutQuad = 34,
	xInQuad_yInQuart = 35,
	xInQuad_yOutQuart = 36,
	xOutQuad_yLinear = 40,
	xOutQuad_yInCirc = 41,
	xOutQuad_yOutCirc = 42,
	xOutQuad_yInQuad = 43,
	xOutQuad_yOutQuad = 44,
	xOutQuad_yInQuart = 45,
	xOutQuad_yOutQuart = 46,
	xInQuart_yLinear = 50,
	xInQuart_yInCirc = 51,
	xInQuart_yOutCirc = 52,
	xInQuart_yInQuad = 53,
	xInQuart_yOutQuad = 54,
	xInQuart_yInQuart = 55,
	xInQuart_yOutQuart = 56,
	xOutQuart_yLinear = 60,
	xOutQuart_yInCirc = 61,
	xOutQuart_yOutCirc = 62,
	xOutQuart_yInQuad = 63,
	xOutQuart_yOutQuad = 64,
	xOutQuart_yInQuart = 65,
	xOutQuart_yOutQuart = 66,
	Partial_xLinear_yLinear = 0,
	Partial_xInQuad_yLinear = 1049576,
	Partial_xInCirc_yLinear = 2098152,
	Partial_xSine_yLinear = 3146728,
	Partial_xLinear_yInQuad = 4195304,
	Partial_xLinear_yInCirc = 5243880,
	Partial_xLinear_ySine = 6292456,
	Partial_xInQuad_yInQuad = 7341032,
	Partial_xOutQuad_yLinear = 2072576,
	Partial_xOutCirc_yLinear = 3121152,
	Partial_xCosine_yLinear = 4169728,
	Partial_xLinear_yOutQuad = 5218304,
	Partial_xLinear_yOutCirc = 6266880,
	Partial_xLinear_yCosine = 7315456,
	Partial_xOutQuad_yOutQuad = 8364032,
	Cam_Linear = 0,
	Cam_InCirc = 1,
	Cam_OutCirc = 2,
	Cam_InQuad = 3,
	Cam_OutQuad = 4,
	Cam_InQuart = 5,
	Cam_OutQuart = 6,
	Custom_xInQuad = 1,
	Custom_xInCirc = 2,
	Custom_xSine = 3,
	Custom_yInQuad = 4,
	Custom_yInCirc = 5,
	Custom_ySine = 6,
	Custom_xyInQuad = 7,
	Custom_xOutQuad = 8,
	Custom_xOutCirc = 9,
	Custom_xCosine = 10,
	Custom_yOutQuad = 11,
	Custom_yOutCirc = 12,
	Custom_yCosine = 13,
	Custom_xyOutQuad = 14
}

const IPI:float = PI/2
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

static var PE:Array[float] = [0,0]
static func PartialEASE(ratio:float,type:int) -> Array[float]:
	
	# Decode type
	var ArER:int = type & 0x3ff
	type = type >> 10
	var ArIR:int = type & 0x3ff
	type = type >> 10
	
	# Check for Reversed Status
	var Reversed:bool = false
	if ArIR > ArER:
		ArIR = ArIR ^ ArER
		ArER = ArIR ^ ArER
		ArIR = ArIR ^ ArER
		Reversed = true
	var RX:float = ( ArIR + (ArER-ArIR)*ratio ) / 1000.0
	var RY:float = RX
	
	# Calculate RX,RY by the type. GDScript's match is quite slow there.
	if Reversed:
		if type == 1:  # xOutQuad
			RX = 1 - RX
			RX = 1 - RX * RX
		elif type == 2:  # xOutCirc
			RX = 1 - RX
			RX = sqrt( 1 - RX * RX )
		elif type == 3:  # xCosine
			RX = cos( RX * IPI )
		elif type == 4:  # yOutQuad
			RY = 1 - RY
			RY = 1 - RY * RY
		elif type == 5:  # yOutCirc
			RY = 1 - RY
			RY = sqrt( 1 - RY * RY )
		elif type == 6:  # yCosine
			RY = cos( RY * IPI )
		elif type == 7:  # xyOutQuad
			RX = 1 - RX
			RX = 1 - RX * RX
			RY = RX
	else:
		if type == 1:  # xInQuad
			RX = RX * RX
		elif type == 2:  # xInCirc
			RX = 1 - RX * RX
			RX = 1 - sqrt(RX)
		elif type == 3:  # xSine
			RX = sin( RX * IPI )
		elif type == 4:  # yInQuad
			RY = RY * RY
		elif type == 5:  # yInCirc
			RY = 1 - RY * RY
			RY = 1 - sqrt(RY)
		elif type == 6:  # ySine
			RY = sin( RY * IPI )
		elif type == 7:  # xyInQuad
			RX = RX * RX
			RY = RX
		
	PE[0] = RX
	PE[1] = RY
	return PE

static var decode_result:Array = [0,0,0,false]
static func decode_ease(type:int) -> Array:
	
	# Decode type
	var ArER:int = type & 0x3ff
	type = type >> 10
	var ArIR:int = type & 0x3ff
	type = type >> 10
	
	# Check for Reversed Status
	if ArIR > ArER:
		ArIR = ArIR ^ ArER
		ArER = ArIR ^ ArER
		ArIR = ArIR ^ ArER
		decode_result[3] = true
	else: decode_result[3] = false
	
	decode_result[0] = type
	decode_result[1] = ArIR / 1000.0
	decode_result[2] = ArER / 1000.0
	return decode_result

# (E)ncode (C)ustom PartialEase
static func ec(custom_type:int,init_ratio:float,end_ratio:float) -> int:
	assert( custom_type>0 and custom_type<15, "custom_type must be ArEase.Custom_* ." )
	custom_type = clampi(custom_type,1,14)
	init_ratio = clampf(init_ratio,0,1)
	end_ratio = clampf(end_ratio,0,1)
	var ArIR:int = int( (init_ratio+0.0005)*1000 )
	var ArER:int = int( (end_ratio+0.0005)*1000 )
	if init_ratio > end_ratio:
		print( "Line %d: Argument init_ratio is greater than Argument end_ratio. Arf swaped them implicitly." % get_stack()[1].line )
		ArIR ^= ArER
		ArER ^= ArIR
		ArIR ^= ArER
	if custom_type > 7:
		custom_type -= 7
		ArIR ^= ArER
		ArER ^= ArIR
		ArIR ^= ArER
	return custom_type*1048576+ArIR*1024+ArER

static func split_pe_former(stored_type:int,stored_ratio:float) -> int:
	var dresult:Array = decode_ease(stored_type)
	dresult[2] = dresult[1] + (dresult[2] - dresult[1]) * stored_ratio
	if dresult[3]: return ec(dresult[0]+7, dresult[1], dresult[2])
	else: return ec(dresult[0], dresult[1], dresult[2])
	
static func split_pe_latter(stored_type:int,stored_ratio:float) -> int:
	var dresult:Array = decode_ease(stored_type)
	dresult[1] = dresult[1] + (dresult[2] - dresult[1]) * stored_ratio
	if dresult[3]: return ec(dresult[0]+7, dresult[1], dresult[2])
	else: return ec(dresult[0], dresult[1], dresult[2])

static func slice_pe(stored_type:int,stored_init:float,stored_end:float) -> int:
	stored_init = clampf(stored_init,0,1)
	stored_end = clampf(stored_end,0,1)
	var dresult:Array = decode_ease(stored_type)
	var delta:float = dresult[2] - dresult[1]
	stored_init = dresult[1] + delta*stored_init
	stored_end = dresult[1] + delta*stored_end
	if dresult[3]: return ec(dresult[0]+7, stored_init, stored_end)
	else: return ec(dresult[0], stored_init, stored_end)
