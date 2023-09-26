#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// This is just a shortcut for setting a graph to "Plan" scaling
Function plan()
	ModifyGraph width={Plan,1,bottom,left}
End

Function rainbow(isReverse)
	Variable isReverse
	
	String imgList = ImageNameList("", ";")
	Variable i, imax = ItemsInList(imgList)
	String imgName
	
	for (i=0; i<imax; i+=1)
		imgName = StringFromList(i, imgList)
		ModifyImage $imgName ctab= {*, *, Rainbow, isReverse}
	endfor
end
	

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

// ------------------------------------------------------------------
// The following functions create an easy way to move a cursor to different points on an image,
// and add those points to lists.

// #todo: Save all the lists in the same data folder as the image data
// #todo: Return the current data folder to where it was when you started
// #extra: add some more ways to calculate distance. Like length ALONG the filament rather than
// distance directly to 0th point. Or projected distance onto the axis between 0th and last point.
// #extra: set the "data full scale" of the lists based on the image data

// WaveRefIndexed and GetWavesDataFolder, as mentioned in WaveList documentation, could be useful
// ------------------------------------------------------------------

Function savePoints()
	//#todo: save data folder ref, move to data folder with the data, then move back at end
	ShowInfo
	ControlBar 50
	Button addPt title="Add pt",size={60,40},proc=add_PointFromCursor
	Button firstPt title="1st pt",size={60,40},proc=start_listFromCursor
	//#todo: would be better to put string in same folder as data
	String/G listName = "list_"
	//SetVariable listNameCtrl title="Prefix for list",size={160,18},pos={140,10},fsize=16,value=listName
	SetVariable listNameCtrl title="Prefix for list",size={160,18},fsize=16,value=listName
	//#todo: Make a button that kills the control bar and buttons when you click it
	Button doneBtn title="Done",size={60,40},proc=removeControls
End

Function start_listFromCursor(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SVAR listName
			String list_xName = listName + "x"
			String list_yName = listName + "y"
			String list_valName = listName + "val"
			String list_pName = listName + "p"
			String list_dName = listNAme + "d"
	
			Make/O/N=0 $list_xName
			Make/O/N=0 $list_yName
			Make/O/D/N=0 $list_valName
			Make/O/I/N=0 $list_pName
			Make/O/N=0 $list_dName
	
			Wave list_X = $list_xName
			Wave list_y = $list_yName
			Wave list_val = $list_valName
			Wave list_p = $list_pName
			Wave list_d = $list_dName
	
			InsertPoints/V=(hcsr(A)) 1, 1, list_x
			InsertPoints/V=(vcsr(A)) 1, 1, list_y
			InsertPoints/V=(zcsr(A)) 1, 1, list_val
			InsertPoints/V=(pcsr(A)) 1, 1, list_p
			InsertPoints/V=0 1, 1, list_d
			
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function add_PointFromCursor(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			SVAR listName
			String list_xName = listName + "x"
			String list_yName = listName + "y"
			String list_valName = listName + "val"
			String list_pName = listName + "p"
			String list_dName = listNAme + "d"
			
			//#extra: throw an error if wave isn't found
			Wave list_X = $list_xName
			Wave list_y = $list_yName
			Wave list_val = $list_valName
			Wave list_p = $list_pName
			Wave list_d = $list_dName
	
			InsertPoints/V=(hcsr(A)) numpnts(list_x), 1, list_x
			InsertPoints/V=(vcsr(A)) numpnts(list_y), 1, list_y
			InsertPoints/V=(zcsr(A)) numpnts(list_val), 1, list_val
			InsertPoints/V=(pcsr(A)) numpnts(list_p), 1, list_p
			Variable distance = dist(hcsr(A), list_x[0], vcsr(A), list_y[0])
			InsertPOints/V=(distance) numpnts(list_d), 1, list_d
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End

Function removeControls(ba) : ButtonControl
	STRUCT WMButtonAction &ba
	
	switch( ba.eventCode )
		case 2: // mouse up
			// click code here
			KillControl addPt
			KillControl firstPt
			KillControl listNameCtrl
			KillControl doneBtn
			ControlBar 0
			break
		case -1: // control being killed
			break
	endswitch

	return 0
End
// ------------------------------------------------------------------
// End of functions used for saving points using cursor
// ------------------------------------------------------------------


// Use the Pythagorean theorem to find the distance between two points in a plane
Function/D dist(x1, x2, y1, y2)
	Variable x1, x2, y1, y2
	
	Return sqrt( (x2-x1)^2 + (y2-y1)^2 )
End

// If you have a wave of wave references, this function rescales all the referenced waves
Function scale_waves_edit(waves, xi, dx, unit, [dim])
	Wave/WAVE waves
	Variable xi, dx, dim
	String unit
	
	Variable i, imax = numpnts(waves)
	for (i=0; i<imax; i+=1)
		if (dim == 0)
			SetScale/P x, xi, dx, unit, waves[i]
		elseif (dim == 1)
			SetScale/P y, xi, dx, unit, waves[i]
		elseif (dim == 2)
			SetScale/P z, xi, dx, unit, waves[i]
		endif
	endfor
End

// For a given type of wave, plot all the subsquare's data in one combined graph.
// waveWave holds references to all the subsquares' waves
// plotName should be left as "" if you want to append the waves to the top graph
// mode is either "image" for a 2D wave that represents an image,
// or "xy" for a wave that is a list of (x, y) points.
Function plot_waves_allSS(waveWave, plotName, mode)
	Wave/WAVE waveWave
	String plotName, mode

	if (!stringmatch(plotName, ""))
		Display/N=$plotName
	endif
	
	Variable i, imax = numpnts(waveWave)
	for (i=0; i<imax; i+=1)
	
		if (stringmatch(mode, "img"))
			Wave image = waveWave[i]
			AppendImage image
		elseif (stringmatch(mode, "XY"))
			Wave xyList = waveWave[i]
			AppendToGraph xyList[][1] vs xyList[][0]
		endif
	endfor
	
	plan()
	if (stringmatch(mode, "XY"))
		ModifyGraph mode=3,marker=19,msize=1
	endif
		
End

Function check_refWave(refWave, i)
	Wave/WAVE refWave
	Variable i
	
	Wave oneWave = refWave[i]
	Display/N=checking_refWave oneWave
	
End

// contourLength:
// 	Use to calculate the contour length along a filament. The starting
// 	point is (xi, yi)
//		BEWARE! make sure that (xi, yi) is on the same side of the filament
//		as (xWave[0], yWave[0]).
// parameters:
// 	xWave, yWave : positions of the filament points
//		(xi, yi) : point that your measure contour length from
//		wOutName : name of the wave to store the results. Will have the
// 		same length as xWave and yWave.
Function contourLength(xWave, yWave, xi, yi, wOutName)
	Wave xWave, yWave
	Variable xi, yi
	String wOutName
	
	Make/O/N=(numpnts(xWave)) $wOutName
	Wave wOut = $wOutName
	
	Variable ds = dist(xi, xWave[0], yi, yWave[0])
	wOut[0] = ds
	
	Variable i, imax = numpnts(xWave)
	for (i=1; i<imax; i+=1)
		ds = dist(xWave[i], xWave[i-1], yWave[i], yWave[i-1])
		wOut[i] = wOut[i-1] + ds
	endfor
	
End

Function msd_oneK(wIn, k)
	Wave wIn
	Variable k
	
	Variable len = numpnts(wIn) - k
	Make/O/D/N=(len) diffSq = (wIn[p+k] - wIn[p])^2
	
	Return sum(diffSq) / len
	
End

Function msd(wIn, kmax, isScaled)
	Wave wIn
	Variable kMax, isScaled
	
	String wOutName = "msd_" + NameOfWave(wIn)
//	Make/O/D/N=(numpnts(wIn)) $wOutName = msd_oneK(wIn, p)
	Make/O/D/N=(kMax) $wOutName = msd_oneK(wIn, p)

	
	if (isScaled)
		Wave wOut = $wOutName
		SetScale/P x, 0, DimDelta(wIn, 0), WaveUnits(wIn, 0), wOut
	endif
End
