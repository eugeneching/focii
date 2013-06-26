; ----------------------------------------------------------------------------
; CacheStartMenuItems()
;
; Builds an in-memory cache of all the details of applications
; that exist on the user's and the common start menu. Also
; shows a GUI.
; ----------------------------------------------------------------------------

gIsStartMenuItemsCached := False
gCacheSize := 0

CacheStartMenuItems() {
  ; Assume global
  global

  ; Get environment variables
  EnvGet, ENV_LOCALAPPDATA, LOCALAPPDATA
  EnvGet, ENV_APPDATA, APPDATA
  EnvGet, ENV_PROGRAMDATA, ALLUSERSPROFILE
  EnvGet, ENV_PATH, PATH

  ; Display the GUI
  DisplayTrayTip("Building index for applications (once only)...", "Gathering shortcuts from start menu")

  ; Build the cache
  gCacheSize := 1

  pathToSearch := ENV_APPDATA . "\Microsoft\Windows\Start Menu\Programs\*.*"
  Loop, %pathToSearch%, 0, 1
  {
    FileGetShortcut, %A_LoopFileLongPath%, targetRealPath,,, targetDesc, targetIcon
    gArrFileName%gCacheSize% = %A_LoopFileName%
    gArrShortcutPath%gCacheSize% = %A_LoopFileLongPath%
    gArrRealPath%gCacheSize% = %targetRealPath%
    gArrDesc%gCacheSize% = %targetDesc%
    gArrIcon%gCacheSize% = %targetIcon%
    gCacheSize := gCacheSize + 1
    ;AddToAutocompleteList("!"A_LoopFileName)
  }

  pathToSearch := ENV_PROGRAMDATA . "\Microsoft\Windows\Start Menu\Programs\*.*"
  Loop, %pathToSearch%, 0, 1
  {
    FileGetShortcut, %A_LoopFileLongPath%, targetRealPath,,, targetDesc, targetIcon
    gArrFileName%gCacheSize% = %A_LoopFileName%
    gArrShortcutPath%gCacheSize% = %A_LoopFileLongPath%
    gArrRealPath%gCacheSize% = %targetRealPath%
    gArrDesc%gCacheSize% = %targetDesc%
    gArrIcon%gCacheSize% = %targetIcon%
    gCacheSize := gCacheSize + 1
    ;AddToAutocompleteList("!"A_LoopFileName)
  }

  ; Remove the GUI
  Gui, Destroy
}


; ----------------------------------------------------------------------------
; LaunchApplication()
;
; Launches an application by searching the start menu for the link,
; search the path, shortcut path and program description.
; ----------------------------------------------------------------------------

LaunchApplication(programToExec) {
  global gIsStartMenuItemsCached, gCacheSize

  ; Grab necessary environment variables
  EnvGet, ENV_LOCALAPPDATA, LOCALAPPDATA
  EnvGet, ENV_APPDATA, APPDATA
  EnvGet, ENV_PROGRAMDATA, ALLUSERSPROFILE
  EnvGet, ENV_PATH, PATH

  ; Manual rebuild cache (command: !!)
  if (programToExec == "!") {
    CacheStartMenuItems()
    gIsStartMenuItemsCached := True
    Return
  }

  ; Cache start menu items (first run)
  if (!gIsStartMenuItemsCached) {
    CacheStartMenuItems()
    gIsStartMenuItemsCached := True
  }

  ; Build regex to search for program name
  regexExpr := "i)^"programToExec
  regexExpr .= "\."

  ; Search cache (by file name first)
  Loop %gCacheSize% {
    targetFileName     := gArrFileName%A_Index%
    targetShortcutPath := gArrShortcutPath%A_Index%
    targetRealPath     := gArrRealPath%A_Index%
    targetDesc         := gArrDesc%A_Index%
    targetIcon         := gArrIcon%A_Index%

    found := RegExMatch(targetFileName, regexExpr)
    if (found != "" && found != 0) {
      Try {
        Run, "%targetRealPath%"
      }
      DisplayTrayTip("Launching application.", targetRealPath)
      Return
    }
  }

  Return

  ; Search cache (fuzzy search)
  ;
  ; We disable this for now.
  ;
  Loop %gCacheSize% {
    targetFileName     := gArrFileName%A_Index%
    targetShortcutPath := gArrShortcutPath%A_Index%
    targetRealPath     := gArrRealPath%A_Index%
    targetDesc         := gArrDesc%A_Index%
    targetIcon         := gArrIcon%A_Index%

    if (InStr(targetRealPath, programToExec) || InStr(targetShortcutPath, programToExec) || InStr(targetDesc, programToExec)) {
      Try {
        Run, "%targetRealPath%"
      }
      DisplayTrayTip("Launching application (fuzzy search).", targetRealPath)
      Return
    }
  }

  DisplayTrayTip("Could not launch application", searchTerm, 2)
  Return
}


; ----------------------------------------------------------------------------
; ExplorePath()
;
; Opens explorer to the path specified.
; ----------------------------------------------------------------------------

ExplorePath(searchTerm) {
  if (FileExist(searchTerm)) {
    Try {
      ; Try dopus first
      Run, dopus.exe "%searchTerm%"
    } Catch e {
      ; Default back to explorer
      Run, explorer.exe "%searchTerm%"
    }
    DisplayTrayTip("Launching explorer.", searchTerm)
    Return

  } else {
    DisplayTrayTip("Could not launch explorer.", "No such path """ . searchTerm . """.", 2)
  }
}


; ----------------------------------------------------------------------------
; WebSearch()
;
; Performs a query using the browser, through a search engine.
; This is Google.
; ----------------------------------------------------------------------------

WebSearch(searchTerm) {
  Try {
    Run, https://www.google.com/search?q=%searchTerm%
  }
}


; ----------------------------------------------------------------------------
; GetProcesses()
;
; Gets a list of all running processes.
; ----------------------------------------------------------------------------

GetProcesses() {
  for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process")
    list .= process.name "`n"

  ; Sort and remove duplicates
  ;
  ; We also ignore word separators [-_'] so that we achieve the effect of
  ; prioritizing the shorter names (e.g. vmware.exe vs. vmware-vmx.exe).
  Sort, list, UCL
  Return list
}


