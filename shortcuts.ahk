;-----------------------------------------------------------------------------
; Focii Shortcuts
;-----------------------------------------------------------------------------

^F2::
  reload
  return

; Ctrl-;
^;::
  Focii()
  return

; Alt-;
!;::
  ; Switch among the windows found by a search term
  SwitchAmongSearchedWindows()
  return

; Win-;
#;::
  ; Switch among windows of the same application
  SwitchAmongSimilarWindows()
  return

; Ctrl-Alt-;
^!;::
  ; Flash the current window
  WinGet, currentHWnd, ID, A
  FlashWindow(currentHWnd)
  return

