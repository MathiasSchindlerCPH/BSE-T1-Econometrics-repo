/********************************************************/
/*														*/
/*	TITLE:		ASSIGNEMENT 7							*/
/*	COURSE: 	FOUNDATIONS OF ECONOMETRICS				*/
/* 	AUTHORS:	Schindler								*/
/*	DATE:		DEC 3, 2021								*/
/*														*/
/********************************************************/

clear all
cls

*	0) SET PATHS FOR IMPORTS/EXPORTS	
global data	"/Users/mathiasschindler/Library/Mobile Documents/com~apple~CloudDocs/BSE/T1_Econometrics/Assignments/Data"
global tab "/Users/mathiasschindler/Library/Mobile Documents/com~apple~CloudDocs/BSE/T1_Econometrics/Assignments/Figures"

*	0) LOAD DATA
use	"$data/assignment7", clear

*	0) NECESSARY PACKAGES
//ssc install _gwtmean

*******************************************************************************
/// 	[TRANSFORMING VARIABLES]				///
{
	
// Construct age Dummies
foreach i of numlist 29/64{ 	//<- Leaving age 28 out bc of dummy trap
	gen aged_`i' = (age == `i')
}
	sum aged_*
	drop aged_30 aged_31 aged_32 	//Bc. none aged 30, 31, 32

// Keep only British:								
keep if nireland == 0	

// Keep only those in 1983-1998 survey
// (I assume this is ''datyear'' -> not specified in assignment)	
keep if inrange(datyear,84,98)

// Save dataset
save "$data/assignment7_sample_for_regs", replace
}


*******************************************************************************
*** 	REPRODUCE FIG 4							***
{
preserve
	replace yearat14   = yearat14 + 1900
	
	keep if nireland == 0
	keep if inrange(age, 32, 64)
	bysort yearat14: egen wtavg_agelfted = wtmean(agelfted), weight(wght)
	
	reg wtavg_agelfted drop15 yearat14* [fweight = wght]
	
	gen agelfted_hat = .
foreach i of numlist 1935/1965{
	predict agelfted_hat_`i' if yearat14 == `i'
	replace agelfted_hat = agelfted_hat_`i' if yearat14 == `i'
	drop agelfted_hat_`i'
}	
	graph tw (scatter wtavg_agelfted yearat14) (line agelfted_hat yearat14 if yearat14 <1947, lwidth(.75) lcolor("green")) ///
		(line agelfted_hat yearat14 if yearat14 >=1947, lwidth(.75) lcolor("green")), xtitle("Year Aged 14") /// 
		ytitle("Avg. Age Left Full-Time Education") legend(order(1 "Local Average" 2 "Polynomial Fit")) ///
		xline(1947) ylabel(14(1)17) xlabel(1935(5)1965)
	//graph export "/Users/mathiasschindler/Library/Mobile Documents/com~apple~CloudDocs/BSE/T1_Econometrics/Assignments/Figures/asgnmnt7_oreopoulos2006_fig4_reprod.png", replace
restore
}	
	
*** 	REPRODUCE FIG 6							***
{
preserve
	replace yearat14   = yearat14 + 1900
	
	keep if nireland == 0
	keep if inrange(age, 32, 64)
	bysort yearat14: egen wtavg_lrearn = wtmean(learn), weight(wght)
	
	reg wtavg_lrearn drop15 yearat14* [fweight = wght] 

	gen learn_hat = .
foreach i of numlist 1935/1965{
	predict learn_hat_`i' if yearat14 == `i'
	replace learn_hat = learn_hat_`i' if yearat14 == `i'
	drop learn_hat_`i'
}	
	
	graph tw (scatter wtavg_lrearn yearat14) (line learn_hat yearat14 if yearat14 <1947, lwidth(.75) lcolor("green")) ///
		(line learn_hat yearat14 if yearat14 >=1947, lwidth(.75) lcolor("green")), xtitle("Year Aged 14") /// 
		ytitle("Log of Annual Earnings (1988 UK Pounds)") legend(order(1 "Local Average" 2 "Polynomial Fit")) ///
		xline(1947) ylabel(8.6(0.2)9.4) xlabel(1935(5)1965)
	//graph export "/Users/mathiasschindler/Library/Mobile Documents/com~apple~CloudDocs/BSE/T1_Econometrics/Assignments/Figures/asgnmnt7_oreopoulos2006_fig6_reprod.png", replace
restore
}



*******************************************************************************
*** 	REPRODUCE TAB 1	(for G. Britain)		***
{
use "$data/assignment7_sample_for_regs", clear	

// Keep only those for whom 'learn' is not N/A 
// - As recommended by Jacob
keep if  missing_earn == 0

***		FIRST STAGE

// Col 1 
reg agelfted drop15 yearat14* [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab1_reprod", replace tex ctitle("First 1") drop(yearat14*) nocons nor2


// Col 2 
reg agelfted drop15 yearat14* age age2 age3 age4 [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab1_reprod", append tex ctitle("First 2") drop(yearat14* age*) nocons nor2


// Col 3 
reg agelfted drop15 yearat14* aged_* [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab1_reprod", append tex ctitle("First 3") drop(yearat14* age* aged_*)  nocons nor2



***		REDUCED FORM

// Col 4 
reg learn drop15 yearat14* [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab1_reprod", append tex ctitle("Reduced 1") drop(yearat14*) nocons nor2


// Col 5
reg learn drop15 yearat14* age age2 age3 age4 [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab1_reprod", append tex ctitle("Reduced 2") drop(yearat14* age*) nocons nor2


// Col 6
reg learn drop15 yearat14* aged_* [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab1_reprod", append tex ctitle("Reduced 3") drop(yearat14* age* aged_*)  nocons nor2
}



*** 	REPRODUCE TAB 2	(for G. Britain)		***
{
use "$data/assignment7_sample_for_regs", clear

// Keep only those for whom 'learn' is not N/A 
// - As recommended by Jacob
keep if  missing_earn == 0

// Correct 'yearat14' variable
// (in order for RD-IV estimates to run)
//replace yearat14   = yearat14 - 1900

***		Returns to Schooling: OLS

// Col 1
reg learn agelfted yearat14* [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab2_reprod", replace tex ctitle("OLS 1") drop(yearat14*) nocons nor2 


// Col 2
reg learn agelfted yearat14* age age2 age3 age4 [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab2_reprod", append tex ctitle("OLS 2") drop(yearat14* age age2 age3 age4) nocons nor2 


// Col 3
reg learn agelfted yearat14* aged_* [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab2_reprod", append tex ctitle("OLS 3") drop(yearat14* aged_*) nocons nor2 



***		Returns to compulsory schooling: IV

// Col 4
ivregress 2sls learn yearat14* (agelfted = drop15) [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab2_reprod", append tex ctitle("IV 1") drop(yearat14*) nocons nor2 


// Col 5
ivregress 2sls learn yearat14* age age2 age3 age4 (agelfted = drop15) [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab2_reprod", append tex ctitle("IV 2") drop(yearat14* age age2 age3 age4) nocons nor2 


// Col 6
ivregress 2sls learn yearat14* aged_* (agelfted = drop15) [fweight = wght], vce(cluster yearat14)

outreg2 using "$tab/asgnmnt7_oreopoulos2006_tab2_reprod", append tex ctitle("IV 4") drop(yearat14* aged_*) nocons nor2 
}

