#NoEnv
#Warn
#Persistent
#SingleInstance Force

SetNumLockState AlwaysOn

; Sets Caps Lock off by either pressing Caps Lock or Shift
~Shift UP::
{
	if ! getKeyState("CapsLock")
		SetCapsLockState Off
	return
}