#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// This is just a shortcut for setting a graph to "Plan" scaling
Function plan()
	ModifyGraph width={Plan,1,bottom,left}
End

// If you have a window with images from lots of subsquares, it can be
// useful to change all their color tables at once.
Function set_ssColorTables(isSameMax, maxVal, colorTable, isReverse)
	Variable isSameMax, maxVal, isReverse
	String colorTable
	
	String imgList = ImageNameList("", ";")
	Variable i, imax = ItemsInList(imgList)
	String imgName
	
	// find the maximum value in all of the waves, if necessary
	if (isSameMax)
		Variable globalMax
		if (numtype(maxVal) == 0) // if maxVal is a normal number (not inf or NaN)
			globalMax = maxVal
		else
			globalMax = 0
			Variable thisMax = 0
			for (i=0; i<imax; i+=1)
				imgName = StringFromList(i, imgList)
				thisMax = WaveMax(ImageNameToWaveRef("", imgName))
				globalMax = max(globalMax, thisMax)
			endfor
		endif
	endif
	
	// set all of the color tables
	for (i=0; i<imax; i+=1)
		imgName = StringFromList(i, imgList)
		if (isSameMax)
			ModifyImage $imgName ctab = {0, globalMax, $colorTable, isReverse}
		else
			ModifyImage $imgName ctab = {0, *, $colorTable, isReverse}
		endif
	endfor
End

Function hide_traces()
	
	NVAR num, start
	
	String traces = TraceNameList("", ";", 1)
	
	Variable i, imax=ItemsInList(traces)
	for (i=0; i<imax; i+=1)
		if (i<start || i>=start+num)
			ModifyGraph hidetrace($StringFromList(i, traces))=1
		else
			ModifyGraph hidetrace($StringFromList(i, traces))=0
		endif
	endfor
	
	//ModifyGraph hideTrace(stdevVsZ_8)=1
End
	
Function update_for_stdevVsZ(ba) : ButtonControl
	STRUCT WMButtonAction &ba

	switch( ba.eventCode )
		case 2: // mouse up
			hide_traces()
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

// Use the Pythagorean theorem to find the distance between two points in a plane
Function/D distance(x1, x2, y1, y2)
	Variable x1, x2, y1, y2
	
	Return sqrt( (x2-x1)^2 + (y2-y1)^2 )
End