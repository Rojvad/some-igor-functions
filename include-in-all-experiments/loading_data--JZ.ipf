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
Function consolidate_pixelFiles_move([pathString])
	String pathString

	if (!ParamIsDefault(pathString))
		NewPath/O pathToFolder, pathString
	else
		NewPath/O pathToFolder
	endif
	
	PathInfo pathToFolder
	String pathToFolderStr = S_path
	String folderList = IndexedDir(pathToFolder, -1, 0)
	// in case pixelData already exists, you don't want to move files from there!
	folderList = removeFromList("pixelData", folderList)
	folderList = removeFromList("sVsZ", folderList) // or from the sVsZ folder
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

// Let's say you've done an aMic scan with multiple subsquares. This lets you
// consolidate the pixel files for every Subsquare
//
// #todo: Make sure the folder names in ss_folderList all start with "ss"
Function consolidate_pixelFiles_move_ssVersion([pathString])
	String pathString

	if (!ParamIsDefault(pathString))
		NewPath/O basePath, pathString
	else
		NewPath/O basePath
	endif
	
	String ss_folderList = IndexedDir(basePath, -1, 1)
	
	Variable i, imax = ItemsInList(ss_folderList)
	for (i=0; i<imax; i+=1)
		consolidate_pixelFiles_move(pathString=StringFromList(i, ss_folderList))
	endfor

End

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
	String slopeFileList = ""
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

// load_aMicWaves_ss:
// 		This is sort of an updated version of load_aMicData(). For a scan with multiple subsquares,
// 		it loads a collection of useful waves for each subsquare. It also makes waves of references
//		to keep everything well-organized.
// paramters:
//		pathString : A complete path to the folder which holds all the subsquare folders
// #bonus: check that all the subfolders have names like ss_
Function load_aMicWaves_ss([pathString])
	String pathString
	
	if (!ParamIsDefault(pathString))
		NewPath/O basePath, pathString
	else
		NewPath/O basePath
	endif

	String dirList = IndexedDir(myPath, -1, 0)
	
	// put the directories in the correct order
	dirList = SortList(dirList, ";", 16)
	
	Variable i, imax = ItemsInList(dirList)
	// Make waves that will hold references to all the subsquare waves
	Make/O/N=(imax)/WAVE stezRef_allSS, SxRef_allSS, SyRef_allSS
	Make/O/N=(imax)/WAVE vvarSxRef_allSS, vvarSyRef_allSS, angleImgRef_allSS
	Make/O/N=(imax)/WAVE filLocsRef_allSS
	Variable xOffset, yOffset, dx, dy
	String wName
	for (i=0; i<imax; i+=1)
		// stez. The stez waves have the ss number saved in the Igor Binary
		LoadWave/Q/P=myPath ":" + StringFromList(i, dirList) + ":stez.ibw"
		wName = "stez_ss" + num2str(i)
		Wave oneWave = $wName
		stezRef_allSS[i] = oneWave
		xOffset = DimOffset(oneWave, 0)
		yOffset = DimOffset(oneWave, 1)
		dx = DimDelta(oneWave, 0)
		dy = DimDelta(oneWave, 1)
		
		// Sx and Sy (assumes they're saved as Igor binaries)
		LoadWave/Q/P=myPath ":" + StringFromList(i, dirList) + ":Sx.ibw"
		Wave Sx
		wName = "Sx_ss" + num2str(i)
		Rename Sx, $wName
		Wave oneWave = $wName
		SxRef_allSS[i] = oneWave
		
		LoadWave/Q/P=myPath ":" + StringFromList(i, dirList) + ":Sy.ibw"
		Wave Sy
		wName = "Sy_ss" + num2str(i)
		Rename Sy, $wName
		Wave oneWave = $wName
		SyRef_allSS[i] = oneWave
		
		// vvarSx and vvarSy. These are delimited text files.
		LoadWave/Q/J/M/D/P=myPath/A=vvarSx_ss/K=1 ":" + StringFromList(i, dirList) + ":variance_Sx"
		wName = "vvarSx_ss" + num2str(i)
		Wave oneWave = $wName
		SetScale/P x, xOffset, dx, "um", oneWave
		SetScale/P y, yOffset, dy, "um", oneWave
		vvarSxRef_allSS[i] = oneWave
		
		LoadWave/Q/J/M/D/P=myPath/A=vvarSy_ss/K=1 ":" + StringFromList(i, dirList) + ":variance_Sy"
		wName = "vvarSy_ss" + num2str(i)
		Wave oneWave = $wName
		SetScale/P x, xOffset, dx, "um", oneWave
		SetScale/P y, yOffset, dy, "um", oneWave
		vvarSyRef_allSS[i] = oneWave
		
		// angleWave. This is a delimited text file
		LoadWave/Q/J/M/D/P=myPath/A=angleImg_ss/K=1 ":" + StringFromList(i, dirList) + ":AngleWaveImage"
		wName = "angleImg_ss" + num2str(i)
		Wave oneWave = $wName
		SetScale/P x, xOffset, dx, "um", oneWave
		SetScale/P y, yOffset, dy, "um", oneWave
		angleImgRef_allSS[i] = oneWave
		
		// Filament locations. This is a delimited text file.
		LoadWave/Q/J/M/D/P=myPath/A=filLocs_um_ss/K=1 ":" + StringFromList(i, dirList) + ":FilamentScatterWaveAxisONLYordered_in_m"
		wName = "filLocs_m_ss" + num2str(i)
		Wave oneWave = $wName
		oneWave *= 1e6
		oneWave[][0] += xOffset
		oneWave[][1] += yOffset
		filLocsRef_allSS[i] = oneWave
		
	endfor
End

// load the standard deviation vs z data from an sVsZ folder
// This is for the version that saves only Sx or Sy data, not both
Function load_stdevData_Si(prefix, numLocs, z, dz)
	String prefix
	Variable numLocs, z, dz
	
	NewPath/O myPath
	
	Variable i, imax=numLocs
	String fileName, wOutName
	for (i=0; i<imax; i+=1)
		sprintf fileName, "stdevVsZ_%d", i
		
		LoadWave/Q/J/M/D/N=wave/K=1/P=myPath fileName
		WAVE wave0
		wOutName = prefix + fileName
		Make/O/N=(numpnts(wave0)) $wOutName = wave0[0][p]
		Wave wOut = $wOutName
			
		SetScale/P x, z, dz, "um", wOut
		SetScale d, 0, 0, "V", wOut
	endfor
End

// load the standard deviation vs z data from an sVsZ folder
// This is for the version that saves both Sx and Sy data
Function load_stdevData_SxSy(prefix, numLocs, z, dz)
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

// Similar to v1, but it creates stezRef_allSS, which holds references to all the
// stez waves for different subsquares.
// Also, it chooses the names for the stez waves rather than taking the name saved
// in the Igor binary file.
// WARNING! I don't think it IS choosing the names. I think it's still using the
// name waved in the Igor binary
Function load_stez_ss_v2()

	NewPath/O myPath
	String dirList = IndexedDir(myPath, -1, 0)
	
	// put the directories in the correct order
	dirList = SortList(dirList, ";", 16)
	
	Variable i, imax = ItemsInList(dirList)
	// Make a wave that will hold references to all the stez waves
	Make/O/N=(imax)/WAVE stezRef_allSS
	String wName
	for (i=0; i<imax; i+=1)
		LoadWave/Q/P=myPath/A=stez_ss ":" + StringFromList(i, dirList) + ":stez.ibw"
		wName = "stez_ss" + num2str(i)
		Wave oneStez = $wName
		stezRef_allSS[i] = oneStez
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

// #bonus: put the perp scans in a child data folder rather than having
//				hundreds of waves clutter things up
Function load_perpScans([pathString, df])
	String pathString
	DFREF df
	
	DFREF saveDFR = GetDataFolderDFR()
	
	if (!ParamIsDefault(pathString))
		NewPath/O pixelDataPath, pathString
	else
		NewPath/O pixelDataPath
	endif
	
	if (!ParamIsDefault(df))
		SetDataFolder df
	endif
		
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
		Make/O/D/N=(DimSize(sx0,1)) $wOutName = sx0[0][p]
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
		Make/O/D/N=(DimSize(sx0,1)) $wOutName = sy0[0][p]
		Wave wOut = $wOutName
		allPerpScans_Sy[i] = wOut
	endfor
	
	KillWaves sx0, sy0
	SetDataFolder saveDFR
End

// load_perpScans_ssVersion:
// 		For each subsquare, make a data folder. That data folder will hold waves with
// 		the Sx and Sy data for all the perpendicular scans. Thus, there will be two
// 		waves for each filament location. There will also be two waves in the data folder
// 		which hold references to all the waves in the df.
// parameters:
// 		pathString : A complete path to the folder which holds all the subsquare folders.

// #bonus: Maybe have a wave of referenes to the allPerpScans waves
// in each df too?
Function load_perpScans_ssVersion([pathString])
	String pathString
	
	DFREF saveDFR = GetDataFolderDFR()	
	
	if (!ParamIsDefault(pathString))
		NewPath/O basePath, pathString
	else
		NewPath/O basePath
	endif
	
	String ss_folderList = IndexedDir(basePath, -1, 1)
	// put the directories in the correct order
	ss_folderList = SortList(ss_folderList, ";", 16)
	
	Variable i, imax = ItemsInList(ss_folderList)
	// This wave will store references to all the data folders (one for each subsquare)
	Make/O/DF/N=(imax) perpScanDfRef_allSS
	String ssPathString, dfName
	Variable n
	for (i=0; i<imax; i+=1)
 
		ssPathString = StringFromList(i, ss_folderList)
		n = ItemsInList(ssPathString, ":")
		dfName = StringFromList(n-1, ssPathString, ":")
		NewDataFolder $dfName
		perpScanDfRef_allSS[i] = saveDFR:$dfName
		
		load_perpScans(pathString=ssPathString+":pixelData:", df=perpScanDFRef_allSS[i])

	endfor
End

// #todo: this should be written in terms of perp scan length and dx
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

// This is a naive way to find the sensitivity from a response curve.
// It simply takes the derivative of the response curve and looks up
// the derivative value at the point i_center.
// #todo: Based on LabVIEW code, find a formula for i_center
Function/D findDerivAtCenter_simple(wIn, i_center)
	Wave wIn
	Variable i_center
	
	Differentiate wIn /D=wIn_deriv
	Variable result = abs(wIn_deriv[i_center])
	KillWaves wIn_deriv
	
	Return result
End

// This uses "findDerivAtCenter_simple" to find an Sx and Sy
// sensitivity for every filament location.
// It saves the results in 2D waves, sensis_Sx and sensis_Sy.
// To find where to put each sensitivity, it looks up the x
// and y pixel values from filLocs_px
Function findSensis_simple(perpScans_Sx, perpScans_Sy, filLocs_px, gridSize, i_center)
	Wave/WAVE perpScans_Sx, perpScans_Sy
	Wave filLocs_px
	Variable gridSize, i_center
	
	Make/O/N=(gridSize, gridSize) sensis_Sx = NaN, sensis_Sy = NaN
	Variable sensi_Sx, sensi_Sy
	Variable x_px, y_px
	Variable i, imax = DimSize(filLocs_px, 0)
	for (i=0; i<imax; i+=1)
		x_px = filLocs_px[i][0]
		y_px = filLocs_px[i][1]
		
		sensi_Sx = findDerivAtCenter_simple(perpScans_Sx[i], i_center)
		sensis_Sx[x_px][y_px] = sensi_Sx
		
		sensi_Sy = findDerivAtCenter_simple(perpScans_Sy[i], i_center)
		sensis_Sy[x_px][y_px] = sensi_Sy
	endfor

End
