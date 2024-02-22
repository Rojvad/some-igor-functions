#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function mySine(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = A + A*cos(2*pi*x/180)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 1
	//CurveFitDialog/ w[0] = A

	return w[0] + w[0]*cos(2*pi*x/180)
End

Function myLine(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = b*abs(x-90)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 1
	//CurveFitDialog/ w[0] = b

	return w[0]*abs(x-90)
End

Function mySine_2(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = A + A*sin(2*pi*x/180 - pi/2)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 1
	//CurveFitDialog/ w[0] = A

	return w[0] + w[0]*sin(2*pi*x/180 - pi/2)
End

Function myLine_2(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = b*90 - b*abs(90-x)
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 1
	//CurveFitDialog/ w[0] = b

	return w[0]*90 - w[0]*abs(90-x)
End

Function simFitX(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = a * x
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 1
	//CurveFitDialog/ w[0] = a

	Wave sensiX_sim0202
	return w[0] * sensiX_sim0202(x)
End

Function simFitY(w,x) : FitFunc
	Wave w
	Variable x

	//CurveFitDialog/ These comments were created by the Curve Fitting dialog. Altering them will
	//CurveFitDialog/ make the function less convenient to work with in the Curve Fitting dialog.
	//CurveFitDialog/ Equation:
	//CurveFitDialog/ f(x) = a * x
	//CurveFitDialog/ End of Equation
	//CurveFitDialog/ Independent Variables 1
	//CurveFitDialog/ x
	//CurveFitDialog/ Coefficients 1
	//CurveFitDialog/ w[0] = a

	Wave sensiY_sim0220
	return w[0] * sensiY_sim0220(x)
End

Function rename_fitStuff(yDataName, newName)
	String yDataName, newName
	
	String oldFitName = "fit_" + yDataName
	String newFitName = "fit_" + newName
	Wave fitWave = $oldFitName
	Rename fitWave, $newFitName
	
	String newCoefsName = "fitP_" + newName
	Wave W_coef
	Rename W_coef, $newCoefsName
	
	String oldResName = "Res_" + yDataName
	String newResName = "Res_" + newName
	Wave resWave = $oldResName
	Rename resWave, $newResName
	
	String newChiSqName = "chiSq_" + newName
	NVAR V_chisq
	Rename V_chisq, $newChiSqName
End