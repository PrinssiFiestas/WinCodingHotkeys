#NoEnv
#Warn
#Persistent
SetKeyDelay 100
#SingleInstance, Force
CoordMode, Mouse, Screen

X := []
Y := []
n_columns := 12
n_rows := 4

; ---------------------------------------------------------------------------------------
;
;       SETTINGS
;
; ---------------------------------------------------------------------------------------

; Distances from the edge of the screen to edge coordinates of mouse jump
margins_v := A_ScreenWidth/10
margins_h := A_ScreenHeight/20

; Settings for arrow mouse movement
displacement := A_ScreenWidth/20
displacement_short := A_ScreenWidth/100
displacement_speed := 1

;   End of settings
;  ------------------------------------

; Set the coordinates for mouse jump
Loop % n_columns
    X[A_Index] := (A_Index - 1)*(A_ScreenWidth - margins_v)/(n_columns - 1) + margins_v/2
Loop % n_rows
    Y[A_Index] := (A_Index - 1)*(A_ScreenHeight - margins_h)/(n_rows - 1) + margins_h/2

; ---------------------------------------------------------------------------------------
;
;       HOTKEYS
;
; ---------------------------------------------------------------------------------------

; Note that in Windows language settings if you have set shift key to the key that turns
; caps off then this script wont work. Better alternative can be found in numpadcaps.ahk

; CapsLock & AnyCharacterKey::Move mouse to physically matching key location
scan_codes := "sc002 sc003 sc004 sc005 sc006 sc007 sc008 sc009 sc00A sc00B sc00C sc00D sc010 sc011 sc012 sc013 sc014 sc015 sc016 sc017 sc018 sc019 sc01A sc01B sc01E sc01F sc020 sc021 sc022 sc023 sc024 sc025 sc026 sc027 sc028 sc02B sc056 sc02C sc02D sc02E sc02F sc030 sc031 sc032 sc033 sc034 sc035 Rshift"
Loop Parse, scan_codes, " "
    Hotkey CapsLock & %A_LoopField%, mouseJump

; Move mouse with arrows. Hold Shift for fine movement
CapsLock & Up::
CapsLock & Down::
CapsLock & Left::
CapsLock & Right::gosub moveMouse

CapsLock & Enter::Click
CapsLock & BackSpace::Click, R

; Focus window under mouse cursor
CapsLock & Space::gosub focusWindow

return ; --------------------------------------------------------------------------------
;
;       IMPLEMENTATIONS
;
; ---------------------------------------------------------------------------------------

mouseJump:
{

    key := StrSplit(A_ThisHotkey, " & ")[2]
    scan_code_strlen := StrLen(StrSplit(scan_codes, " ")[1]) + 1 ; = 6

    key_i := (InStr(scan_codes, key) - 1)/scan_code_strlen

    x_i := Mod(key_i, n_columns) + 1
    x_i := Floor(x_i) ; cast to int
    x1 := X[x_i]

    y_i := Mod(key_i/n_columns, n_rows) + 1
    y_i := Floor(y_i)
    y1 := Y[y_i]

    MouseMove %x1%, %y1%, 2
    return
}

moveMouse:
{
    MouseGetPos, x0, y0
    d := GetKeyState("LShift") ? displacement_short : displacement
    direction := StrSplit(A_ThisHotkey, " & ")[2]
    x_direction := direction == "Left" ? -1 : direction == "Right" ? 1 : 0
    y_direction := direction == "Up"   ? -1 : direction == "Down"  ? 1 : 0

    x1 := x0 + x_direction * d
    y1 := y0 + y_direction * d

    MouseMove, %x1%, %y1%, %displacement_speed%
    return
}

focusWindow:
{
    MouseGetPos,,, hwnd
    WinActivate, ahk_id %hwnd%
    return
}