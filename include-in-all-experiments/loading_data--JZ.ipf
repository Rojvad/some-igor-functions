#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

// Edited 2023-01-08
// Edited 2023-02-07
// Edited 2023-02-09 - Added load_aMicData(graphNameSuffix)
// Edited 2023-02-18 - Now vvar = variance rather than vvar = variance^T. I changed the way
//							variance is saved in LabVIEW.  YOU'LL HAVE TO CHANGE THIS BACK WHEN
//							WORKING WITH DATA OLDER THAN 2/18!
// Edited 2023-02-22
// Edited 2023-04-06 - Added load_stdevData

Function load_MBBTF()
	
	NewPath/O folderLocation
	
	String fileNames = "response_x.csv;response_y.csv;response_z.csv;response_x_during_y_move.csv;response_x_during_z_move.csv;" + \
							"response_y_during_x_move.csv;response_y_during_z_move.csv;" + \
							"response_z_during_x_move.csv;response_z_during_y_move.csv"
	String waveNames = "x_vs_x;y_vs_y;z_vs_z;x_vs_y;x_vs_z;y_vs_x;y_vs_z;z_Vs_x;z_vs_y"
	
	Variable i, imax = ItemsInList(fileNames)
	for (i=0; i<imax; i+=1)
	
		// The data for Sx(y) and Sz(y) are mistakenly saved in a different format. >:(
		if (i==3 || i==8)
			LoadWave/Q/M/J/D/K=1/P=folderLocation/N=wave StringFromList(i, fileNames)
			WAVE wave0
			Make/O/N=(DimSize(wave0, 1)) $StringFromList(i, waveNames) = wave0[0][p]
		else
			LoadWave/Q/J/D/K=1/P=folderLocation/N=wave StringFromList(i, fileNames)
			WAVE wave0
			Duplicate/O wave0, $StringFromList(i, waveNames)
		endif
	
		WAVE wOut = $StringFromList(i, waveNames)
		SetScale/P x, -2.5, 0.01, "um", wOut
		SetScale d, -10, 10, "V", wOut
	endfor
	
	KillWaves wave0

End

// Move all the files from one folder into another folder.
Function moveFiles(oldFolderStr, newFolderStr)
	String oldFolderStr, newFolderStr
	
	NewPath/O oldFolderPath, oldFolderStr
	String fileList = IndexedFile(oldFolderPath, -1, "????")
	
	Variable i
	String fileName, oldLoc, newLoc
	for (i=0; i<ItemsInList(fileList); i+=1)
		fileName = StringFromList(i, fileList)
		oldLoc = oldFolderStr + fileName
		newLoc = newFolderStr + fileName
		MoveFile oldLoc as newLoc
	endfor
End

// Use for aMic fluctuation data.
// Moves all the files from the numbered folders into a folder called pixelData.
// Deletes the numbered folders afterwards.
Function consolidate_pixelFiles_move()
	
	NewPath/O pathToFolder
	PathInfo pathToFolder
	String pathToFolderStr = S_path
	String folderList = IndexedDir(pathToFolder, -1, 0)
	// in case pixelData already exists, you don't want to move files from there!
	folderList = removeFromList("pixelData", folderList)
	Print folderlist
	
	String pixelDataStr = pathToFolderStr + "pixelData:"
	NewPath/O/C pixelDataPath, pixelDataStr
	
	Variable i
	String oldFolderStr
	for (i=0; i<ItemsInList(folderList); i+=1)
		oldFolderStr = pathToFolderStr + StringFromList(i, folderList) + ":"
		MoveFiles(oldFolderStr, pixelDataStr)
		// DeleteFolder oldFolderStr
	endfor
end

// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
// Added the stuff below on 2023/02/07. I didn't check it to perfection, I just
// knew I'd need it for taking data on 02/08.
// ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

// filList_px comes from the LabVIEW-generated file,
// "FilamentScatterWaveAxisONLYordered_in_px"
Function load_SensiData(gridSize, filList_px)
	Variable gridSize
	WAVE filList_px
	
	NewPath/O pixelDataPath
	String allFileList = IndexedFile(pixelDataPath, -1, "????")
	
	// Collect all the files which stored slopes for the perpindicular scans
	// We only want the files that start with "Slopes___"
	String/G slopeFileList = ""  // #extra: I can probably remove the /G, right?
	String fileName
	Variable i, imax = ItemsInList(allFileList), keep
	for (i=0; i<iMax; i+=1)
		fileName = StringFromList(i, allFileList)
		keep = StringMatch(fileName, "Slopes*")
		if (keep)
			slopeFileList = AddListItem(fileName, slopeFileList)
		endif
	endfor
	
	// loop over all the slope files and extract the values from them.
	// in this loop, we'll re-use the variables fileName and iMax
	// But first, we have to put the files in the right order
	slopeFileList = SortList(slopeFileList, ";", 16)
	iMax = ItemsInList(slopeFileList)
	Make/O/N=(iMax) filList_sensiX, filList_sensiY, filList_sensiUsed
	Make/O/N=(gridSize, gridSize) sensiXImg = NaN, sensiYImg = NaN, sensiUsedImg = Nan
	Variable sensiX, sensiY

	for (i=0; i<iMax; i+=1)
		fileName = StringFromList(i, slopeFileList)
//		printf "fileName = %s\r", fileName
		
		LoadWave/Q/J/N=sensi/P=pixelDataPath fileName
		WAVE sensi0, sensi1
		sensiX = abs(sensi0[0])
		sensiY = abs(sensi1[0])
		
		filList_sensiX[i] = sensiX
		filList_sensiY[i] = sensiY
		filList_sensiUsed[i] = max(sensiX, sensiY)
		sensiXImg[filList_px[i][0]][filList_px[i][1]] = sensiX
		sensiYImg[filList_px[i][0]][filList_px[i][1]] = sensiY
		sensiUsedImg[filList_px[i][0]][filList_px[i][1]] = max(sensiX, sensiY)
		
	endfor
	
	KillWaves sensi0, sensi1
End

// Copied this function from 10/19
// Make 1D waves for all the fluctuation values and all the sensitivity values.
Function pull_values(img1, img2, list1Name, list2Name)
	WAVE img1, img2
	String list1Name, list2Name
	
	Make/O/N=0 $list1Name, $list2Name
	WAVE list1 = $list1Name
	WAVE list2 = $list2Name 
	
	Variable i, j, num = 0
	Variable imax = DimSize(img1, 0)
	Variable jmax = DimSize(img1, 1)
	for (j=0; j<jmax; j+=1)
		for (i=0; i<imax; i+=1)
			if ( numtype(img1[i][j])==0 && numType(img2[i][j])==0 )
				InsertPoints/V=(img1[i][j]) numpnts(list1), 1, list1
				InsertPoints/V=(img2[i][j]) numpnts(list2), 1, list2
				num += 1
			endif
		endfor
	endfor
	Printf "List should have %g elements\r", num
End

// This function requires that you've already done consolidate_pixelFiles_move()
// #extra: Find pixelData folder rather than make user select it
Function load_aMicData(graphNameSuffix)
	String graphNameSuffix
	
	// pseudo code:
	// Load in the stez
	// Load in variance
	// transpose variance and name it vvar (NOT ANYMORE! I changed the LabVIEW code that makes variance)
	// scale vvar to match stez
	// display vvar on top of stez
	// load in the sensitivity data
	// take sqrt(vvar) / sensiUsed. Name it flucs_m_noNS
	// display flucs_m_noNoiseSub on top of stez
	NewPath/O myPath
	
	// make a graph of the voltage variance for every filament pixel
	LoadWave/O/P=myPath  "Sx.ibw"
	LoadWave/O/P=myPath  "Sy.ibw"
	LoadWave/O/P=myPath  "Sz.ibw"
	LoadWave/O/P=myPath  "SensitivityTotalEZ.ibw"
	WAVE stez
	LoadWave/Q/J/M/D/N=wave/K=1/P=myPath "variance"
	WAVE wave0
	Rename wave0, vvar
	WAVE vvar
	LoadWave/Q/J/M/D/N=wave/K=1/P=myPath "SxOrSy"
	WAVE wave0
	Rename wave0, SxOrSyImg
	WAVE SxOrSyImg
	SetScale/P x, DimOffset(stez, 0), DimDelta(stez, 0), WaveUnits(stez, 0), vvar, SxOrSyImg
	SetScale/P y, DimOffset(stez, 1), DimDelta(stez, 1), WaveUnits(stez, 1), vvar, SxOrSyImg
	String graphName = "vvar" + graphNameSuffix
	Display/N=$graphName/W=(10,10,360,360)
	AppendImage stez
	AppendImage vvar
	ModifyGraph width={Plan,1,bottom,left}
	ModifyImage vvar ctab= {*,*,Rainbow,1}
	ModifyGraph axisEnab(bottom)={0,0.8}
	ColorScale/C/N=text0/F=0/A=RC/X=-1.50/Y=-0.2 image=vvar, lblMargin=10, "\\Z16σ\\S2\\M\\Z16 [V\\S2\\M\\Z16]"
	ModifyGraph axisEnab(left)={0,0.95}
	TextBox/C/N=title/F=1/A=LT/X=-0.21/Y=-3.51 "\\Z16No noise subtraction"
	
	// make a graph of the standard deviation, in m, for every filament pixel
	// Don't subtract any noise from the voltage variance.
	LoadWave/Q/J/M/D/N=wave/K=1/P=myPath "FilamentScatterWaveAxisONLYordered_in_px"
	Wave wave0
	Rename wave0, filList_px
	WAVE filList_px
	Variable gridSize = DimSize(stez, 0)
	load_sensiData(gridSize, filList_px)
	WAVE sensiUsedImg
	Duplicate vvar, flucs_m_noNS
	flucs_m_noNS[][] = sqrt(vvar[p][q]) / sensiUsedImg[p][q]
	graphName = "flucs_noNS" + graphNameSuffix
	Display/N=$graphName/W=(10,10,360,360)
	AppendImage stez
	AppendImage flucs_m_noNS
	ModifyGraph width={Plan,1,bottom,left}
	ModifyImage flucs_m_noNS ctab= {*,*,Rainbow,1}
	ModifyGraph axisEnab(bottom)={0,0.8}
	ColorScale/C/N=text0/F=0/A=RC/X=-1.50/Y=-0.2 image=flucs_m_noNS, lblMargin=10, "\\Z16σ [m]"
	ModifyGraph axisEnab(left)={0,0.95}
	TextBox/C/N=title/F=1/A=LT/X=-0.21/Y=-3.51 "\\Z16No noise subtraction"
	
End

// load the standard deviation vs z data from an sVsZ folder
Function load_stdevData(prefix, numLocs, z, dz)
	String prefix
	Variable numLocs, z, dz
	
	NewPath/O myPath
	
	Variable i, imax=numLocs
	String fileName_Sx, wOutName_Sx
	String fileName_Sy, wOutName_Sy
	for (i=0; i<imax; i+=1)
		sprintf fileName_Sx, "stdevSxVsZ_%d", i
		sprintf fileName_Sy, "stdevSyVsZ_%d", i
		
		LoadWave/Q/J/M/D/N=wave/K=1/P=myPath fileName_Sx
		WAVE wave0
		wOutName_Sx = prefix + fileName_Sx
		Make/O/N=(numpnts(wave0)) $wOutName_Sx = wave0[0][p]
		Wave wOut_Sx = $wOutName_Sx
		
		LoadWave/Q/J/M/D/N=wave/K=1/P=myPath fileName_Sy
		WAVE wave0
		wOutName_Sy = prefix + fileName_Sy
		Make/O/N=(numpnts(wave0)) $wOutName_Sy = wave0[0][p]
		Wave wOut_Sy = $wOutName_Sy
		
		
		SetScale/P x, z, dz, "um", wOut_Sx, wOut_Sy
		SetScale d, 0, 0, "V", wOut_Sx, wOut_Sy
		
	endfor
End

// For a scan that consists of multiple subsquares, these 2 functions load the stez wave
// from each subsquare and display them on a single graph.
// #extra: Limit the dirList to directories that have a name like ss_(some integer)
Function load_stez_ss()

	NewPath/O myPath
	String dirList = IndexedDir(myPath, -1, 0)
	
	Variable i, imax = ItemsInList(dirList)
	for (i=0; i<imax; i+=1)
		LoadWave/Q/P=myPath ":" + StringFromList(i, dirList) + ":stez.ibw"
	endfor
End

Function display_stez_ss(graphName, isRainbow)
	String graphName
	Variable isRainbow
	
	String ss_waveList = WaveList("stez_ss*", ";", "")
	
	Display/N=$graphName
	Variable i, imax = ItemsInList(ss_waveList)
	for (i=0; i<imax; i+=1)
		WAVE stez_oneSS = $StringFromList(i, ss_waveList)
		AppendImage stez_oneSS
	endfor
	
	plan()
	if (isRainbow)
		set_ssColorTables(1, inf, "Rainbow", 1)
	endif
End

// #todo: Make a wave of wave references that points to the Sx response curves (and Sy)
Function load_perpScans()

	NewPath/O pixelDataPath
	String allFileList = IndexedFile(pixelDataPath, -1, "????")
	
	String/G sxFileList = ""
	String/G syFileList = ""
	String fileName, wOutName
	Variable i, imax = ItemsInList(allFileList), isSx, isSy
	for (i=0; i<imax; i+=1)
		fileName = StringFromList(i, allFileList)
		isSx = StringMatch(fileName, "SensiScanX*")
		isSy = StringMatch(fileName, "SensiScanY*")
		if (isSx)
			sxFileList = AddListItem(fileName, sxFileList)
		elseif(isSy)
			syFileList = AddListItem(fileName, syFileList)
		endif
	endfor
	
	// Put the file lists in order. This isn't actually necessary
	sxFileList = SortList(sxFileList, ";", 16)
	syFileList = SortList(syFileList, ";", 16)
	
	// Make some waves to store references to all the response curves
	Make/WAVE/O/N=(itemsInList(sxFileList)) allPerpScans_Sx
	Make/WAVE/O/N=(itemsInList(syFileList)) allPerpScans_Sy
	
	// Load the Sx data for the perpendicular scans
	imax = ItemsInList(sxFileList)
	for (i=0; i<imax; i+=1)
		fileName = StringFromList(i, sxFileList)
		LoadWave/Q/J/M/D/N=sx/K=0/P=pixelDataPath fileName
		Wave sx0
		wOutName = "sx_perpScan" + num2str(i)
		Make/O/N=(DimSize(sx0,1)) $wOutName = sx0[p]
		Wave wOut = $wOutName
		allPerpScans_Sx[i] = wOut
	endfor
	
	// Load the Sy data for the perpendicular scans
	imax = ItemsInList(syFileList)
	for (i=0; i<imax; i+=1)
		fileName = StringFromList(i, syFileList)
		LoadWave/Q/J/M/D/N=sy/K=0/P=pixelDataPath fileName
		Wave sy0
		wOutName = "sy_perpScan" + num2str(i)
		Make/O/N=(DimSize(sx0,1)) $wOutName = sy0[p]
		Wave wOut = $wOutName
		allPerpScans_Sy[i] = wOut
	endfor
	
	KillWaves sx0, sy0
End

// #todo: this should be writeen in terms of perp scan length and dx
//Function scale_perpScans_edit(locNums, xi, dx)
//	Wave locNums
//	Variable xi, dx
//	
//	Variable i, imax = numpnts(locNums)
//	String ogName
//	for (i=0; i<imax; i+=1)
//		ogName = "sx_perpScan" + num2str(locNums[i])
//		Wave wIn = $ogName
//		SetScale/P x, xi, dx, "um", wIn
//		
//		ogName = "sy_perpScan" + num2str(locNums[i])
//		Wave wIn = $ogName
//		SetScale/P x, xi, dx, "um", wIn
//	endfor
//
//End

// #todo: make copies for Sy responses, too
// #todo: this should be writeen in terms of perp scan length and dx
Function scale_perpScans_copy(locNums, xi, dx)
	Wave locNums
	Variable xi, dx
	
	Variable i, imax = numpnts(locNums)
	String ogName, wOutName
	for (i=0; i<imax; i+=1)
		ogName = "sx_perpScan" + num2str(locNums[i])
		Wave wIn = $ogName
		wOutName = ogName + "_scaledWell"
		Duplicate/O wIn, $wOutName
		Wave wOut = $wOutName
		
		SetScale/P x, xi, dx, "um", wOut

	endfor

End
