'==============================================================
' TASK 3 - ROBOT CLAW MACHINE   (Epson C3, vacuum nozzle)   v1
'
' How to play:
'   1. Press START (green). If START is not set, FORWARD (blue) starts.
'   2. The claw sweeps left/right  -> press FORWARD (blue) to stop it.
'   3. The claw sweeps front/back  -> press REVERSE (white) to stop it.
'   4. It goes down with the vacuum on. The pressure switch tells if it
'      caught a prize. Caught -> prize goes to the chute (win sound).
'      Missed -> lose sound. Nobody presses -> it stops by itself.
'   RESET (orange) clears the score, STOP (red) ends the program.
'
' Points - teach them with TOOL 1 and LOCAL 0 (world)!
'   ClawA     one corner of the prize area, nozzle touching the TOP of a prize
'   ClawB     opposite corner of the prize area (only X and Y are used)
'   ClawHigh  above the prize area at travel height (home + travel height)
'   ChuteDrop where the prize is released, just above the chute
'
' main  = the game
' main1 = I/O test, prints every input that changes (to find the buttons)
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

' ---------- Working variables ----------
Double DxAB, DyAB, DzUp, DzChute
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
	Tool 1
	Randomize

	' Distances between the taught points. The signs come from the points,
	' so "up" is always towards ClawHigh.
	DxAB = CX(ClawB) - CX(ClawA)
	DyAB = CY(ClawB) - CY(ClawA)
	DzUp = CZ(ClawHigh) - CZ(ClawA)
	DzChute = CZ(ClawHigh) - CZ(ChuteDrop)

	If Abs(DzUp) < 20 Or Abs(DxAB) < 20 Or Abs(DyAB) < 20 Then
		Print "ERROR: check the points (area too small or ClawHigh too low)"
		Exit Function
	EndIf

	VacOff()
	Go ClawHigh
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
	Go ClawHigh
	Print "Claw machine stopped"

Fend

'--------------------------------------------------------------
' One game: two sweeps, drop, check, chute
'--------------------------------------------------------------
Function PlayOneGame
	Boolean caught
	Integer nPass

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
	VacOn()
	SpeedS DownS
	Move ClawA +X(Xs) +Y(Ys)
	caught = CheckVacuum()
	Move ClawA +X(Xs) +Y(Ys) +Z(DzUp)
	SpeedS TravelS

	' optional "weak claw", like a real arcade machine
	If caught = True And WeakClaw > 0 Then
		If Rnd(100) < WeakClaw Then
			Print "Oops! The claw is weak..."
			VacOff()
			caught = False
		EndIf
	EndIf

	' 4) result
	If caught = True Then
		Go ChuteDrop +Z(DzChute)
		Move ChuteDrop
		VacOff()
		Move ChuteDrop +Z(DzChute)
		gWins = gWins + 1
		Print "YOU WIN!"
		Buzz(3, 0.15)
	Else
		VacOff()
		Print "Missed... try again!"
		Buzz(1, 1.0)
	EndIf

	Go ClawHigh
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
