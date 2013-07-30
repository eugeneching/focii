; ----------------------------------------------------------------------------
; HandleChrome()
;
; Special handling for Chrome's tabs.
; ----------------------------------------------------------------------------

HandleChrome(hWnd) {
  ; Activate Chrome 
  ActivateWindowByHWnd(hWnd)

  ; Wait for Chrome to be the active window
  SetTitleMatchMode 2
  IfWinNotActive, ahk_class Chrome_WidgetWin_1,, WinActivate, ahk_class Chrome_WidgetWin_1,
  WinWaitActive, ahk_class Chrome_WidgetWin_1

  ; Get unique window handle
  ControlGet, firstTabHWnd, Hwnd

  ; Secondary search term not empty
  if windowTitle <>
  {
    ; Loop through tabs in Chrome
    Loop {
      WinGetActiveTitle, Title
      if (InStr(Title, windowTitle, CaseSensitive=False))
        break
      Send {Ctrl Down}{Tab Down}{Tab Up}{Ctrl Up}
      ControlGet, currentTabHWnd, Hwnd
      if (currentTabHWnd == firstTabHWnd)
        break
    }
  }
}


