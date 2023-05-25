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
			String list_dName = listNAme + "d"
	
			Make/O/N=0 $list_xName
			Make/O/N=0 $list_yName
			Make/O/N=0 $list_valName
			Make/O/N=0 $list_dName
	
			Wave list_X = $list_xName
			Wave list_y = $list_yName
			Wave list_val = $list_valName
			Wave list_d = $list_dName
	
			InsertPoints/V=(hcsr(A)) 1, 1, list_x
			InsertPoints/V=(vcsr(A)) 1, 1, list_y
			InsertPoints/V=(zcsr(A)) 1, 1, list_val
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
			String list_dName = listNAme + "d"
			
			//#extra: throw an error if wave isn't found
			Wave list_X = $list_xName
			Wave list_y = $list_yName
			Wave list_val = $list_valName
			Wave list_d = $list_dName
	
			InsertPoints/V=(hcsr(A)) numpnts(list_x), 1, list_x
			InsertPoints/V=(vcsr(A)) numpnts(list_y), 1, list_y
			InsertPoints/V=(zcsr(A)) numpnts(list_val), 1, list_val
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

