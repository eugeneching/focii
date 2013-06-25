; ----------------------------------------------------------------------------
; HandleTrillian()
;
; Special handling for Trillian's multiple chat windows.
; ----------------------------------------------------------------------------

HandleTrillian(hWnd, PID, processName, windowTitle) {
  ; Specified a particular window
  if windowTitle <>
  {
    ; Only activate a valid window and display TrayTip if successful
    SetTitleMatchMode, RegEx
    WinActivate, i)%windowTitle%, Trillian Window
    IfWinActive, i)%windowTitle%, Trillian Window
    {
      SetTitleMatchMode, 3
      WinGetTitle, windowTitle, A       ; Window title
      WinGet, hWnd, ID, %windowTitle%
      FlashWindow(hWnd)
      DisplayTrayTip("Activating """ . processName . """ (" . PID . ").", windowTitle)
    }
  
  ; No particular window specified
  } else {
    ; Activate Trillian
    ActivateWindowByHWnd(hWnd, PID, processName, windowTitle)
  }

}


