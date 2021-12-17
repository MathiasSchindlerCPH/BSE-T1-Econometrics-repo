/********************************************************/
/*														*/
/*	TITLE:		ASSIGNEMENT 6							*/
/*	COURSE: 	FOUNDATIONS OF ECONOMETRICS				*/
/* 	AUTHORS:	Schindler								*/
/*	DATE:		NOV 12, 2021							*/
/*														*/
/********************************************************/

clear all
cls

*	0) SET PATHS FOR IMPORTS/EXPORTS	
global data	"/Users/mathiasschindler/Library/Mobile Documents/com~apple~CloudDocs/BSE/T1_Econometrics/Assignments/Data"

*	0) LOAD DATA
use	"$data/assignment6", clear


*******************************************************************************
*** 	TRANSFORMING VARIABLES		***
/*DROP UNNECESSARY VARIABLES*/
keep id year female annual_salary stay separation mass_layoff year_brth

/* LOG WAGES:   */
gen log_wage = ln(annual_salary)
order log_wage, a(annual_salary)
drop annual_salary

/* COVARIATES  */
** Gender:
tab female,m 

** Decade of birth-dummies:
foreach i of numlist 1950 1960{
	gen brth_dec_`i' = ( inrange(year_brth, `i', `i'+9))
}
	gen brth_dec_1970 = ( year_brth >= 1970) //<- to incl the few born in '80, '81
drop year_brth

** 1995 earnings decile dummies
xtile wage_dcl = log_wage if year == 1995, nq(10) 
bysort id: egen  wage_1995_dcl = max(wage_dcl)
drop wage_dcl

foreach i of numlist 1/10{
	gen wage_1995_dcl`i' = inlist(wage_1995_dcl, `i')
	//replace wage_1995_dcl`i' = . if wage_1995_dcl == .
	gen fem_wagedcl`i' = female*wage_1995_dcl`i'
}
order fem_wagedcl*, last

drop wage_1995_dcl


/* TIME INDICATOR  */
// (Time of displacement is measured in 1999 according to the instructions)
gen t = 0 if year == 1999
order t, a(year)

foreach i of numlist -4 -3 -2 -1 1 2{
	replace t = `i' if year == (1999 + `i')
}


/* GLOBAL FOR COVARIATES  */
// Always supress 1 dummy pr. category to avoid dummy trap
global xvars female /*brth_dec_1950*/ brth_dec_1960 brth_dec_1970 /*wage_1995_dcl1 */		///
wage_1995_dcl2 wage_1995_dcl3 wage_1995_dcl4 wage_1995_dcl5 wage_1995_dcl6 wage_1995_dcl7	///
wage_1995_dcl8 wage_1995_dcl9 wage_1995_dcl10 /*fem_wagedcl1*/ fem_wagedcl2 fem_wagedcl3	///
fem_wagedcl4 fem_wagedcl5 fem_wagedcl6 fem_wagedcl7 fem_wagedcl8 fem_wagedcl9 fem_wagedcl10

/* CHECK FOR MISSING VARIABLES  */
mdesc //None



*******************************************************************************
/* QUESTION 1: BALANCING PROPERTY */
// Chosen arbitrary year: 1996
pscore separation $xvars if year == 1996, pscore(pscore_sep_1996) logit 
pscore mass_layoff $xvars if year == 1996, pscore(pscore_mass_1996) logit
*NB: "if year == 1996" bc. we should do it for "arbitrarily chosen year"



******************************************************************************
/* QUESTION 2: ATT */
/* CONSTRUCT TIME BEFORE/AFTER TREATMENT  */

//Nearest-neighbor (for separation):
gen attnd_sep = .

foreach i of numlist 1996/2001{
	di "Nearest Neighbor matching method for year: `i'" 
	attnd log_wage separation $xvars if year == `i', comsup logit
	
	replace attnd_sep = r(attnd) if year == `i'
}

//Nearest-neighbor (for mass-layoff):
gen attnd_mass = .

foreach i of numlist 1996/2001{
	di "Nearest Neighbor matching method for year: `i'" 
	attnd log_wage mass_layoff $xvars if year == `i', comsup logit
	
	replace attnd_mass = r(attnd) if year == `i'
}


//Kernel (for separation):
gen attk_sep = .

foreach i of numlist 1996/2001{
	di "Kernel matching method for year: `i'" 
	attk log_wage separation $xvars if year == `i', comsup logit
	
	replace attk_sep = r(attk) if year == `i'
}

//Kernel (for mass-layoff):
gen attk_mass = .

foreach i of numlist 1996/2001{
	di "Kernel matching method for year: `i'" 
	attk log_wage mass_layoff $xvars if year == `i', comsup logit
	
	replace attk_mass = r(attk) if year == `i'
}



*******************************************************************************
/* QUESTION 3: DATT */

//Define salary in 1995 for each individual
gen an_sal_95 = log_wage if year == 1995
by id: egen annual_salary_95 = max(an_sal_95) 
drop an_sal_95

//Generate difference in income relative to 1995
foreach i of numlist 1996/2001{
	gen d_income_`i' = log_wage - annual_salary_95 if year == `i'
}


//Nearest-neighbor (for separation):
gen dattnd_sep = .

foreach i of numlist 1996/2001{
	di "Nearest Neighbor matching method for year: `i'" 
	attnd d_income_`i' separation $xvars if year == `i', comsup logit
	
	replace dattnd_sep = r(attnd) if year == `i'
}

//Nearest-neighbor (for mass-layoff):
gen dattnd_mass = .

foreach i of numlist 1996/2001{
	di "Nearest Neighbor matching method for year: `i'" 
	attnd d_income_`i' mass_layoff $xvars if year == `i', comsup logit
	
	replace dattnd_mass = r(attnd) if year == `i'
}


//Kernel (for separation):
gen dattk_sep = .

foreach i of numlist 1996/2001{
	di "Kernel matching method for year: `i'" 
	attk d_income_`i' separation $xvars if year == `i', comsup logit
	
	replace dattk_sep = r(attk) if year == `i'
}

//Kernel (for separation):
gen dattk_mass = .

foreach i of numlist 1996/2001{
	di "Kernel matching method for year: `i'" 
	attk d_income_`i' mass_layoff $xvars if year == `i', comsup logit
	
	replace dattk_mass = r(attk) if year == `i'
}

drop d_income_*
drop annual_salary_95


*******************************************************************************
/* QUESTION 4: GRAPHING RESULTS */
collapse att* datt*, by(t)
drop if _n == 1
export excel using "/Users/mathiasschindler/Library/Mobile Documents/com~apple~CloudDocs/BSE/T1_Econometrics/Assignments/Data/assignment6_constructeddata_msch.xlsx", firstrow(var)

graph tw (connected attnd_sep t)  (connected attnd_mass t), name(att_nn_graph, replace) ///
			title("ATT (Nearest Neighbor)") ///
			legend(col(1) lab(1 "Separated") lab(2 "Mass-layoff"))			
			
graph tw (connected attk_sep t)  (connected attk_mass t), name(att_k_graph, replace) ///
			title("ATT (Kernel)") ///
			legend(col(1) lab(1 "Separated") lab(2 "Mass-layoff"))

			
graph tw (connected dattnd_sep t)  (connected dattnd_mass t), name(datt_nn_graph, replace) ///
			title("Differenced ATT (Nearest Neighbor)") ///
			legend(col(1) lab(1 "Separated") lab(2 "Mass-layoff"))
			
graph tw (connected dattk_sep t)  (connected dattk_mass t), name(datt_k_graph, replace) ///
			title("Differenced ATT (Kernel)") ///
			legend(col(1) lab(1 "Separated") lab(2 "Mass-layoff"))

			
grc1leg 	att_nn_graph  att_k_graph	datt_nn_graph 	 datt_k_graph			
			
			
			
			
/*
graph tw (connected attnd_sep t)  (connected  attk_sep t)				///
		 (connected attnd_mass t) (connected  attk_mass t)				///
		, name(att_graph, replace) ///
		title("ATT") ///
		legend(col(1) lab(1 "Separated (nn)") lab(2 "Separated (kernel)") lab(3 "Mass-layoff (nn)") lab(4 "Mass-layoff (kernel)"))
	
	
graph tw (connected dattnd_sep t)  (connected  dattk_sep t)					///
		 (connected dattnd_mass t) (connected  dattk_mass t)				///
		, name(att_graph, replace) ///
		title("Differenced ATT") ///
		legend(col(1) lab(1 "Separated (nn)") lab(2 "Separated (kernel)") lab(3 "Mass-layoff (nn)") lab(4 "Mass-layoff (kernel)"))

graph combine att_graph datt_graph
*/



