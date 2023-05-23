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
SetKeyDelay 0

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
			SendEvent ^{%arrow%}
		else if (GetKeyState("Shift"))
			SendEvent +{%arrow%}
		else
			SendEvent {%arrow%}
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

	SendEvent +{%jump%} ; highligh line from cursor position to get it's contents
	Sleep 10 ; move the time to global setting
	SendEvent ^c
	ClipWait 0
	if (ErrorLevel == 1)
	{
		MsgBox End of line or failure reading line!
		Clipboard := clipboardStorage
		return
	}
	lineContents := Clipboard
	SendEvent {%jumpBack%} ; get back to original cursor position

	Input char, L1
	charPosition := InStr(lineContents, char, true, direction == "Right" ? 1 : -1)
	if (charPosition == -1)
	{
		Clipboard := clipboardStorage
		return
	}
	if (direction == "Left")
		charPosition := StrLen(lineContents) - charPosition + 1

	SendEvent {%jumpBack%} ; revert initial arrow press
	; Highlight to found character
	Loop %charPosition%
		SendEvent +{%direction%}

	Clipboard := clipboardStorage
	return
}

; remember INSERT at errors!
; maybe with reset callback or something
highlightInner:
{
	lChar := ""
	rChar := ""
	Input inputtedChar, L1

	; Wait for intrusive modifiers to be lifted
	while (GetKeyState("Ctrl") || GetKeyState("Alt") || GetKeyState("AltGr") || GetKeyState("Shift"))
		Sleep 1

	pairs := "()[]{}<>""""''"
	charIndex := InStr(pairs, inputtedChar)
	if (charIndex == 0)
		return
	lChar := SubStr(pairs, charIndex - !Mod(charIndex, 2), 1)
	rChar := SubStr(pairs, charIndex +  Mod(charIndex, 2), 1)

	clipboardStorage := Clipboard ; AGAIN HANDLE

	; -------------------- TEMP SEPARATOR: REMOVE AFTER REFACTOR

	class Position
	{
		row := 0
		index := 0
		rowsMoved := 0
		found := false

		updatePosition(char, mode)
		{
			if (char != "`r")
				this.index++
			if (char == "`n")
			{
				this.row++
				if (mode == "resetIndexOnNewLine")
					this.index := 0
			}
			return
		}

		debugMsg()
		{
			_row := this.row
			_index := this.index
			_rowsMoved := this.rowsMoved
			_found := this.found
			Sleep 100
			MsgBox, row: %_row%`nindex: %_index%`nrowsMoved: %_rowsMoved%`nfound: %_found%
		}
	}

	lPosition := new Position
	rPosition := new Position

	lPosition := findMatching("Left")

	; Get back to starting position
	while (lPosition.rowsMoved > 0)
	{
		SendEvent {Down}
		lPosition.rowsMoved--
	}

	rPosition := findMatching("Right")

	; Go to rChar
	SendEvent {Left}
	rIndex := rPosition.index
	Loop %rIndex%
		SendEvent {Right}

	; Highlight from rChar to lChar
	rowsToLeftChar := lPosition.row + rPosition.row
	lIndex := lPosition.index
	if (rowsToLeftChar > 0)
	{
		while (rowsToLeftChar > 0)
		{
			SendEvent +{Up}
			rowsToLeftChar--
		}
		SendEvent +{End}
		Loop %lIndex%
			SendEvent +{Left}
	}
	else ; rChar is at the same line as lChar
	{
		total := rIndex + lIndex
		Loop %total%
			SendEvent +{Left}
	}

	if (InStr(A_ThisHotkey, "Delete"))
	{
		SendEvent {Delete}
	}
	else
	{
		; Revert initial press when activated hotkey ; MOVE TO RESETG
		SendEvent {Insert}
	}

	Clipboard := clipboardStorage
	return

	; ----------------- Helpers ----------------------

	findMatching(direction)
	{
		matchCount := { l: 0, r: 0 }
		alreadyScanned := 0
		position := new Position
		Loop
		{
			clipToScan := getClipToAnalyze(direction, alreadyScanned)

			position.rowsMoved += getMovedRows(clipToScan)

			clipLength := StrLen(clipToScan)
			alreadyScanned += clipLength

			scanClip(clipToScan, clipLength, position, matchCount, direction)

			if (position.found)
				break
		}
		return position
	}

	getMovedRows(ByRef clip)
	{
		StrReplace(clip, "`n", "`n", newLinesInClip)
		return newLinesInClip
	}

	getClipToAnalyze(direction, alreadyScanned)
	{
		global rowsToAnalyze
		global inputtedChar
		global verticalDirection
		Clipboard := "" ; this needs to be handled better
		verticalDirection := direction == "Left" ? "Up" : "Down"
		Loop %rowsToAnalyze%
			SendEvent +{%verticalDirection%}
		Sleep 10
		SendEvent ^c
		ClipWait 0
		if (direction == "Left")
			clip := SubStr(Clipboard, 1, StrLen(Clipboard) - alreadyScanned)
		else
			clip := SubStr(Clipboard, alreadyScanned + 1)
		if (clip == "")
		{
			MsgBox Couldn't find matching `'%inputtedChar%`'
			;Clipboard := clipboardStorage ; !!!! HABDLE
			return ""
		}
		return clip
	}

	scanClip(ByRef clipToScan, clipLength, ByRef position, ByRef matches, direction)
	{
		global lChar, rChar
		char := ""
		Loop %clipLength%
		{
			; Get char
			if (direction == "Left")
				char := SubStr(clipToScan, 1 - A_Index, 1)
			else
				char := SubStr(clipToScan, A_Index, 1)

			if (char == lChar)
				matches.l++
			if (char == rChar)
				matches.r++

			; ----------------------------------------

			if (direction == "Left")
				position.updatePosition(char, "resetIndexOnNewLine")
			else
				position.updatePosition(char, "noReset")

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

	checkCounts(counts, direction)
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
