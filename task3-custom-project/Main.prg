'==============================================================
' TASK 3 - ROBOT CLAW MACHINE   (Epson C3, vacuum nozzle)   v1.2
' Cabinet version (v3 box): the claw always goes back to the prize hole
' and releases there. The prize falls down the shaft, slides on the
' internal ramp and comes out on the platform at the front.
'
' How to play:
'   1. Press START (green). If START is not set, FORWARD (blue) starts.
'   2. The claw sweeps left/right  -> press FORWARD (blue) to stop it.
'   3. The claw sweeps front/back  -> press REVERSE (white) to stop it.
'   4. It goes down with the vacuum on. The pressure switch tells if it
'      caught a prize. Then the claw goes back to the prize hole and
'      releases. Caught -> the prize falls to the door (win sound).
'      Missed -> lose sound. Nobody presses -> it stops by itself.
'   If the claw is stopped over the prize hole corner, it doesn't go down.
'   RESET (orange) clears the score, STOP (red) ends the program.
'
' Points - teach them with TOOL 1 and LOCAL 0 (world)!
'   ClawA     FRONT-LEFT mark on the play floor, nozzle touching the TOP of a capsule
'   ClawB     BACK-RIGHT mark on the play floor (only X and Y are used)
'   ClawHigh  above the play floor at travel height (only Z is used)
'   HoleDrop  above the centre of the prize hole, at travel height
'             (home of the claw + where it releases)
'
' main  = the game
' main1 = I/O test, prints every input that changes (to find the buttons)
'
' v1.2: Tool 1 is set by code at the start (the controller is shared
'       with other groups and they sometimes change it)
'==============================================================

' ---------- I/O numbers (fill in after running main1) ----------
Integer BtnStart     ' green  (latching)   -1 = not used
Integer BtnStop      ' red    (latching)   -1 = not used
Integer BtnReset     ' orange (latching)   -1 = not used
Integer BtnX         ' blue   (momentary)  stops the left/right sweep
Integer BtnY         ' white  (momentary)  stops the front/back sweep
Integer VacIn        ' vacuum pressure switch input, -1 = no sensor
Integer VacOkLevel   ' value of VacIn when a part is held (1 or 0)
Integer BuzzerOut    ' buzzer output, -1 = no buzzer
Integer VacOut       ' vacuum output

' ---------- Game settings ----------
Boolean UseVacuum    ' False = dry run (vacuum never turns on)
Integer TravelS      ' normal linear speed [mm/s]
Integer SweepS       ' sweep speed [mm/s] (higher = harder)
Integer DownS        ' speed going down to the prize [mm/s]
Integer MaxPasses    ' sweeps before the claw stops by itself
Double VacWait       ' max time to wait for the vacuum sensor [s]
Integer WeakClaw     ' % chance that the claw drops the prize (0 = fair)
Double HoleFracX     ' prize hole corner (front-right): no grab if the claw
Double HoleFracY     ' stops with X beyond HoleFracX and Y before HoleFracY

' ---------- Working variables ----------
Double DxAB, DyAB, DzUp
Double Xs, Ys
Integer StopPrev
Global Preserve Integer gGames     ' kept even after a power cut
Global Preserve Integer gWins

Function main

	' ---- I/O numbers ----
	BtnStart = -1
	BtnStop = -1
	BtnReset = -1
	BtnX = -1
	BtnY = -1
	VacIn = -1
	VacOkLevel = 1
	BuzzerOut = -1
	VacOut = 8

	' ---- Game settings ----
	UseVacuum = False    ' first test: False. Then True.
	TravelS = 300
	SweepS = 80          ' first test slow, later 120-200
	DownS = 50
	MaxPasses = 4
	VacWait = 0.8
	WeakClaw = 0
	HoleFracX = 2.0      ' 2.0 = OFF (no cabinet yet). With the printed cabinet: 0.63
	HoleFracY = 0.38

	If BtnX < 0 Or BtnY < 0 Then
		Print "ERROR: set BtnX and BtnY first (run main1 to find the inputs)"
		Exit Function
	EndIf

	Motor On
	Power High
	Speed 30
	Accel 30, 30
	SpeedS TravelS
	AccelS 2000
	TLSet 1, XY(-0.762, -2.677, 74.499, 0, 0, 0)   ' our vacuum nozzle
	Tool 1
	Randomize

	' Distances between the taught points. The signs come from the points,
	' so "up" is always towards ClawHigh.
	DxAB = CX(ClawB) - CX(ClawA)
	DyAB = CY(ClawB) - CY(ClawA)
	DzUp = CZ(ClawHigh) - CZ(ClawA)

	If Abs(DzUp) < 20 Or Abs(DxAB) < 20 Or Abs(DyAB) < 20 Then
		Print "ERROR: check the points (area too small or ClawHigh too low)"
		Exit Function
	EndIf

	VacOff()
	Go HoleDrop
	If BtnStop >= 0 Then
		StopPrev = Sw(BtnStop)
	EndIf

	Do
		Print "Games = ", gGames, "   Wins = ", gWins
		Print "Press START to play"
		If WaitForStart() = False Then
			Exit Do
		EndIf
		PlayOneGame()
	Loop

	VacOff()
	Go HoleDrop
	Print "Claw machine stopped"

Fend

'--------------------------------------------------------------
' One game: two sweeps, go down, check, back to the hole, release
'--------------------------------------------------------------
Function PlayOneGame
	Boolean caught
	Integer nPass
	Double fx, fy

	gGames = gGames + 1
	Buzz(2, 0.1)

	' 1) left/right sweep at travel height
	Print "Stop the claw with FORWARD (blue)"
	SpeedS TravelS
	Go ClawA +Z(DzUp)
	SpeedS SweepS
	nPass = 0
	Do
		If nPass Mod 2 = 0 Then
			Move ClawA +X(DxAB) +Z(DzUp) Till Sw(BtnX) = On
		Else
			Move ClawA +Z(DzUp) Till Sw(BtnX) = On
		EndIf
		nPass = nPass + 1
	Loop Until TillOn = True Or nPass >= MaxPasses
	P50 = P*
	Xs = CX(P50) - CX(ClawA)

	' 2) front/back sweep
	Print "Now stop it with REVERSE (white)"
	Wait 0.3
	nPass = 0
	Do
		If nPass Mod 2 = 0 Then
			Move ClawA +X(Xs) +Y(DyAB) +Z(DzUp) Till Sw(BtnY) = On
		Else
			Move ClawA +X(Xs) +Z(DzUp) Till Sw(BtnY) = On
		EndIf
		nPass = nPass + 1
	Loop Until TillOn = True Or nPass >= MaxPasses
	P50 = P*
	Ys = CY(P50) - CY(ClawA)

	' 3) go down with the vacuum on and check the sensor
	'    (not over the prize hole corner: there is nothing to grab there)
	fx = Xs / DxAB
	fy = Ys / DyAB
	If fx > HoleFracX And fy < HoleFracY Then
		Print "Prize hole corner, nothing to grab!"
		caught = False
	Else
		VacOn()
		SpeedS DownS
		Move ClawA +X(Xs) +Y(Ys)
		caught = CheckVacuum()
		Move ClawA +X(Xs) +Y(Ys) +Z(DzUp)
	EndIf
	SpeedS TravelS

	' optional "weak claw", like a real arcade machine
	If caught = True And WeakClaw > 0 Then
		If Rnd(100) < WeakClaw Then
			Print "Oops! The claw is weak..."
			VacOff()
			caught = False
		EndIf
	EndIf

	' 4) back to the prize hole and release (always, like a real machine)
	Go HoleDrop
	VacOff()
	If caught = True Then
		gWins = gWins + 1
		Print "YOU WIN! Take your prize from the door"
		Buzz(3, 0.15)
	Else
		Print "Missed... try again!"
		Buzz(1, 1.0)
	EndIf
Fend

'--------------------------------------------------------------
' Waits for START. Also handles STOP and RESET while waiting.
' Returns False when STOP was pressed.
'--------------------------------------------------------------
Function WaitForStart As Boolean
	Integer sPrev, rPrev

	sPrev = -1
	rPrev = -1
	If BtnStart >= 0 Then
		sPrev = Sw(BtnStart)
	EndIf
	If BtnReset >= 0 Then
		rPrev = Sw(BtnReset)
	EndIf

	Do
		' START is latching: any change of state starts the game
		If BtnStart >= 0 Then
			If Sw(BtnStart) <> sPrev Then
				WaitForStart = True
				Exit Function
			EndIf
		Else
			If Sw(BtnX) = On Then
				Do While Sw(BtnX) = On      ' wait until it is released
					Wait 0.02
				Loop
				WaitForStart = True
				Exit Function
			EndIf
		EndIf

		' STOP is latching: any change ends the program
		If BtnStop >= 0 Then
			If Sw(BtnStop) <> StopPrev Then
				WaitForStart = False
				Exit Function
			EndIf
		EndIf

		' RESET is latching: any change clears the score
		If BtnReset >= 0 Then
			If Sw(BtnReset) <> rPrev Then
				rPrev = Sw(BtnReset)
				gGames = 0
				gWins = 0
				Print "Score cleared"
				Buzz(1, 0.4)
			EndIf
		EndIf

		Wait 0.05
	Loop
Fend

'--------------------------------------------------------------
' True if the vacuum sensor says a part is held
'--------------------------------------------------------------
Function CheckVacuum As Boolean
	Integer k

	If UseVacuum = False Or VacIn < 0 Then
		Wait 0.5
		CheckVacuum = True       ' no sensor: assume caught (to test the path)
		Exit Function
	EndIf

	For k = 1 To Int(VacWait / 0.05)
		If Sw(VacIn) = VacOkLevel Then
			CheckVacuum = True
			Exit Function
		EndIf
		Wait 0.05
	Next
	CheckVacuum = False
Fend

'--------------------------------------------------------------
' Vacuum and buzzer helpers
'--------------------------------------------------------------
Function VacOn
	If UseVacuum = True Then
		On VacOut
	EndIf
	Wait 0.5
Fend

Function VacOff
	If UseVacuum = True Then
		Off VacOut
	EndIf
	Wait 0.3
Fend

Function Buzz(n As Integer, t As Double)
	Integer i
	If BuzzerOut < 0 Then
		Exit Function
	EndIf
	For i = 1 To n
		On BuzzerOut
		Wait t
		Off BuzzerOut
		Wait t
	Next
Fend

'--------------------------------------------------------------
' main1: I/O test. Press the buttons and watch the Run Window.
' Stop it with the Stop button of the Run Window.
'--------------------------------------------------------------
Function main1
	Integer i
	Integer prev(23)

	For i = 0 To 23
		prev(i) = Sw(i)
	Next
	Print "I/O test: press each button. Every input that changes is printed."

	Do
		For i = 0 To 23
			If Sw(i) <> prev(i) Then
				prev(i) = Sw(i)
				Print "Input ", i, " = ", prev(i)
			EndIf
		Next
		Wait 0.05
	Loop
Fend
