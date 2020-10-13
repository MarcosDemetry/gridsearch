**************************
*** Testing GridSearch ***
**************************

clear

** Programs **

capture program drop createCutOff drawLines

program createCutOff
	
	local cutoffByConstruction = `1'
	
	* Creating data with artificial cutoff for xVar
	set obs 100
	gen xVar = _n

	gen yVar = rnormal(x,2) if x <= `cutoffByConstruction'
	replace yVar = rnormal(`cutoffByConstruction',2) if x > `cutoffByConstruction'


end

program drawLines
	
	* Extracting values from gridsearch
	forvalues i = 0/2 {
		local b`i' = `r(b`i')'
	}

	local cutoff = `r(cutoff)'
	display `cutoff'

	gen line1 = `b0' + xVar*`b1' if xVar <= `cutoff'
	gen line2 =  `b0' + xVar*(`b1' + `b2') + `cutoff' if xVar >= `cutoff'

	* Plotting results
	twoway 	(scatter yVar xVar) ///
			(line line1 xVar) ///
			(line line2 xVar, ///
			legend(order(1 "Y Points" 2 "First line" 3 "Second Line")))

end



* Testing for arbitrary cut-off
createCutOff 50

gridsearch yVar xVar
quietly return list

drawLines
		
** Testing difference from cut-off **

matrix result = J(19,3,.)
local counter = 1
forvalues cutOff = 5(5)95 {
	clear 
	quietly createCutOff `cutOff'
	
	quietly gridsearch yVar xVar
	quietly return list
	
	local diff = (`r(cutoff)' - `cutOff')/`cutOff'
	
	matrix result[`counter',1] = `cutOff'
	matrix result[`counter',2] = `r(cutoff)'
	matrix result[`counter',3] = `diff'
	
	local counter = `counter' + 1
	
}

matlist result

svmat result, names(col)

twoway scatter c3 c1, xtitle("Cut-Off") ytitle("Difference from actual cut-off (%)")
