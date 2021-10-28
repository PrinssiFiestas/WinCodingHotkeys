#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
; SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

SetKeyDelay 100
#SingleInstance, Force

CoordMode, Mouse, Screen



X := []
Y := []
sarakkeiden_maara := 12
marginaalit := A_ScreenWidth/10
yla_ala_vali := A_ScreenHeight/20

siirtyma := A_ScreenWidth/20
lyhyempi_siirtyma := A_ScreenWidth/95
siirtyman_nopeus := 1

i := 0
Loop %sarakkeiden_maara%
{
    X[i+1] := i * (A_ScreenWidth - marginaalit) / (sarakkeiden_maara-1) + marginaalit/2
    i++
}
i := 0
Loop 4
{
    Y[i+1] := i * (A_ScreenHeight - yla_ala_vali) / 3 + yla_ala_vali/2
    i++
}

HotkeyList := "1 2 3 4 5 6 7 8 9 0 + ´ q w e r t y u i o p å ¨ a s d f g h j k l ö ä ' < z x c v b n m , . - RShift"

Loop, Parse, HotkeyList, " "
{
    Hotkey, CapsLock & %A_LoopField%, KoordinaattiLoikkari
}

Return

penis:=0
KoordinaattiLoikkari:
{
    nappain := SubStr(A_ThisHotkey, 12)
    nappain_num := Floor((InStr(HotkeyList, nappain)+1)/2)
    x1 := X[ Mod(nappain_num, sarakkeiden_maara) + (Mod(nappain_num,sarakkeiden_maara)==0)*sarakkeiden_maara ]
    y1 := Y[Floor( (nappain_num - Mod(nappain_num, sarakkeiden_maara))/sarakkeiden_maara + 1 - (Mod(nappain_num, sarakkeiden_maara)==0) )]

    MouseMove, %x1%, %y1% ,2

    Return
}


CapsLock & Up::
{
    MouseGetPos, x0, y0
    
    if GetKeyState("LShift")
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
    
    if GetKeyState("LShift")
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
    
    if GetKeyState("LShift")
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
    
    if GetKeyState("LShift")
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