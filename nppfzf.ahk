#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
#SingleInstance Force
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.


; Open a file in Notepad++ using fzf but only if cmd already exists which indicates that I'm working on a project rather than any other document.


#If WinActive("ahk_class Notepad++") and WinExist("ahk_class ConsoleWindowClass")
^o::
WinActivate ahk_class ConsoleWindowClass
SendInput notepad{VKBB}{VKBB} {RAlt DOWN}4{RAlt Up}{Shift DOWN}8{Shift UP}fzf{Shift DOWN}9{Shift UP}{Enter}

#If