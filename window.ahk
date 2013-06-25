; ----------------------------------------------------------------------------
; SwitchAmongRelatedWindows()
;
; Searches for all related windows and switches among them. Related
; windows, by definition, are windows of the same class, or originating
; from the same application.
; ----------------------------------------------------------------------------

SwitchAmongRelatedWindows() {
  ; Groups cannot be destroyed (AHK limitation), so we store a unique group
  ; per class. This is a slight memory leak, but a decision was made to do it
  ; this way, in order to achieve both process-level and class-level window
  ; switching.

  ; Also, since we are creating groups based on class names, we want to make 
  ; sure that the class name is a valid group name. Hence, we remove all
  ; non-alphanumeric characters.

  ; Get details of current active window
  WinGetClass, currentClass, A
  WinGet, currentPID, PID, A

  
  ; Add all these windows to a group
  sanitizedClassName := RegExReplace(currentClass, "[^a-zA-Z]", "")
  groupName := "AllCurrentWindowsOf" sanitizedClassName
  GroupAdd %groupName%, ahk_class %currentClass%
  GroupAdd %groupName%, ahk_pid %currentPID%

  ; Go to next window of currently activated process
  ; WinActivateBottom, ahk_class %currentClass%
  WinActivateBottom, ahk_group %groupName%

  ; Flash it
  WinGet, currentHWnd, ID, A
  FlashWindow(currentHWnd)

  return
}


; ----------------------------------------------------------------------------
; ActivateWindowByTitle()
;
; Search for a specific window, using only the title of the
; window.
; ----------------------------------------------------------------------------

ActivateWindowByTitle(searchTerm) {
  ; Get window titles and search
  found := False
  windowTitles := WinGetAll("Title")
  Loop, Parse, windowTitles, `n,
  {
    ; Found (window title), get PID, ProcessName and hWnd
    If (InStr(A_LoopField, SearchTerm, CaseSensitive=false)) {
      found := True
      SetTitleMatchMode, 3
      windowTitle := A_LoopField                        ; Window title
      WinGet, PID, PID, %windowTitle%                   ; PID
      WinGet, processName, ProcessName, %windowTitle%   ; Process name
      WinGet, hWnd, ID, %windowTitle%                   ; hWnd

      ; Activate window
      ActivateWindowByHWnd(hWnd, PID, processName, windowTitle)
      break
    }
  }

  ; Window title not found
  if (!found) {
    ; Give up
    DisplayTrayTip("Could not find window title.", searchTerm, 2)
  }
}


; ----------------------------------------------------------------------------
; ActivateWindowByHWnd()
;
; Activates the specified window by hWnd, and displays the
; tray tip.
; ----------------------------------------------------------------------------

ActivateWindowByHWnd(hWnd, PID, processName, windowTitle) {
  global currHWnd, currPID, currProcessName, currWindowTitle

  DisplayTrayTip("Activating """ . processName . """ (" . PID . ").", windowTitle)
  WinActivate, ahk_id %hWnd%

  currHWnd        = %hWnd%
  currPID         = %PID%
  currProcessName = %processName%
  currWindowTitle = %windowTitle%

  FlashWindow(hWnd)
}


; ----------------------------------------------------------------------------
; ActivateWindowByPID()
;
; Activates the specified window by hWnd, and displays the
; tray tip.
; ----------------------------------------------------------------------------

ActivateWindowByPID(PID, processName, windowTitle) {
  global currHWnd, currPID, currProcessName, currWindowTitle

  DisplayTrayTip("Activating """ . processName . """ (" . PID . ").", windowTitle)
  WinActivate, ahk_pid %PID%
  WinGet, hWnd, ID, ahk_pid %PID%

  currHWnd        = %hWnd%
  currPID         = %PID%
  currProcessName = %processName%
  currWindowTitle = %windowTitle%

  FlashWindow(hWnd)
}


; ----------------------------------------------------------------------------
; SwitchToAltTabWindow()
;
; Sends the alt-tab key combination, and flash the new window.
; ----------------------------------------------------------------------------

SwitchToAltTabWindow() {
  Send {Alt Down}{Tab Down}{Tab Up}{Alt Up}
  WinGet, hWnd, ID, A
  FlashWindow(hWnd)
}


; ----------------------------------------------------------------------------
; WinGetAll()
;
; Gets all the information about all windows that exist
; (PID, ProcessName, Title, etc).
; ----------------------------------------------------------------------------

WinGetAll(Which="Title", DetectHidden="Off") {
  O_DHW := A_DetectHiddenWindows, O_BL := A_BatchLines ; Save original states
  DetectHiddenWindows, % (DetectHidden != "off" && DetectHidden) ? "on" : "off"
  SetBatchLines, -1

  ; Get all hwnd
  WinGet, all, list

  ; Return Window Titles
  if (Which="Title") {
    Loop, %all% {
      WinGetTitle, WTitle, % "ahk_id " all%A_Index%
      If WTitle ; Prevent to get blank titles
        Output .= WTitle "`n"
    }
  }

  ; Return process names
  else if (Which="Process") {
    Loop, %all% {
      WinGet, PName, ProcessName, % "ahk_id " all%A_Index%
      Output .= PName "`n"
    }
  }

  ; Return window classes
  else if (Which="Class") {
    Loop, %all% {
      WinGetClass, WClass, % "ahk_id " all%A_Index%
      Output .= WClass "`n"
    }
  }

  ; Return window handles (unique ID)
  else if (Which="hWnd") {
    Loop, %all%
      Output .= all%A_Index% "`n"
  }

  ; Return process identifiers (PIDs)
  else if (Which="PID") {
    Loop, %all% {
      WinGet, PID, PID, % "ahk_id " all%A_Index%
      Output .= PID "`n"
    }
    Sort, Output, U N ; Numeric order and remove duplicates
  }

  DetectHiddenWindows, %O_DHW%  ; Back to original state
  SetBatchLines, %O_BL%         ; Back to original state
  Sort, Output, UCL             ; Sort and remove duplicates
  Return Output
}



