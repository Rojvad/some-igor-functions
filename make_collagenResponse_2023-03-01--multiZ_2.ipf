#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function make_collagenResponse()
	NewDataFolder/S root:multiZ_2
	NewPath myPath, "C:Users:Jordan:Box:ActivityMicroscopy:data:2023-03-01--Collagen_AlSampleHolder--JZ:multiZ_2:aMic_zLayers:layer5"
	LoadWave/H/P=myPath "Sy.ibw"
	Wave Sy
	Make/O/N=(DimSize(Sy, 1)) Sy_lay5_lp_x373 = Sy(37.3)[p]
	SetScale/P x, DimOffset(Sy, 1), DimDelta(Sy, 1), WaveUnits(Sy, 1), Sy_lay5_lp_x373
	Make/O/N=2 bar =  {2.709, 2.709}
	SetScale/P x, 40.7, 1.5, "um", bar
	Display/N=collagenResponse/W=(728.25,187.25,1122.75,395.75) Sy_lay5_lp_x373,bar
	ModifyGraph mode(Sy_lay5_lp_x373)=4
	ModifyGraph lSize(bar)=2
	ModifyGraph rgb(bar)=(0,0,0)
	Label left "\\Z16Sy [V]"
	Label bottom "\\Z16y [um]"
	TextBox/C/N=text0/F=0/A=LT/X=0.00/Y=0.00 "2023-03-01, multiZ_2, lay5\r\nSy gain = 100\r\nx=37.3 um"
	TextBox/C/N=text1/F=0/A=LT/X=61.56/Y=19.81 "\\Z161.5 um"
	SetDrawLayer UserFront
	SetDrawEnv linethick= 1.5,arrow= 1
	DrawLine 0.726415094339623,0.314009661835749,0.768867924528302,0.473429951690821
End