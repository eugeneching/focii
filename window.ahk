; ----------------------------------------------------------------------------
; SwitchAmongSearchedWindows()
;
; Searches for all windows found via the search, and switches among them.
; ----------------------------------------------------------------------------

SwitchAmongSearchedWindows() {
  ; Retrieve all the found windows from the group
  global g_group_index
  index := g_group_index - 1

  ; Go to next window of currently activated process
  groupName := "AllWindowsSearchedFor" index
  WinActivateBottom, ahk_group %groupName%

  ; Flash it
  WinGet, hWnd, ID, A
  FlashWindow(hWnd)

  return
}

; ----------------------------------------------------------------------------
; SwitchAmongSimilarWindows()
;
; Searches for all similar windows and switches among them. Similar
; windows, by definition, are windows of the same class, or originating
; from the same application.
;
; Caveat:
;   Groups cannot be destroyed (AHK limitation), so we store a unique group
;   per class. This is a slight memory leak, but a decision was made to do it
;   this way, in order to achieve both process-level and class-level window
;   switching.
;
;   Also, since we are creating groups based on class names, we want to make
;   sure that the class name is a valid group name. Hence, we remove all
;   non-alphanumeric characters.
; ----------------------------------------------------------------------------

SwitchAmongSimilarWindows() {
  ; Get details of current active window
  WinGetClass, current_class, A
  WinGet, current_pid, PID, A

  ; Add all these windows to a group
  sanitized_class_name := RegExReplace(current_class, "[^a-zA-Z]", "")
  groupName := "AllCurrentWindowsOf" sanitized_class_name
  GroupAdd %groupName%, ahk_class %current_class%
  GroupAdd %groupName%, ahk_pid %current_pid%

  ; Go to next window of currently activated process
  WinActivateBottom, ahk_group %groupName%

  ; Flash it
  WinGet, hWnd, ID, A
  FlashWindow(hWnd)

  return
}


; ----------------------------------------------------------------------------
; FindWindowByProgramNameAndTitle()
;
; Searches for all windows given a search term, first using the program name
; and then the window title (optional). Puts all found windows into a group
; for later use, and returns the first found window.
; ----------------------------------------------------------------------------

FindWindowByProgramNameAndTitle(search_term) {
  global g_group_index

  ; Split the input by delimiters (!)
  StringSplit, input, search_term, !
  if (ErrorLevel || search_term = "")
    Return

  program_name         := input1
  program_window_title := input2

  found := False
  running_process_hwnds := WinGetAll("hWnd")

  Loop, Parse, running_process_hwnds, `n,
  {
    ; Grab the hWnd
    hWnd := A_LoopField
    if (hWnd == "")
      continue

    ; Grab the process name
    WinGet, process_name, ProcessName, ahk_id %hWnd%
    if (process_name == "")
      continue

    ; Process found (ProcessName), get PID, hWnd and window title
    if (InStr(process_name, program_name, CaseSensitive=False)) {
      ; Support for special cases (found, move on)
      if (process_name == "chrome.exe" || process_name == "canary.exe")
        break

      ; Optional window title given, use it to filter
      if (program_window_title <> "") {
        WinGetTitle, window_title, ahk_id %hWnd%
        if !(InStr(window_title, program_window_title, CaseSensitive=False))
          continue
      }

      ; Add all such windows to a group
      group_name := "AllWindowsSearchedFor" g_group_index
      GroupAdd %group_name%, ahk_id %hWnd%
      if (!found) {
        found := True
        first_hwnd := hWnd
      }
    }
  }

  if (found)
    return first_hwnd

  return -1
}


; ----------------------------------------------------------------------------
; FindWindowByProgramNameAndTitle()
;
; Searches for all windows given a search term, using only the title of the
; window, and then the window title (optional). Puts all found windows into
; a group for later use, and returns the first found window.
; ----------------------------------------------------------------------------

FindWindowByTitle(search_term) {
  global g_group_index

  ; Split the input by delimiters (!)
  StringSplit, input, search_term, !
  if (ErrorLevel || search_term = "")
    Return

  program_name         := input1
  program_window_title := input2

  found := False
  window_titles := WinGetAll("Title")

  Loop, Parse, window_titles, `n,
  {
    ; Grab the window title
    window_title := A_LoopField

    If (InStr(window_title, search_term, CaseSensitive=False)) {
      SetTitleMatchMode, 3
      WinGet, hWnd, ID, %window_title%

      ; Add all such windows to a group
      group_name := "AllWindowsSearchedFor" g_group_index
      GroupAdd %group_name%, ahk_id %hWnd%
      if (!found) {
        found := True
        first_hwnd := hWnd
      }
    }
  }

  if (found)
    return first_hwnd

  return -1
}


; ----------------------------------------------------------------------------
; ActivateWindowByHWnd()
;
; Activates the specified window by hWnd, and displays the tray tip.
; ----------------------------------------------------------------------------

ActivateWindowByHWnd(hWnd) {
  ; Get details from hWnd
  WinGet, process_name, ProcessName, ahk_id %hWnd%  ; Process name
  WinGet, pid, PID, ahk_id %hWnd%                   ; PID
  WinGetTitle, window_title, ahk_id %hWnd%          ; Window title

  DisplayTrayTip("Activating """ . process_name . """ (" . pid . ").", window_title)
  WinActivate, ahk_id %hWnd%

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



