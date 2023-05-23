; documentation and stuff

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
~Insert & i Up::gosub highlightInner


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

	clipboardStorage := Clipboard

	lRow := 0
	rRow := 0
	lColumn := 0 ; counting from end of line
	rIndex := 0

	rowsToAnalyze := 5 ; make this a global setting
	rowsMoved := 0

	; These change after first iteration to "Right" and "Down"
	direction := "Left"
	verticalDirection := "Up"
	Loop 2 ; find left then right
	{
		row := 0
		lCount := 0
		rCount := 0
		clipLength := 0
		alreadyScanned := 0
		Loop
		{
			Clipboard := ""
			Loop %rowsToAnalyze%
				SendEvent +{%verticalDirection%}
			Sleep 10
			SendEvent ^c
			ClipWait 0
			if (direction == "Left")
				clipToScan := SubStr(Clipboard, 1, StrLen(Clipboard) - alreadyScanned)
			else
				clipToScan := SubStr(Clipboard, alreadyScanned + 1)
			if (clipToScan == "")
			{
				MsgBox Couldn't find matching `'%inputtedChar%`'
				Clipboard := clipboardStorage
				return
			}

			; Check if close to start/end of file for correct rowsMoved by counting new lines
			; Get `n count with dummy StrReplace() which counts replacements to newLinesInClip
			StrReplace(clipToScan, "`n", "`n", newLinesInClip)
			rowsMoved += newLinesInClip

			clipLength := StrLen(clipToScan)
			alreadyScanned += clipLength

			Loop %clipLength%
			{
				; Get char
				if (direction == "Left")
					char := SubStr(clipToScan, 1 - A_Index, 1)
				else
					char := SubStr(clipToScan, A_Index, 1)

				; Compare character
				if (char == lChar)
					lCount++
				if (char == rChar)
					rCount++

				; --------------------------------------
				;	Check counts
				if (direction == "Left")
				{
					if (lCount > rCount || (rChar == lChar && lCount > 0))
					{
						lRow := row
						break 2
					}
				}
				else if (direction == "Right")
				{
					if (rCount > lCount || (rChar == lChar && rCount > 0))
					{
						rRow := row
						break 2
					}
				}

				; ----------------------------------------
				;	Check newline
				if (char != "`r")
				{
					if (direction == "Right")
						rIndex++
					else
						lColumn++
				}
				if (char == "`n")
				{
					row++
					if (direction == "Left")
						lColumn := 0
				}
			}
		}

		if (A_Index == 2) ; done finding lChar and rChar
			break

		; Get back to starting position
		while (rowsMoved > 0)
		{
			SendEvent {Down}
			rowsMoved--
		}
		direction := "Right"
		verticalDirection := "Down"
	}

	; Go to rChar
	SendEvent {Left}
	Loop %rIndex%
		SendEvent {Right}

	; Highlight from rChar to lChar
	rowsToLeftChar := lRow + rRow
	if (rowsToLeftChar > 0)
	{
		while (rowsToLeftChar > 0)
		{
			SendEvent +{Up}
			rowsToLeftChar--
		}
		SendEvent +{End}
		Loop %lColumn%
			SendEvent +{Left}
	}
	else ; rChar is at the same line as lChar
	{
		total := rIndex + lColumn
		Loop %total%
			SendEvent +{Left}
	}

	if (InStr(A_ThisHotkey, "Delete"))
	{
		SendEvent {Delete}
	}
	else
	{
		; Revert initial press when activated hotkey
		;if (GetKeyState("Insert", "T"))
			SendEvent {Insert}
	}

	Clipboard := clipboardStorage
	return
}
