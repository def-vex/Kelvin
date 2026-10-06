#Requires AutoHotkey v2.0

class Action {

    ; path is the full path to the exe to run
    ; closeMethod uses two ways - either window which is a nice WinClose or kill which is a ProcessClose
    __New(path, closeMethod := "window", maxCloseAttempts := 6, windowTitle := "") {
        SplitPath(path, &exeName)
        this.path := path
        this.exeName := exeName
        this.closeMethod := closeMethod
        this.maxCloseAttempts := maxCloseAttempts
        this.startedByUs := false
        this.closing := false
        this.closeAttempts := 0
        this.windowTitle := windowTitle ; I shall implement this some day
    }

    Start() {
        ; Initializing
        this.closing := false
        this.closeAttempts := 0

        if ProcessExist(this.exeName)
            return ; already running and so we don't close it

        if !FileExist(this.path) {
            TrayTip("Not found: " this.path, "Kelvin")
            return
        }

        TrayTip("Opening " this.exeName "...", "Kelvin")
        Run(this.path)
        this.startedByUs := true
    }

    Stop() {
        if this.startedByUs
            this.closing := true ; leave the cleaning to Update()
    }

    CloseWindows() {
        target := (this.windowTitle != "" ? this.windowTitle " " : "") "ahk_exe " this.exeName
        for hwnd in WinGetList(target) {
            ; if (WinGetTitle(hwnd) = "")
                ; continue ; I shall implement this some day
            try WinClose(hwnd)
        }
    }

    Update() {
        if !this.closing
            return

        if !ProcessExist(this.exeName) {
            this.closing := false
            this.startedByUs := false
            return
        }

        if (this.closeMethod = "kill") {
            ProcessClose(this.exeName)
        } else if (this.closeAttempts < this.maxCloseAttempts) {
            this.closeAttempts++
            TrayTip("Closing " this.exeName "...", "Kelvin")
            this.CloseWindows()
        }
    }
}

class Rule {
    ; triggers are array of exe names
    ; actions are array of action objects
    __New(name, triggers, actions) {
        this.name := name
        this.triggers := triggers
        this.actions := actions
        this.active := false
    }

    AnyTriggerRunning() {
        for exe in this.triggers
            if ProcessExist(exe)
                return true
        return false
    }

    Tick() {
        running := this.AnyTriggerRunning()

        if running && !this.active {
            this.active := true
            for a in this.actions
                a.Start()
        } else if !running && this.active {
            this.active := false
            for a in this.actions
                a.Stop()
        }

        for a in this.actions
            a.Update()
    }
}

Tick() {
    global rules, closeIfRiotClient

    if closeIfRiotClient && ProcessExist("Riot Client.exe")
        ExitApp()

    for r in rules
        r.Tick()
}