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
		iw(5,1,1).n(5,1,1.375).n(7,1,2.8125+0.125,30).f(),
		iw(3,1,1.125).n(3,1,1.375).n(4,1,2.875+0.125,30).f(),
		iw(7,1,1.25).n(7,1,1.375).n(10,1,2.75+0.125,30).f(),
		iw(9,1,1.375).n(13,1,2.6875+0.125,30).f()
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

	wid(9).r(3.625)
	wid(27).r(3.625+0.25)
	wid(9).r(3.625+0.5)
	wid(21).r(3.625+0.625)
	wid(27).r(3.625+0.75)
	wid(15).r(3.625+1)

	wid(23).r(5.625)
	wid(11).r(5.625+0.25)
	wid(23).r(5.625+0.5)
	wid(17).r(5.625+0.75)
	wid(29).r(5.625+1)
	
	wid(19).r(7.625)
	wid(13).r(7.75)
	wid(25).r(7.875)
	wid(31).r(8)
	wid(25).r(8.25)
	wid(13).r(8.375)
	wid(19).r(8.625)
	wid(13).r(8.75)
