/*
 _ __      _       _      
| / / ___ | | _ _ <_>._ _ 
|  \ / ._>| || | || || ' |
|_\_\\___.|_||__/ |_||_|_|

Repository : github.com/def-vex/Kelvin
Maintainer : def-vex
Release    : beta-release

*/

#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "config.ahk"
#Include "engine.ahk"

;@Ahk2Exe-SetProductName Doing something
;@Ahk2Exe-SetDescription Kelvin
;@Ahk2Exe-SetVersion beta-release

A_IconTip := "Kelvin (beta-release)"

; Make sure Kelvin is running with admin privileges
; This is to ensure that MSI Afterburner does not throw a user prompt when Kelvin tries to start it up
if !(A_IsAdmin) {
	try {
		Run '*RunAs "' . A_ScriptFullPath . '"'
	}
	ExitApp() ; Restart to ensure admin privileges
}

; Read registry to find out the install path of MSI Afterburner and the fallback here is just the default location it tends to install to
try {
	filePathForAfterburnerToRun := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\MSI\Afterburner", "InstallPath")
} catch {
	filePathForAfterburnerToRun := "C:\Program Files (x86)\MSI Afterburner\MSIAfterburner.exe"
}

; Read registry to find out the install path of RivaTuner Statistics Server and the fallback here is just the default location it tends to install to
try {
	filePathForRTSSToRun := RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Unwinder\RTSS", "InstallPath")
} catch {
	filePathForRTSSToRun := "C:\Program Files (x86)\RivaTuner Statistics Server\RTSS.exe"
}

if !(FileExist(filePathForAfterburnerToRun)) {
	MsgBox("MSI Afterburner was not found on this system.", "Kelvin - File Error", 0x10)
	ExitApp()
}

if !(FileExist(filePathForRTSSToRun)) {
	MsgBox("RivaTuner Statistics Server was not found on this system.", "Kelvin - File Error", 0x10)
	ExitApp()
}

; Make sure that Kelvin can see MSI Afterburner and RTSS even if they are in the system tray
DetectHiddenWindows true

; Initializing settings
; In case the settings file is not found, Kelvin falls back to default values
iniPath := A_ScriptDir . "\settings.ini"

if !FileExist(iniPath) {
	CreateDefaultIni(iniPath)
}

; Synchronize discovered executable paths into the INI file
SyncIniPath(iniPath, "Afterburner", filePathForAfterburnerToRun)
SyncIniPath(iniPath, "RTSS", filePathForRTSSToRun)

killAfterburnerOnStart := GetInt("KillAfterburnerOnStart", 1, 0)
checkInterval := GetInt("CheckInterval", 5000, 1000)
waitForRTSSToOpen := GetInt("WaitForRTSSToOpen", 10, 1)
forceLaunchRTSS := GetInt("ForceLaunchRTSS", 1, 0)
maxCloseAttempts := GetInt("MaxCloseAttempts", 6, 1)
closeIfRiotClient := GetInt("CloseIfRiotClient", 1, 0)

if (killAfterburnerOnStart) && ProcessExist("MSIAfterburner.exe") {
	TrayTip("Killing MSI Afterburner on startup...", "Kelvin")
	try WinClose("MSI Afterburner ahk_exe MSIAfterburner.exe")
}

targets := []
targetList := IniRead(iniPath, "Targets", , "")

; Populate target applications list from the INI file that was read
Loop Parse, targetList, "`n", "`r" {
	; No leading or trailing space characters in the line
	line := Trim(A_LoopField)

	; Check if empty line between targets and continue to next line if empty
	; Also ignore comments
	if (line == "") || (SubStr(line, 1, 1) == ";") {
		continue
	}

	parts := StrSplit(line, "=", , 2) ; Check if there is an '=' sign

	if (parts.Length != 2) || (Trim(parts[1]) == "") || (Trim(parts[2]) == "") {
		MsgBox("Formatting error in settings.ini:`nInvalid entry:`n`"" . line . "`"", "Kelvin - Config Error", 0x30)
		ExitApp()
	}

	targets.Push(Trim(parts[2]))
}

; Check if there were no targets in which case Kelvin does not care and will exit
if (targets.Length == 0) {
	MsgBox("Error in settings.ini:`nNo target processes found under [Targets].", "Kelvin - Config Error", 0x30)
	ExitApp()
}

rules := [
    Rule("Games -> Afterburner", targets, [
        Action(filePathForAfterburnerToRun, "window", maxCloseAttempts),
        Action(filePathForRTSSToRun, "kill")
    ])
]

Tick()
SetTimer(Tick, checkInterval)

CreateDefaultIni(path) {
	FileAppend("
	( LTrim
	[Settings]
	; Kill MSI Afterburner on startup (or just manually remove it from your Startup applications)
	KillAfterburnerOnStart=1
	; Milliseconds between checks (default 5000)
	CheckInterval=5000
	; Seconds to wait for RTSS to start with Afterburner
	WaitForRTSSToOpen=10
	; 1 = start RTSS if Afterburner didn't, 0 do not start RTSS forcefully
	ForceLaunchRTSS=1
	; Close requests Kelvin sends before giving up on MSI Afterburner
	MaxCloseAttempts=6
	; Close if Riot Client is detected
	CloseIfRiotClient=1

	[Paths]
	; Leave blank so Kelvin does the work for you
	Afterburner=
	RTSS=

	[Targets]
	; One exe file per line
	; To check your game's specific exe name, open Task Manager and go to details to search for your game
	1=notepad.exe
	)", path, "UTF-16")
}

SyncIniPath(path, key, detectedPath) {
	currentVal := IniRead(path, "Paths", key, "")
	if (currentVal != detectedPath) {
		IniWrite(detectedPath, path, "Paths", key)
	}
}

GetInt(key, default, min) {
	try {
		value := Integer(IniRead(iniPath, "Settings", key, default))
	} catch {
		value := default
	}
	
	return Max(value, min)
}