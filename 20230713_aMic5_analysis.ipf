#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Strconstant dfName = "aMic_5"
Strconstant pathToData = "C:Users:JDZes:Box:ActivityMicroscopy:data:2023-07-13--2,2mg_mL_collagen:aMic_5:aMic_and_sVsZ_selection:layer0"
Strconstant pathToSTEZ = "C:Users:JDZes:Box:ActivityMicroscopy:data:2023-07-13--2,2mg_mL_collagen:aMic_5:aMic_and_sVsZ_selection:SensitivityTotalEZ_all.ibw"
Constant perpScan_rhoi = -1
Constant perpSCan_drho = 0.025
Constant perpScan_iCenter = 40
Constant vvar_Sx_noise = 0.002192197540016086; // How much voltage variance should you subtract from Sx fluc measurements? 
Constant vvar_Sy_noise = 0.002510640934040701; // How much voltage variance should you subtract from Sy fluc measurements?

Function main()

	NewDataFolder/s $dfName
	// Should probably make a reference to the df
	
	// Load "SensitivityTotalEZ"
	Loadwave/Q pathToSTEZ
	Wave stez
	Variable xi = DimOffset(stez,0)
	Variable dx = DimDelta(stez,0)
	Variable yi = DimOffset(stez,1)
	Variable dy = DimDelta(stez, 1)
	
	// Load the voltage variance data for Sx and Sy channels
	NewPath/Q/O myPath, pathToData
	LoadWave/Q/J/M/D/N=wave/K=1/P=myPath "variance_Sx"
	Wave wave0
	Rename wave0, vvar_Sx
	LoadWave/Q/J/M/D/N=wave/K=1/P=myPath "variance_Sy"
	Wave wave0
	Rename wave0, vvar_Sy
	Wave vvar_Sx, vvar_Sy
	SetScale/P x, xi, dx, "um", vvar_Sx, vvar_Sy
	SetScale/P y, yi, dy, "um", vvar_Sx, vvar_Sy

	// Load the list of locations where data was taken
	NewPath/Q/O sVsZPath, pathToData + ":sVsZ"
	LoadWave/Q/J/M/D/N=wave/K=1/P=sVsZPath "FilamentLocsAndDirections"
	Wave wave0
	Rename wave0, filLocs_um
	Wave filLocs_um
	Duplicate filLocs_um, filLocs_px
	filLocs_px[][0] -= xi
	filLocs_px[][0] /= dx
	filLocs_px[][1] -= yi
	filLocs_px[][1] /= dy
	
	// Load all the perpendicular scans
	NewDataFolder/S perpScans
	String pixelDataPath = pathToData + ":pixelData"
	load_perpScans(pathString=pixelDataPath)
	Wave allPerpScans_Sx, allPerpScans_Sy
	scale_waves_edit(allPerpScans_Sx, perpScan_rhoi, perpScan_drho, "um")
	scale_waves_edit(allPerpScans_Sy, perpScan_rhoi, perpScan_drho, "um")
	SetDataFolder ::
	
	// Calculate the sensitivites for every data location
	Variable gridSize = DimSize(stez, 0)
	findSensis_simple(allPerpScans_Sx, allPerpScans_Sy, filLocs_px, gridSize, perpScan_iCenter)
	Wave sensis_Sx, sensis_Sy

	// Subtract the voltage variance noise.
	// For now, you have to define the values to be subtracted as constants, at the top of the file
	Duplicate vvar_Sx, vvar_Sx_NS
	vvar_Sx_NS -= vvar_Sx_noise
	vvar_Sx_NS = max(0, vvar_Sx_NS)
	Duplicate vvar_Sy, vvar_Sy_NS
	vvar_Sy_NS -= vvar_Sy_noise
	vvar_Sy_NS = max(0, vvar_Sy_NS)
	
	// Calibrate the data. Remember, the sensitivities are in V/um.
	Duplicate vvar_Sx, flucsX_NS_nm
	flucsX_NS_nm = (sqrt(vvar_Sx_NS) / sensis_Sx) * 1000
	Duplicate vvar_Sy, flucsY_NS_nm
	flucsY_NS_nm = (sqrt(vvar_Sy_NS) / sensis_Sy) * 1000
End
