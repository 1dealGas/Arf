extends Arf
func fumen():

	Madeby("|·|·|  Inherited from Project Solace")

	Offset(0)
	BPM([
		0,198
	])
	Hispeed(0.73)

	forz(1)
	var p1:=[
		iw(5,1,1).n(5,1,1.375).n(7,1,2.8125,30).f(),
		iw(3,1,1.125).n(3,1,1.375).n(4,1,2.875,30).f(),
		iw(7,1,1.25).n(7,1,1.375).n(10,1,2.75,30).f(),
		iw(9,1,1.375).n(13,1,2.6875,30).f()
	]
	for i in p1:
		(i as WishGroup).copy(0,0,2).mirror_lr()
		(i as WishGroup).copy(0,0,4)
		(i as WishGroup).copy(0,0,6).mirror_lr()
	
	wid(6).r(1.625)
	wid(2).r(1.625+0.25)
	wid(8).r(1.625+0.5)
	wid(6).r(1.625+0.75)
	wid(2).r(1.625+1)
