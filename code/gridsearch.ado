*! Version 1.0.0 1october2020

// Generalization of Statalist answer by Maarten Buis:
// https://www.statalist.org/forums/forum/general-stata-discussion/general/1511364-piecewise-regression


//-------------------\\
capture program drop gridsearch
// Main program
program define gridsearch, rclass

	syntax varlist

	local y "`1'"
	local x "`2'"
	
	// try a range of knots, and choose the knot with the lowest rmse
	sum `x', d

	local range = r(p95) - r(p5)
	local begin = r(p5)
	local finish = r(p95)
	local d = `range'/20

	tempname minrmse
	scalar `minrmse' = .

	forvalues i = `begin'(`d')`finish' {
		qui totry, c(`i') y("`y'") x("`x'")
		if e(rmse) < `minrmse' {
			scalar `minrmse' = e(rmse)
			local c  = r(c)
			local b0 = r(b0)
			local b1 = r(b1)
			local b2 = r(b2)

		}
	}

	// display those initial values
	di `c'
	totry, c(`c') y("`y'") x("`x'")

	// estimate the end result
	nl (`y' = {b0} + `x'*{b1} + (`x'>{c})*( `x'-{c})*{b2}), ///
	   variables(`x') initial(b0 `b0' b1 `b1' c `c' b2 `b2')


	return scalar cutoff 	= `c'
	return scalar b0		= `b0'
	return scalar b1		= `b1'
	return scalar b2		= `b2'
	
end

// compute the model for a fixed knot
capture program drop totry
program define totry, rclass

    syntax, c(real) y(string) x(string)
  	
	local y "`y'"
	local x "`x'"
	
    tempvar x2
    gen double `x2' = (`x' > `c')*(`x' - `c')
    reg `y' `x' `x2', vce(robust)
    return scalar c  = `c'
    return scalar b0 = _b[_cons]
    return scalar b1 = _b[`x']
    return scalar b2 = _b[`x2']
end


