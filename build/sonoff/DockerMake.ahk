#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

WinActivate, ahk_exe bash.exe
WinWaitActive, A
Send rm app.dic 0x10000.bin && make{Enter}
binfile = C:\Users\wmb\Documents\GitHub\cforth\build\sonoff\0x10000.bin
Sleep 1000
While !FileExist(binfile)
  Sleep 250
