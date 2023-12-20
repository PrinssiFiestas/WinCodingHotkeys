#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
#SingleInstance force

; Fix scroll not working on Vim90 (not gVim).

SetTitleMatchMode, 2
#IfWinActive, - VIM

WheelUp::Send 3^y
WheelDown::Send 3^e

#IfWinActive