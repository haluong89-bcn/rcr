capture log close
local tmp = c(current_date)
log using "rcr_certification `tmp'", text replace
/*******************************************************************
* RCR_CERTIFICATION.DO
*
* This is a do-file designed to provide a detailed test of the RCR
* program, including its optional arguments and postestimation 
* commands.  
*
* Change log:
*
*	5/17/2010	Created
*	5/19/2010	Small changes to comments; added current date to name of logfile.
*	5/25/2010	Substantial changes to various asserts to account for the changes
*                 in precision of calculation for version 0.9.07.
*   6/24/2011	Added code to test DETAILS option and RCRPLOT command, version 0.9.13.
*   8/9/2011    Added code to test LOWER and UPPER options for CITYPE, version 0.9.14.
*   5/11/2015   Changes to accommodate updated variable names (e.g., betax instead of theta), version 1.9.
*
*
********************************************************************/
clear all
set mem 400m
set more off
cscript "Testing script for RCR and its postestimation commands" adofiles rcr rcr_estat rcr_predict

use rcr_example, clear
/* Generate some handy values */
quietly gen zero = 0
quietly gen one = 1
quietly gen two = 2
set seed 53
forvalues i = 1 / 20 {
	quietly gen x`i' = runiform()
}
quietly egen ID = seq()
quietly gen SAT1000 = SAT*1000
quietly gen SAT0001 = SAT*0.0001
quietly gen Small_Class1000 = Small_Class*1000
quietly gen Small_Class0001 = Small_Class*0.0001

/*******************************************************************
* Basic regression with default options 
********************************************************************/
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree
est store basic

/* Compare against saved results - these were generated by calling "mkassert eclass" */
assert `"`e(_estimates_name)'"' == `"basic"'
assert `"`e(cmd)'"'             == `"rcr"'
assert `"`e(citype)'"'          == `"Conservative"'
_assert_streq `"`e(ctrlvar)'"' `" White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree"'
assert `"`e(treatvar)'"'        == `"Small_Class"'
assert `"`e(depvar)'"'          == `"SAT"'
assert `"`e(predict)'"'         == `"rcr_predict"'
assert `"`e(estat_cmd)'"'       == `"rcr_estat"'
assert `"`e(title)'"'           == `"RCR model"'
assert `"`e(properties)'"'      == `"b V"'
assert reldif( e(betaxCI_H)  , 6.488085264868137 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.259480713112168 ) <  1E-8
assert         e(cilevel)   == 95
assert         e(lambdaH)   == 1
assert         e(lambdaL)   == 0
assert         e(N)         == 5839
tempname T_b 
mat `T_b' = J(1,5,0)
mat `T_b'[1,1] =    12.310599093114
mat `T_b'[1,2] =  8.169709964978111
mat `T_b'[1,3] =   28.9354891702633
mat `T_b'[1,4] =   5.13504376498382
mat `T_b'[1,5] =   5.20150257358542
tempname C_b
matrix `C_b' = e(b)
assert mreldif( `C_b' , `T_b' ) < 1E-8
_assert_streq `"`: rowfullnames `C_b''"' `"y1"'
_assert_streq `"`: colfullnames `C_b''"' `"lambdaInf betaxInf lambda0 betaxL betaxH"'
mat drop `C_b' `T_b'
tempname T_V 
mat `T_V' = J(5,5,0)
mat `T_V'[1,1] =  4.402731051063719
mat `T_V'[1,2] =  1.680910570472625
mat `T_V'[1,3] =  14.86034005429277
mat `T_V'[1,4] =  .0262163576425921
mat `T_V'[1,5] =  .0148105705706819
mat `T_V'[2,1] =  1.680910570472625
mat `T_V'[2,2] =  936.8160737460918
mat `T_V'[2,3] = -3305.544936154673
mat `T_V'[2,4] = -20.86047836198298
mat `T_V'[2,5] =  .0945995722412722
mat `T_V'[3,1] =  14.86034005429277
mat `T_V'[3,2] = -3305.544936154673
mat `T_V'[3,3] =  11776.47628212536
mat `T_V'[3,4] =  76.32135272938001
mat `T_V'[3,5] =  2.093295479416368
mat `T_V'[4,1] =  .0262163576425921
mat `T_V'[4,2] = -20.86047836198298
mat `T_V'[4,3] =  76.32135272938001
mat `T_V'[4,4] =  .9157293949360822
mat `T_V'[4,5] =  .4385652205906294
mat `T_V'[5,1] =  .0148105705706819
mat `T_V'[5,2] =  .0945995722412722
mat `T_V'[5,3] =  2.093295479416368
mat `T_V'[5,4] =  .4385652205906294
mat `T_V'[5,5] =  .4309027113843122
tempname C_V
matrix `C_V' = e(V)
assert mreldif( `C_V' , `T_V' ) < 1E-8
_assert_streq `"`: rowfullnames `C_V''"' `"lambdaInf betaxInf lambda0 betaxL betaxH"'
_assert_streq `"`: colfullnames `C_V''"' `"lambdaInf betaxInf lambda0 betaxL betaxH"'
mat drop `C_V' `T_V'
/* End comparison */

/*******************************************************************
* Basic regression with rescaling
********************************************************************/
est replay basic
/* Rescaling both, should leave results roughly unchanged */
rcr SAT1000 Small_Class1000 White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree
assert reldif( e(betaxCI_H)  , 6.488093355120499 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.259476500967557 ) <  1E-8
rcr SAT0001 Small_Class0001 White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree 
assert reldif( e(betaxCI_H)  , 6.488085194193078 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.259481216660567 ) <  1E-8
/* Scaling outcome up or treatment down, either should multiply coefficient by 1000 */
rcr SAT1000 Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree
assert reldif( e(betaxCI_H)  , 6488.085284518956 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3259.481232785231 ) <  1E-8
rcr SAT Small_Class0001 White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree
assert reldif( e(betaxCI_H)  , 64871.83283612684 ) <  1E-8
assert reldif( e(betaxCI_L)  , 32607.22424757308 ) <  1E-8
/* Scaling outcome down or treatment up, either should multiply coefficient by 0.0001 */
rcr SAT0001 Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree
assert reldif( e(betaxCI_H)  , .0006488085303737 ) <  1E-8
assert reldif( e(betaxCI_L)  , .000325948074516  ) <  1E-8
rcr SAT Small_Class1000 White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree
assert reldif( e(betaxCI_H)  , .0064880852473763 ) <  1E-8
assert reldif( e(betaxCI_L)  , .0032594807011477 ) <  1E-8

/*******************************************************************
* Basic regression with different explanatory variables 
********************************************************************/
/***** Things that should produce an error message *****/
/* No treatment or control variable.  Should (and does) produce an error message. */
rcof "noisily rcr SAT" == 102
/* No control variable.  Should (and does) produce an error message. */
rcof "noisily rcr SAT Small_Class" == 102
/* Outcome variable doesn't vary */
rcof "noisily rcr zero Small_Class White_Asian" == 1
/* Treatment variable doesn't vary */
rcof "noisily rcr SAT zero White_Asian" == 1
/* Control variable doesn't vary */
rcof "noisily rcr SAT Small_Class zero" == 1
/* Collinearity among control variables  */
rcof "noisily rcr SAT Small_Class White_Asian zero" == 1
rcof "noisily rcr SAT Small_Class White_Asian White_Asian" == 1
/* More than 25 control variables */
rcof "noisily rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree x1-x20" == 103

/***** Things that should produce a warning message but give it a try *****/
/* Outcome and treatment are identical (collinear) */
rcof "noisily rcr SAT SAT White_Asian" == 0
/* Treatment and control are identical (collinear) */
rcof "noisily rcr SAT Small_Class Small_Class" == 0
/* Outcome and control are identical (collinear) */
rcof "noisily rcr SAT Small_Class SAT" == 0
/* Outcome and control are exactly unrelated */
/* This leads to an error in RCR.EXE.  It would be nice to catch it in the ado-file */
preserve
keep SAT Small_Class
tempfile tmp
quietly gen unrelated_variable = 1
quietly save `tmp', replace
quietly replace unrelated_variable = 0
quietly append using `tmp'
rcof "noisily rcr SAT Small_Class unrelated_variable" == 1
restore

/***** Things that should work *****/
/* Just one control variable */
rcr SAT Small_Class White_Asian
assert reldif( e(betaxCI_H)  , 6.494755100453821 ) <  1E-8
assert reldif( e(betaxCI_L)  , 2.893150619179314 ) <  1E-8
/* Up to 25 control variables */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree x1-x19
assert reldif( e(betaxCI_H)  , 7.341531127530879 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.976272660323884 ) <  1E-8

/*******************************************************************
* IF/IN/WEIGHT options
********************************************************************/
/* IF */
/* This specification should work */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree if  Free_Lunch > 0
assert reldif( e(betaxCI_H)  , 8.284396403084376 ) <  1E-8
assert reldif( e(betaxCI_L)  , 4.126516220297534 ) <  1E-8
/* This specification excludes all observations and (properly) produces an error message */
rcof "noisily rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree if  Free_Lunch>2" == 2000

/* IN */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree in 1/100  
assert reldif( e(betaxCI_H)  , 27.26163444874422 ) <  1E-8
assert reldif( e(betaxCI_L)  , .9203357905110554 ) <  1E-8
/* These two specifications exclude too many observations.  They should produce an error message.*/
rcof "noisily rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree in 1/1" == 2001
rcof "noisily rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree in 1/3" == 2001

/* WEIGHT */
/* Unweighted, for comparison */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree
savedresults save unweighted e()
/* FW=frequency weights, should lead to double the number of observations and smaller SE's */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree [fw = two]
assert reldif( e(betaxCI_H)  , 6.111214963474101 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.808877201524171 ) <  1E-8
/* PW=probability weights, should lead to same number of observations and same SE's */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree [pw = two]
assert reldif( e(betaxCI_H)  , 6.488085264868134 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.259480713112181 ) <  1E-8
/* AW=analytic weights, should lead to same number of observations and same SE's */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree [aw = two]
assert reldif( e(betaxCI_H)  , 6.488085264868134 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.259480713112181 ) <  1E-8
/* IW=importance weights, should lead to double the number of observations and smaller SE's */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree [iw = two]
assert reldif( e(betaxCI_H)  , 6.111214963474101 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.808877201524171 ) <  1E-8
/* With weights, but all weights set to one.  This should generate the same results as unweighted */
quietly rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree [fw = one]
savedresults compare unweighted e()
quietly rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree [aw = one]
savedresults compare unweighted e()
savedresults drop unweighted

/*******************************************************************
* CLUSTER option
********************************************************************/
/* No clustering, for comparison */
est replay basic
/* Clustering on group */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, cluster(TCHID)
assert reldif( e(betaxCI_H)  , 7.221434897597197 ) <  1E-8
assert reldif( e(betaxCI_L)  , 2.472053399759639 ) <  1E-8
/* Clustering on individual ID. Should give the same result as no clustering */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, cluster(ID)
assert reldif( e(betaxCI_H)  , 6.488085264868137 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.259480713112168 ) <  1E-8
/* Clustering on a constant. Should give missing standard errors and (-inf,+inf) as the CI */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, cluster(zero)
assert         e(betaxCI_L) < -8.99e+305
assert         e(betaxCI_H) > -8.99e+305

/*******************************************************************
* VCEADJ option
********************************************************************/
/* No adjustment, for comparison */
est replay basic
/* Quadruple the covariance matrix (should double the standard errors) */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, vceadj(4.0)
assert reldif( e(betaxCI_H)  , 7.774667956150855 ) <  1E-8
assert reldif( e(betaxCI_L)  , 1.383917661240516 ) <  1E-8
/* Zero.  Should make the standard errors zero. */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, vceadj(0.0)
tempname T_V 
mat `T_V' = J(5,5,0)
tempname C_V
matrix `C_V' = e(V)
assert mreldif( `C_V' , `T_V' ) < 1E-8
/* Negative.  Should produce an error message */
rcof "noisily rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, vceadj(-6)" == 111

/*******************************************************************
* LAMBDA option
********************************************************************/
/* Default lambda, for comparison */
est replay basic
/* Specified at default (should be identical) */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, lambda(0 1)
assert reldif( e(betaxCI_H)  , 6.488085264868137 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.259480713112168 ) <  1E-8
/* A single point (should give the same value for betaxH and betaxL */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, lambda(0 0)
assert reldif( e(betaxCI_H)  , 6.488085264868137 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.914919882302702 ) <  1E-8
/* Going from -infinity */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, lambda(. 0)
assert reldif( e(betaxCI_H)  , 12.30252920699166 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.914919882302702 ) <  1E-8
/* Going to +infinity */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, lambda(0 .)
assert         e(betaxCI_H) > 8.99e+305
assert         e(betaxCI_L) < -8.99e+305
/* Going from -infinity to +infinity */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, lambda(. .)
assert         e(betaxCI_H) > 8.99e+305
assert         e(betaxCI_L) < -8.99e+305
/* Just below lambdaInf */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, lambda(0 12.3)
assert reldif( e(betaxCI_H)  , 6.488085264868137 ) <  1E-8
assert reldif( e(betaxCI_L)  , -18.08208794130959) <  1E-8
/* Just above lambdaInf */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, lambda(12 12.32)
assert         e(betaxCI_H) > 8.99e+305
assert         e(betaxCI_L) < -8.99e+305

/*******************************************************************
* LEVEL option
********************************************************************/
/* Default level (i.e. 95) */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree
assert reldif( e(betaxCI_H)  , 6.488085264868137 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.259480713112168 ) <  1E-8
/* Specify same level as default (should get same result) */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, level(95)
assert reldif( e(betaxCI_H)  , 6.488085264868137 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.259480713112168 ) <  1E-8
/* Now replay with a different level */
/* Doing this will leave the current results in e() unchanged, but report new levels and put them in r() */
rcr, level(90)
assert reldif( e(betaxCI_H)  , 6.488085264868137 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.259480713112168 ) <  1E-8
assert reldif( r(betaxCI_H)  , 6.281236804837625 ) <  1E-8
assert reldif( r(betaxCI_L)  , 3.561021633566327 ) <  1E-8
/* Estimate with that level. Should get same result, but now stored in e(). */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, level(90)
assert reldif( e(betaxCI_H)  , 6.281236804837625 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.561021633566327 ) <  1E-8

/*******************************************************************
* CITYPE option
********************************************************************/
est replay basic
/* Specify the same citype as default (result should be the same) */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, citype("conservative")
assert reldif( e(betaxCI_H)  , 6.488085264868137 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.259480713112168 ) <  1E-8
/* Specify Imbens-Manski (should be narrower than default) */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, citype("imbens-manski")
assert reldif( e(betaxCI_H)  , 6.466066180253211 ) <  1E-8
assert reldif( e(betaxCI_L)  , 3.291579840373562 ) <  1E-8
/* Specify Lower. */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, citype("lower")
assert reldif( r(betaxCI_H)  , 6.281236804837625 ) <  1E-8
assert         r(betaxCI_L) < -8.0e+306
/* Specify Upper. */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, citype("upper")
assert         r(betaxCI_H) > 8.0e+306
assert reldif( r(betaxCI_L)  , 3.561021633566327 ) <  1E-8
/* Specify NONSENSE (or any other unsupported type).  Should generate a warning message and a missing CI */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, citype("NONSENSE")
assert         e(betaxCI_L) == .
assert         e(betaxCI_H) == .

/*******************************************************************
* SAVE option (undocumented)
********************************************************************/
/* This option tells stata to create files called in.txt, out.txt, and log.txt */
/* First delete those files if they already exist */
capture erase in.txt
capture erase out.txt
capture erase log.txt
/* Second, run the command with the option included */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, save
/* Finally, check for existence of the files */
confirm file in.txt
confirm file out.txt
confirm file log.txt

/*******************************************************************
* NLCOM , TESTNL postestimation commands
********************************************************************/
est restore basic
/* Testing TESTNL */
testnl _b[betaxH] = 0
assert reldif( r(chi2)  , 62.78825430596226 ) <  1E-8
/* Testing NLCOM */
nlcom _b[betaxH]-_b[betaxL]
tempname b b1 v v1
matrix `b' = r(b)
scalar `b1' = `b'[1,1]
assert reldif( `b1' , .0664588086015998) < 1E-8
matrix `v' = r(V)
scalar `v1' = `v'[1,1]
assert reldif( `v1' , .4695016651521872) < 1E-8
mat drop `b' `v'
scalar drop `b1' `v1'
/* What happens if the parameters are not identified? */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, lambda(. .)
testnl _b[betaxH] = 0
assert         r(p)    == .
assert         r(chi2) == 0
assert         r(df)   == 0
nlcom _b[betaxH]-_b[betaxL]
tempname T_b 
mat `T_b'=   1.7976931340e+307
tempname C_b
matrix `C_b' = r(b)
assert mreldif( `C_b' , `T_b' ) < 1E-8
mat drop `C_b' `T_b'

/*******************************************************************
* ESTAT postestimation commands
********************************************************************/
est restore basic
estat vce

tempname T_V 
mat `T_V' = J(5,5,0)
mat `T_V'[1,1] =  4.402731051063719
mat `T_V'[1,2] =  1.680910570472625
mat `T_V'[1,3] =  14.86034005429277
mat `T_V'[1,4] =  .0262163576425921
mat `T_V'[1,5] =  .0148105705706819
mat `T_V'[2,1] =  1.680910570472625
mat `T_V'[2,2] =  936.8160737460918
mat `T_V'[2,3] = -3305.544936154673
mat `T_V'[2,4] = -20.86047836198298
mat `T_V'[2,5] =  .0945995722412722
mat `T_V'[3,1] =  14.86034005429277
mat `T_V'[3,2] = -3305.544936154673
mat `T_V'[3,3] =  11776.47628212536
mat `T_V'[3,4] =  76.32135272938001
mat `T_V'[3,5] =  2.093295479416368
mat `T_V'[4,1] =  .0262163576425921
mat `T_V'[4,2] = -20.86047836198298
mat `T_V'[4,3] =  76.32135272938001
mat `T_V'[4,4] =  .9157293949360822
mat `T_V'[4,5] =  .4385652205906294
mat `T_V'[5,1] =  .0148105705706819
mat `T_V'[5,2] =  .0945995722412722
mat `T_V'[5,3] =  2.093295479416368
mat `T_V'[5,4] =  .4385652205906294
mat `T_V'[5,5] =  .4309027113843122
tempname C_V
matrix `C_V' = r(V)
assert mreldif( `C_V' , `T_V' ) < 1E-8
_assert_streq `"`: rowfullnames `C_V''"' `"lambdaInf betaxInf lambda0 betaxL betaxH"'
_assert_streq `"`: colfullnames `C_V''"' `"lambdaInf betaxInf lambda0 betaxL betaxH"'
mat drop `C_V' `T_V'

estat summarize
tempname T_stats 
mat `T_stats' = J(8,4,0)
mat `T_stats'[1,1] =  51.44962197971362
mat `T_stats'[1,2] =  23.29444665859316
mat `T_stats'[1,3] = -15.76239002946902
mat `T_stats'[1,4] =    127.28907462949
mat `T_stats'[2,1] =  .3024490494947765
mat `T_stats'[2,2] =  .4537342203017396
mat `T_stats'[2,3] = -.1323335592008756
mat `T_stats'[2,4] =   1.13789208746946
mat `T_stats'[3,1] =  .6723754067477308
mat `T_stats'[3,2] =  .2394896046268605
mat `T_stats'[3,3] = -.3176245932522692
mat `T_stats'[3,4] =  1.656502390874715
mat `T_stats'[4,1] =  .4874122281212536
mat `T_stats'[4,2] =  .4965590599853063
mat `T_stats'[4,3] = -.1860571596338484
mat `T_stats'[4,4] =  1.187412228121254
mat `T_stats'[5,1] =  .4836444596677513
mat `T_stats'[5,2] =  .4164020368805063
mat `T_stats'[5,3] = -.4973079212846296
mat `T_stats'[5,4] =  1.468492944516236
mat `T_stats'[6,1] =  .8405548895358794
mat `T_stats'[6,2] =  .2504450623319503
mat `T_stats'[6,3] = -.0344451104641206
mat `T_stats'[6,4] =  1.662777111758102
mat `T_stats'[7,1] =  9.266997773591369
mat `T_stats'[7,2] =  5.152943131556667
mat `T_stats'[7,3] = -2.399668893075297
mat `T_stats'[7,4] =  25.05647145780189
mat `T_stats'[8,1] =  .3519438259976023
mat `T_stats'[8,2] =  .3908864114709845
mat `T_stats'[8,3] = -.4980561740023977
mat `T_stats'[8,4] =  1.242700128518611
tempname C_stats
matrix `C_stats' = r(stats)
assert mreldif( `C_stats' , `T_stats' ) < 1E-8
_assert_streq `"`: rowfullnames `C_stats''"' `"SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree"'
_assert_streq `"`: colfullnames `C_stats''"' `"mean sd min max"'
mat drop `C_stats' `T_stats'
/* This should produce an error message */
rcof "noisily estat ic" == 321

/*******************************************************************
* ESTIMATES postestimation commands
********************************************************************/
estimates stats basic
estimates table basic, b(%9.3f) se p title("Results from RCR") stats(N)

/*******************************************************************
* PREDICT postestimation command
********************************************************************/
/* The predict command is not supported, so this should produce an error message */
rcof "noisily predict" == 321

*******************************************************************
* DETAILS option and RCRPLOT postestimation command
********************************************************************/
/* Call RCRPLOT without having specified DETAILS.  Should generate an error message */
estimates restore basic
rcof "noisily rcrplot" == 321  

/* Call RCR with DETAILS specified */
preserve
set scheme s2mono /* The default scheme (s2color) changes slightly after version 8, so we use a scheme that didn't change */
rcr SAT Small_Class White_Asian Girl Free_Lunch White_Teacher Teacher_Experience Masters_Degree, details
quietly summarize lambda
assert reldif( r(mean)   , 39.17132731582898 ) <  1E-8

/* Save plot (as a postscript file) and check to make sure it hasn't changed */
tempfile rcrplot
quietly graph export `rcrplot', as(ps) replace
checksum `rcrplot'
assert r(checksum) == 3556610235

/* Call RCRPLOT with arguments */
rcrplot, xrange(-20 20) yrange(-40 40)
quietly graph export `rcrplot', as(ps) replace
checksum `rcrplot'
assert r(checksum) == 1962833918

restore

*******************************************************************
* TEST_THETA postestimation command
********************************************************************/
/* Call RCRPLOT without having specified DETAILS.  Should generate an error message */
estimates restore basic
test_betax
assert reldif( r(p)  , 6.75341735534e-08 ) <  1E-8
test_betax =  3.29158
assert reldif( r(p)  , .0500000163998828 ) <  1E-8


log close
