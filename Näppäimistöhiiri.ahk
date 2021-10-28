#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
; SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

SetKeyDelay 100
#SingleInstance, Force

CoordMode, Mouse, Screen



X := []
Y := []
marginaalit := A_ScreenWidth/10
yla_ala_vali := A_ScreenHeight/20

siirtyma := A_ScreenWidth/20
lyhyempi_siirtyma := A_ScreenWidth/95
siirtyman_nopeus := 1

i := 0
Loop 10
{
    X[i+1] := i * (A_ScreenWidth - marginaalit) / 9 + marginaalit/2
    i++
}
i := 0
Loop 4
{
    Y[i+1] := i * (A_ScreenHeight - yla_ala_vali) / 3 + yla_ala_vali/2
    i++
}

HotkeyList := "34567890+´wertyuiopåasdfghjklö<zxcvbnm,."

Loop, Parse, HotkeyList
{
    Hotkey, CapsLock & %A_LoopField%, KoordinaattiLoikkari
}

Return

penis:=0
KoordinaattiLoikkari:
{
    nappain := SubStr(A_ThisHotkey, 12)
    nappain_num := InStr(HotkeyList, nappain)
    x1 := X[ Mod(nappain_num, 10) + (Mod(nappain_num,10)==0)*10 ]
    y1 := Y[ Floor( (nappain_num - Mod(nappain_num, 10))/10 + 1 - (Mod(nappain_num, 10)==0) ) ]

    MouseMove, %x1%, %y1% ,2

    Return
}


CapsLock & Up::
{
    MouseGetPos, x0, y0
    
    if GetKeyState("Shift")
    {
        y0 -= lyhyempi_siirtyma
    }
    Else
    {
        y0 -= siirtyma
    }
    MouseMove, %x0%, %y0%, %siirtyman_nopeus%

    Return
}


CapsLock & Down::
{
    MouseGetPos, x0, y0
    
    if GetKeyState("Shift")
    {
        y0 += lyhyempi_siirtyma
    }
    Else
    {
        y0 += siirtyma
    }
    MouseMove, %x0%, %y0%, %siirtyman_nopeus%

    Return
}


CapsLock & Left::
{
    MouseGetPos, x0, y0
    
    if GetKeyState("Shift")
    {
        x0 -= lyhyempi_siirtyma
    }
    Else
    {
        x0 -= siirtyma
    }
    MouseMove, %x0%, %y0%, %siirtyman_nopeus%

    Return
}


CapsLock & Right::
{
    MouseGetPos, x0, y0
    
    if GetKeyState("Shift")
    {
        x0 += lyhyempi_siirtyma
    }
    Else
    {
        x0 += siirtyma
    }
    MouseMove, %x0%, %y0%, %siirtyman_nopeus%

    Return
}


CapsLock & Enter::
{
    Click
    Return
}


CapsLock & BackSpace::
{
    Click, R
    Return
}