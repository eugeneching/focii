; ----------------------------------------------------------------------------
; HandleTrillian()
;
; Special handling for Trillian's multiple chat windows.
; ----------------------------------------------------------------------------

HandleTrillian(hWnd) {
  ; Get details from hWnd
  WinGet, process_name, ProcessName, ahk_id %hWnd%  ; Process name
  WinGet, pid, PID, ahk_id %hWnd%                   ; PID
  WinGetTitle, window_title, ahk_id %hWnd%          ; Window title

  ; Specified a particular window
  if window_title <>
  {
    ; Only activate a valid window and display TrayTip if successful
    SetTitleMatchMode, RegEx
    WinActivate, i)%window_title%, Trillian Window
    IfWinActive, i)%window_title%, Trillian Window
    {
      SetTitleMatchMode, 3
      WinGetTitle, window_title, A       ; Window title
      WinGet, hWnd, ID, %window_title%
      FlashWindow(hWnd)
      DisplayTrayTip("Activating """ . process_name . """ (" . pid . ").", window_title)
    }

  ; No particular window specified
  } else {
    ; Activate Trillian
    ActivateWindowByHWnd(hWnd)
  }
}


