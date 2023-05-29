; documentation and stuff

global rowsToAnalyze := 5

; ---------------------------------------------------------------------------------------
;
;		HOTKEYS
;
; ---------------------------------------------------------------------------------------

; ~arrow & number:: Repeat arrow key presses number of times
arrowList := "Left Right Up Down"
numberList := "1 2 3 4 5 6 7 8 9 0"
Loop Parse, arrowList, " "
{
	arrow = %A_LoopField%
	Loop Parse, numberList, " "
		Hotkey ~%arrow% & %A_LoopField%, repeatArrows
}

; Delete inner or highlight inner
; Equivalent for Vim's "di". Only highlights with insert
~Delete & i Up::
~Insert & i Up::
~Delete & a Up::
~Insert & a Up::gosub highlightInner


; Find character in line
; Wait for character input, find it in current line, highlight to it and move cursor to it
~Left & f Up::
~Right & f Up::gosub findCharInLine

return ; --------------------------------------------------------------------------------
;
;		IMPLEMENTATIONS
;
; ---------------------------------------------------------------------------------------

#NoEnv
#SingleInstance force
#Persistent
#Warn

repeatArrows:
{
	hotkeyElements := StrSplit(A_ThisHotkey, " & ")
	arrow := SubStr(hotkeyElements[1], 2)
	number := SubStr(hotkeyElements[2], 1, 1)
	if (number == 0)
		number := 10

	Loop %number%
	{
		if (GetKeyState("Ctrl"))
			SendInput ^{%arrow%}
		else if (GetKeyState("Shift"))
			SendInput +{%arrow%}
		else
			SendInput {%arrow%}
	}
	return
}

findCharInLine:
{
	clipboardStorage := Clipboard
	Clipboard := "" ; empty always before ClipWait

	direction := InStr(A_ThisHotkey, "Left") ? "Left" : "Right"
	jump      := direction == "Left" ? "Home" : "End"
	jumpBack  := direction == "Left" ? "Right" : "Left"

	SendInput +{%jump%} ; highligh line from cursor position to get it's contents
	Sleep 10 ; move the time to global setting
	SendInput ^c
	ClipWait 0
	if (ErrorLevel == 1)
	{
		MsgBox End of line or failure reading line!
		Clipboard := clipboardStorage
		return
	}
	lineContents := Clipboard
	SendInput {%jumpBack%} ; get back to original cursor position

	Input char, L1
	charPosition := InStr(lineContents, char, true, direction == "Right" ? 1 : -1)
	if (charPosition == -1)
	{
		Clipboard := clipboardStorage
		return
	}
	if (direction == "Left")
		charPosition := StrLen(lineContents) - charPosition + 1

	SendInput {%jumpBack%} ; revert initial arrow press
	; Highlight to found character
	Loop %charPosition%
		SendInput +{%direction%}

	Clipboard := clipboardStorage
	return
}

highlightInner:
{
	lChar := ""
	rChar := ""
	Input inputtedChar, L1

	; Wait for intrusive modifiers to be lifted
	while (GetKeyState("Ctrl") || GetKeyState("Alt") || GetKeyState("AltGr") || GetKeyState("Shift"))
		Sleep 1

	pairs := "()[]{}<>""""''" ; move to settings and add parity checking
	charIndex := InStr(pairs, inputtedChar)
	if (charIndex == 0)
		return
	lChar := SubStr(pairs, charIndex - !Mod(charIndex, 2), 1)
	rChar := SubStr(pairs, charIndex +  Mod(charIndex, 2), 1)

	clipboardStorage := Clipboard

	class Position ; relative to cursor
	{
		row := 0
		column := 0
		found := false
	}
	lPosition := new Position
	rPosition := new Position

	lPosition := findMatching("Left")
	if ( ! lPosition.found)
	{
		MsgBox Couldn't find valid %lChar%!
		goto highlightInnerFinish
	}

	; Get back to starting position
	SendInput {Right}

	; Get cursor position for the case that lChar is on the same line with rChar
	if (lPosition.row == 0)
	{
		Clipboard := ""
		SendInput +{End}
		Sleep 10
		SendInput ^c
		ClipWait 0.1
		if (ErrorLevel == 0)
		{
			lOffset := lPosition.column
			lPosition.column += StrLen(Clipboard)
			SendInput {Left} ; get back
		}
	}

	rPosition := findMatching("Right")

	; There's a bug somewhere which makes findMatching() to always find rChar at the end of file
	if ( ! rPosition.found)
	{
		MsgBox Couldn't find matching %rChar%!
		goto highlightInnerFinish
	}

	; Go to rChar
	SendInput {Left} ; Get back to starting position
	if (rPosition.row > 0)
	{
		SendInput {End}{Right} ; Go to column 0 on next line
		Loop % rPosition.row - 1
			SendInput {Down}
	}
	Loop % rPosition.column
		SendInput {Right}

	; Highlight from rChar to lChar
	rowsToLeftChar := lPosition.row + rPosition.row
	lColumn := lPosition.column
	if (rowsToLeftChar > 0)
	{
		while (rowsToLeftChar > 0)
		{
			SendInput +{Up}
			rowsToLeftChar--
		}
		SendInput +{End}
		Loop %lColumn%
			SendInput +{Left}
	}
	else ; rChar is at the same line as lChar
	{
		Loop % rPosition.column + lOffset
			SendInput +{Left}
	}

	if (InStr(A_ThisHotkey, "Delete"))
		SendInput {Delete}

highlightInnerFinish:

	if (InStr(A_ThisHotkey, "Insert"))
		SendInput {Insert}
	Clipboard := clipboardStorage
	return

	; ----------------- Helpers ----------------------

	findMatching(ByRef direction)
	{
		matchCount := { l: 0, r: 0 }
		alreadyScanned := 0
		position := new Position
		Loop
		{
			clipToScan := getClipToAnalyze(direction, alreadyScanned)
			if (clipToScan.contents == "")
				break ; return with position.found = false
			alreadyScanned += clipToScan.length

			scanClip(clipToScan, position, matchCount, direction)

			if (position.found)
				break
		}
		return position
	}

	getClipToAnalyze(ByRef direction, alreadyScanned)
	{
		global rowsToAnalyze
		global inputtedChar
		global verticalDirection
		Clipboard := ""
		clip := ""
		verticalDirection := direction == "Left" ? "Up" : "Down"
		Loop %rowsToAnalyze%
			SendInput +{%verticalDirection%}
		Sleep 10
		SendInput ^c
		ClipWait 0.1
		if (ErrorLevel == 1 && alreadyScanned == 0) ; we're on 1st/last line and using Notepad.exe
		{
			; Try scanning the current line
			if (direction == "Left")
				SendInput +{Home}
			else
				SendInput +{End}
			Sleep 10
			SendInput ^c
			clip := Clipboard
		}
		else if (direction == "Left")
			clip := SubStr(Clipboard, 1, StrLen(Clipboard) - alreadyScanned)
		else
			clip := SubStr(Clipboard, alreadyScanned + 1)

		return { contents: clip, length: StrLen(clip) }
	}

	scanClip(ByRef clipToScan, ByRef position, ByRef matches, ByRef direction)
	{
		global lChar, rChar
		char := ""
		clipLength := clipToScan.length
		Loop %clipLength%
		{
			; Get char
			if (direction == "Left")
				char := SubStr(clipToScan.contents, 1 - A_Index, 1)
			else
				char := SubStr(clipToScan.contents, A_Index, 1)

			if (char == lChar)
				matches.l++
			if (char == rChar)
				matches.r++

			; ----------------------------------------

			if (char != "`r")
				position.column++
			if (char == "`n")
			{
				position.row++
				position.column := 0
			}

			; --------------------------------------

			if (checkCounts(matches, direction) == "LeftMatch" && direction == "Left")
			{
				position.found := true
				return
			}
			else if (checkCounts(matches, direction) == "RightMatch" && direction == "Right")
			{
				position.found := true
				return
			}
		}
		position.found := false
		return
	}

	checkCounts(counts, ByRef direction)
	{
		global lChar, rChar
		if (direction == "Left" && (counts.l > counts.r || (rChar == lChar && counts.l > 0)))
			return "LeftMatch"
		else if (direction == "Right" && (counts.r > counts.l || (rChar == lChar && counts.r > 0)))
			return "RightMatch"
		else
			return ""
	}
}
