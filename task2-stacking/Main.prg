'==============================================================
' TASK 2 - STACKING  (Epson C3-A600S, vacuum nozzle)
'
' Based on our Task 1 (pick and place). Only 2 locals are used:
'   Local 1 = Infeed  (Infeed_Token, Infeed_Block, Retract_Safe)
'   Local 3 = Tray    (Tray_Token)
' The alignment station (Local 2) is NOT used in this task.
'
' The robot builds ONE tower in the tray pocket at Tray_Token:
'   level 0 = token, level 1 = block, level 2 = token, ...
' Parts are taken from the infeed stacks, from the top down.
'
' Note: in our locals -Z points UP (same as in Task 1).
'==============================================================

' ---------- Settings (change here) ----------
Integer NTokens      ' number of tokens in the infeed stack
Integer NBlocks      ' number of blocks in the infeed stack
Double PartH         ' height of one part [mm]
Double PlaceGap      ' release the part a little above the tower [mm]
Double ApproachH     ' approach height above the tower [mm]
Integer FastS        ' normal SpeedS [mm/s]
Integer SlowS        ' SpeedS for the last mm down onto the tower [mm/s]
Boolean UseIO        ' False = dry run (vacuum never turns on)
                     ' True  = uses output 8 (vacuum)

' ---------- Working variables ----------
Integer TokLeft      ' tokens left in the infeed
Integer BlkLeft      ' blocks left in the infeed
Integer StackLvl     ' tower level where the next part goes

Function main

	NTokens = 5
	NBlocks = 5
	PartH = 6.0
	PlaceGap = 0.5
	ApproachH = 40
	FastS = 500          ' we used 100 for the first test
	SlowS = 30           ' keep it low, this is the move onto the tower
	UseIO = True         ' step 1: False (dry run, no I/O)  step 2: True (with I/O)

	Motor On
	Power High
	Speed 10             ' PTP speed [%], 10 while testing, 30 later
	Accel 30, 30
	SpeedS FastS
	AccelS 5000
	Tool 1

	TokLeft = NTokens
	BlkLeft = NBlocks
	StackLvl = 0

	If UseIO = True Then
		Print "Task 2 - Stacking WITH I/O (vacuum on output 8)"
	Else
		Print "Task 2 - Stacking WITHOUT I/O (dry run, infeed and tray must be empty)"
	EndIf
	Print "Levels to build = ", NTokens + NBlocks
	VacOff()
	Go Retract_Safe

	' Alternate token, block, token, block... until the infeed is empty
	Do While TokLeft > 0 Or BlkLeft > 0

		If TokLeft > 0 Then
			Pick_Token(TokLeft - 1)      ' top part of the stack
			TokLeft = TokLeft - 1
			Place_Stack(StackLvl)
			StackLvl = StackLvl + 1
		EndIf

		If BlkLeft > 0 Then
			Pick_Block(BlkLeft - 1)
			BlkLeft = BlkLeft - 1
			Place_Stack(StackLvl)
			StackLvl = StackLvl + 1
		EndIf

	Loop

	Go Retract_Safe
	Print "Done. Levels in the tower = ", StackLvl

Fend

'--------------------------------------------------------------
' Vacuum: only touches output 8 when UseIO = True
'--------------------------------------------------------------
Function VacOn
	If UseIO = True Then
		On 8
	EndIf
	Wait 0.5
Fend

Function VacOff
	If UseIO = True Then
		Off 8
	EndIf
	Wait 0.5
Fend

'--------------------------------------------------------------
' Pick from the infeed. idx = position in the stack (0 = bottom)
' Infeed_Token / Infeed_Block are taught on the bottom part.
'--------------------------------------------------------------
Function Pick_Token(idx As Integer)
	Print "Pick token from infeed, idx = ", idx
	Go Infeed_Token -Z(50 + idx * PartH)
	Move Infeed_Token -Z(idx * PartH)
	VacOn()
	Move Infeed_Token +X(-1) -Z(50 + idx * PartH)
Fend

Function Pick_Block(idx As Integer)
	Print "Pick block from infeed, idx = ", idx
	Go Infeed_Block -Z(50 + idx * PartH)
	Move Infeed_Block -Z(idx * PartH)
	VacOn()
	Move Infeed_Block +X(-1) +Y(1) -Z(60 + idx * PartH)
Fend

'--------------------------------------------------------------
' Place on the tower. lvl = level (0 = bottom, inside the pocket)
' Every level is PartH higher than the one below.
'--------------------------------------------------------------
Function Place_Stack(lvl As Integer)
	Double zUp
	zUp = lvl * PartH + PlaceGap
	Print "Place on tower, level = ", lvl
	Go Tray_Token -Z(zUp + ApproachH)     ' above the tower
	SpeedS SlowS
	Move Tray_Token -Z(zUp)               ' straight down, slow
	VacOff()
	Move Tray_Token -Z(zUp + ApproachH)   ' straight up
	SpeedS FastS
Fend
