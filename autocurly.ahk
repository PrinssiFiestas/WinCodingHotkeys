#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance, force

; Auto closes {} but only when { gets followed by Enter. 
; You should probably disable auto closing braces on your editor if you use this script. 

#Hotstring EndChars `n

::{::
Send {{}{}}{Left}{Enter}
return
