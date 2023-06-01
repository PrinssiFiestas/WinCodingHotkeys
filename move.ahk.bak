; ---------------------------------------------------------------------------------------
;
;		GLOBAL SETTINGS
;
; ---------------------------------------------------------------------------------------

; Increasing this might increase speed for multi-line operations, but may introduce
; pointless scrolling
global rowsToAnalyze := 5

; Increasing these might help if hotkeys fail sometimes
global highlightWaitTime := 1
global clipWaitTime := 0.01

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
~Delete & i UP::
~Insert & i UP::highlightInner(false)
~Delete & a UP::
~Insert & a UP::highlightInner(true)

; Find character in line
; Wait for character input, find it in current line, highlight to it and move cursor to it
~Left & f UP::
~Right & f UP::
~Left & t UP::
~Right & t UP::gosub findCharInLine

; Copy or cut
; Press 'i', 'a', 'f' or 't' while holding 'Ctrl' for combined function or press twice to
; copy/cut line
~^~c UP::
~^~x UP::gosub copy

; Highlight line
~Insert & Left::
~Insert & Right::
~Insert & Up::
~Insert & Down::highlightLine(StrSplit(A_ThisHotkey, " & ")[2])

; Delete line
~Delete & d::gosub deleteLine

; Move and scroll up/down
; Only works with editors that scroll with ^Up or ^Down
; Note that scroll() may also be called in repeatArrows
<^>!Up::
RAlt & Up::scroll("Up")
<^>!Down::
RAlt & Down::scroll("Down")

return ; --------------------------------------------------------------------------------
;
;		IMPLEMENTATIONS
;
; ---------------------------------------------------------------------------------------

#NoEnv
#SingleInstance force
#Persistent
#Warn

getHighlightedContents()
{
	clipboardStorage := Clipboard
	Clipboard := ""
	Sleep % highlightWaitTime
	SendInput ^c
	ClipWait % clipWaitTime
	contents := Clipboard
	Clipboard := clipboardStorage
	return contents
}

; ---------------------------------------------------------------------------------------

repeatArrows:
{
	hotkeyElements := StrSplit(A_ThisHotkey, " & ")
	arrow := SubStr(hotkeyElements[1], 2)
	number := SubStr(hotkeyElements[2], 1, 1)
	if (number == 0)
		number := 10

	Loop % number
	{
		if (GetKeyState("RAlt") || GetKeyState("AltGr"))
			scroll(arrow)
		else if (GetKeyState("Ctrl"))
			SendInput ^{%arrow%}
		else if (GetKeyState("Shift"))
			SendInput +{%arrow%}
		else if (GetKeyState("Alt"))
			SendInput !{%arrow%}
		else
			SendInput {%arrow%}
	}
	return
}

; ---------------------------------------------------------------------------------------
; ---------------------------------------------------------------------------------------

findCharInLine:
{
	direction := InStr(A_ThisHotkey, "Left") ? "Left" : "Right"
	jump      := direction == "Left" ? "Home" : "End"
	jumpBack  := direction == "Left" ? "Right" : "Left"

	SendInput +{%jump%}
	lineFromCursor := getHighlightedContents()

	if (lineFromCursor == "")
	{
		MsgBox End of line or failure reading line!
		return
	}
	SendInput {%jumpBack%} ; get back to original cursor position

	Input char, L1
	charPosition := InStr(lineFromCursor, char, true, direction == "Right" ? 1 : -1)
	if (charPosition == -1)
		return

	if (direction == "Left")
		charPosition := StrLen(lineFromCursor) - charPosition + 1

	SendInput {%jumpBack%} ; revert initial arrow press
	; Highlight to found character
	Loop % charPosition + (InStr(A_ThisHotkey, " f ") != 0)
		SendInput +{%direction%}

	return
}

; ---------------------------------------------------------------------------------------
; ---------------------------------------------------------------------------------------

scroll(direction)
{
	SendInput ^{%direction%}{%direction%}
	return
}

; ---------------------------------------------------------------------------------------
; ---------------------------------------------------------------------------------------

; Highlight full line including newline from previous line
; Usually it's better to use _highlightLine(), but this might be faster
; Highlighted line is copied so checking if first line can be done by InStr(Clipboard, "´n")
_highlightLineUp()
{
	SendInput {End}+{Up}
	lineContents := getHighlightedContents()
	if (InStr(lineContents, "`n"))
		SendInput +{End}
	if (lineContents == "") ; try again with different method
		SendInput {End}+{Home}+{Home}
	return lineContents
}

; ---------------------------------------------------------------------------------------
; ---------------------------------------------------------------------------------------

deleteLine:
{
	lineToDelete := _highlightLineUp()
	onFirstLine := ! InStr(lineToDelete, "`n")

	if (onFirstLine)
		SendInput {Backspace}{Delete}
	else
		SendInput +{End}{BackSpace}{Right}

	return
}

; ---------------------------------------------------------------------------------------
; ---------------------------------------------------------------------------------------

highlightLine(direction)
{
	_highlightLine(direction)
	SendInput {Insert} ; revert inital press
	return
}

_highlightLine(direction)
{
	highlighted := _highlightLineUp()
	notOnFirstLine := InStr(highlighted, "`n")

	if (direction == "Left" && notOnFirstLine)
		SendInput +{Right}
	else if (direction == "Right" && notOnFirstLine)
		SendInput {End}{Right}+{End}
	else if (direction == "Down" && notOnFirstLine)
		SendInput {End}{Right}+{End}+{Right}
	else if (direction == "Right")
		SendInput {Left}+{End}
	else if (direction == "Down")
		SendInput {Left}+{End}+{Right}

	return
}

; ---------------------------------------------------------------------------------------
; ---------------------------------------------------------------------------------------

copy:
{
	key := ""
	keylist := "i a f t c x"

	; Poll for follow-up key
	while (GetKeyState("Ctrl"))
	{
		Sleep 1
		Loop Parse, keylist, " "
		{
			if (GetKeyState(A_LoopField))
			{
				key := A_LoopField
				break 2
			}
		}
	}

	if (key == "c")
	{
		SendInput +{End}
		lineEnd := getHighlightedContents()
		startingPosition := StrLen(lineEnd)

		_highlightLine("Left")
		line := getHighlightedContents()
		if (line != "")
			Clipboard := line

		SendInput {End}
		Loop % startingPosition
			SendInput {Left}
	}
	else if (key == "x")
	{
		_highlightLine("Left")
		line := getHighlightedContents()
		if (line != "")
			Clipboard := line
		SendInput {Delete}{Backspace}
	}

	return
}

; ---------------------------------------------------------------------------------------
; ---------------------------------------------------------------------------------------

class Position
{
	row := 0 ; relative to cursor

	; Columns are relative to cursor position when rChar and lChar are on the same
	; line. Otherwise lChar column is relative to line end and rChar is relative to
	; line start. These cases have to be handled separately to increase speed by
	; eliminating the need for redundant scan for line position or always moving
	; relative to cursor position.
	column := 0

	found := false
}

highlightInner(isInclusive)
{
	positions := _highlightInner(isInclusive)
	if ((!positions[1].found) || (!positions[2].found))
		return

	if      (InStr(A_ThisHotkey, "Insert"))
		SendInput {Insert}
	else if (InStr(A_ThisHotkey, "Delete"))
		SendInput {Delete}
	return
}

_highlightInner(isInclusive)
{
	global lChar := ""
	global rChar := ""
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

	; --------------------------------------------

	lPosition := new Position
	rPosition := new Position

	lPosition := _findMatching("Left", isInclusive)
	if ( ! lPosition.found)
	{
		MsgBox Couldn't find valid %lChar%!
		return [lPosition, rPosition]
	}

	; Get back to starting position
	SendInput {Right}

	rPosition := _findMatching("Right", isInclusive)

	; There's a bug somewhere which makes _findMatching() to always find rChar at the end
	; of file so !rPosition.found is always false, but don't remove it! Fix the bug!
	if ( ! rPosition.found)
	{
		MsgBox Couldn't find matching %rChar%!
		return [lPosition, rPosition]
	}

	; Get back to starting position
	SendInput {Left}

	; ----------------------------------------------------
	;	Special cases

	; When rChar is on the same line with lChar position.column can be used directly
	if (lPosition.row == 0 && rPosition.row == 0)
	{
		Loop % rPosition.column
			SendInput {Right}
		Loop % rPosition.column + lPosition.column
			SendInput +{Left}
		return [lPosition, rPosition]
	}

	; When rChar is on different line than rChar and lPosition is on the first line, then
	; column needs to be updated to be relative to line end rather than cursor so it can be
	; found reliably
	if (lPosition.row == 0 && rPosition.row > 0)
	{
		SendInput +{End}
		lineTail := getHighlightedContents()
		if (lineTail != "")
		{
			lOffset := lPosition.column
			lPosition.column += StrLen(lineTail)
			SendInput {Left} ; get back
		}
	}

	; ----------------------------------------------------

	; Go to rChar
	if (rPosition.row > 0)
	{
		SendInput {End}{Right}
		Loop % rPosition.row - 1
			SendInput {Down}
	}
	Loop % rPosition.column
		SendInput {Right}

	; Highlight from rChar to lChar
	rowsToLeftChar := lPosition.row + rPosition.row
	while (rowsToLeftChar > 0)
	{
		SendInput +{Up}
		rowsToLeftChar--
	}
	SendInput +{End}
	Loop % lPosition.column
		SendInput +{Left}

	return [lPosition, rPosition]
}

; -------------------------------------------------
;	Helpers for highlightInner

_findMatching(ByRef direction, isInclusive)
{
	matchCount := { l: 0, r: 0 }
	alreadyScanned := 0
	position := new Position
	Loop
	{
		clipToScan := _getClipToAnalyze(direction, alreadyScanned)
		if (clipToScan.contents == "")
			break ; return with position.found = false
		alreadyScanned += clipToScan.length

		_scanClip(clipToScan, position, matchCount, direction)

		if (position.found)
			break
	}
	if ( ! isInclusive)
		position.column--
	return position
}

_getClipToAnalyze(ByRef direction, alreadyScanned)
{
	global rowsToAnalyze

	verticalDirection := direction == "Left" ? "Up" : "Down"
	Loop %rowsToAnalyze%
		SendInput +{%verticalDirection%}
	rows := getHighlightedContents()

	if (rows == "" && alreadyScanned == 0) ; we're on 1st/last line on Notepad.exe
	{
		; Try scanning the current line
		if (direction == "Left")
			SendInput +{Home}
		else
			SendInput +{End}
		clip := getHighlightedContents()
	}
	else if (direction == "Left")
		clip := SubStr(rows, 1, StrLen(rows) - alreadyScanned)
	else
		clip := SubStr(rows, alreadyScanned + 1)

	return { contents: clip, length: StrLen(clip) }
}

_scanClip(ByRef clipToScan, ByRef position, ByRef matches, ByRef direction)
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

		if (_checkCounts(matches, direction) == "LeftMatch" && direction == "Left")
		{
			position.found := true
			return
		}
		else if (_checkCounts(matches, direction) == "RightMatch" && direction == "Right")
		{
			position.found := true
			return
		}
	}
	position.found := false
	return
}

_checkCounts(counts, ByRef direction)
{
	global lChar, rChar
	if (direction == "Left" && (counts.l > counts.r || (rChar == lChar && counts.l > 0)))
		return "LeftMatch"
	else if (direction == "Right" && (counts.r > counts.l || (rChar == lChar && counts.r > 0)))
		return "RightMatch"
	else
		return ""
}

