; ----------------------------------------------------------------------------
; PowerBox()
;
; Custom slim input box that can be use to capture input.
;
; Usage:
;   Result := PowerBox()
;
; Notes:
;   The GuiID should be sufficent for most uses. If however it conflicts then
;   you will need to change it in three places:
;     GuiID := (New ID number)  - found in the second line of the cInpuBox function
;     (New ID number)GuiEscape: - Found just below cInputBox function
;     (New ID number)GuiClose:  - Found just below cInputBox function
; ----------------------------------------------------------------------------

PowerBox() {
  global _cInput_Result, _cInput_Value, autocomplete_list, Box
  ; global searchHistory1, searchHistory2, searchHistory3, searchHistory4, searchHistory5

  GuiID := 8    ; If changed, also change the subroutines below for #GuiEscape & #GuiClose

  ; Figure out where the mouse is
  CoordMode, Mouse, Screen
  MouseGetPos, mouseX, mouseY

  ; Figure out which monitor it is on
  SysGet, virtualScreenWidth, 78
  SysGet, virtualScreenStartX, 76
  SysGet, nMonitors, MonitorCount

  ; Compute the dimensions and locations
  boxWidth := 400
  mouseRelativeX := mouseX - virtualScreenStartX
  monitorWidth := (virtualScreenWidth // nMonitors)
  mouseMonitor := (mouseRelativeX // monitorWidth)
  xpos := virtualScreenStartX + (mouseMonitor * monitorWidth) + (monitorWidth // 2) - (boxWidth // 2)

  ; Draw the box
  ; comboBoxList = %searchHistory1%|%searchHistory2%|%searchHistory3%|%searchHistory4%|%searchHistory5%|%autocomplete_list%
  comboBoxList = %autocomplete_list%

  Gui, %GuiID%:Margin, 0, 0
  Gui, %GuiID%:Font, Segoe UI c404040 S16
  Gui, %GuiID%:Color, c040404, FFF8DB
  Gui, %GuiID%:Add, ComboBox, % "r5 vBox w400 h30 -VScroll g_cInput_Value v_cInput_Value", % comboBoxList
  Gui, %GuiID%:+AlwaysOnTop -Border -Caption -MaximizeBox -MinimizeBox +ToolWindow
  Gui, %GuiID%:Add, Button, x232 y70 w0 h0 hidden gCInputButton, % "Cancel"
  Gui, %GuiID%:Add, Button, x122 y70 w0 h0 hidden gCInputButton Default, % "OK"
  Gui, %GuiID%:Show, xCenter yCenter autosize x%xpos%

  ; Wait for input, do autocomplete as well
  currentText := ""
  Loop {
    If( _cInput_Result ) {
      break
    }
  }

  ; Get the result
  Gui, %GuiID%:Submit, Hide

  if (_cInput_Result = "OK") {
    Result := _cInput_Value
  } else {
    Result := ""
  }

  _cInput_Value := ""
  _cInput_Result := ""

  ; Event: On destroy
  Gui %GuiID%:Destroy
  Return Result
}

_cInput_Value:
  gui, submit, nohide
  ; Check whether anything changed since we're in a busy loop,
  ; and we don't want to keep firing the autocomplete code
  ;
  currentText := ""
  if (currentText != _cInput_Value) {
    ; Don't autocomplete when we see a backspace, or when there's nothing
    search := "|"_cInput_Value
    pos := InStr(autocomplete_list, "|"_cInput_Value)
    pos_end := InStr(autocomplete_list, "|", 1, pos+1)

    if (pos and pos_end == 0)
      pos_end := StrLen(autocomplete_list) + 1 

    If (!GetKeyState("BackSpace", "P") and _cInput_Value and pos) {
      ; Get hold of the actual autocomplete match string
      found := SubStr(autocomplete_list, pos + 1, pos_end - pos - 1)

      if (found) {
        BlockInput On
        GuiControl, Text, _cInput_Value, %found%
        numAutocompleteChars := StrLen(found) - StrLen(_cInput_Value)

        ; Sends in the remainder of the string that we autocomplete to,
        ; and then highlight the characters that we autocompleted, so 
        ; the user can override them.
        SendInput % "{End}+{Left " numAutocompleteChars "}"
        BlockInput Off

        ; Sleep is needed else currentText won't update properly
        Sleep, 100
        currentText := _cInput_Value
      }
    } 
  }
  Return


8GuiEscape:
8GuiClose:
  _cInput_Result := "Close"
  Return

CInputButton:
  StringReplace _cInput_Result, A_GuiControl, &,, All
  Return



; ----------------------------------------------------------------------------
; AboutBox()
;
; Displays the about box.
; ----------------------------------------------------------------------------

AboutBox() {
  GuiID := 9
  Try {
    Gui, %GuiID%:Destroy
  }

  Gui, %GuiID%:Font, c404040 S18
  Gui, %GuiID%:Add, Text,, Focii

  Gui, %GuiID%:Font, c404040 S10, Consolas Bold
  Gui, %GuiID%:Add, Text,, Precise window switching using `nonly the keyboard.

  Gui, %GuiID%:Font, c404040 S10, Consolas Bold
  Gui, %GuiID%:Add, Text,, Eugene Ching (codejury)
  Gui, %GuiID%:Font, c404040 S10, Consolas
  Gui, %GuiID%:Add, Text,, Twitter: @codejury `n  Email: eugene@enegue.com `n    Web: www.codejury.com

  Gui, %GuiID%:Font, c404040 S10, Consolas Bold
  Gui, %GuiID%:Add, Text,, Eugene Ng
  Gui, %GuiID%:Font, c404040 S10, Consolas
  Gui, %GuiID%:Add, Text,,   Email: eugenenegue@gmail.com

  Gui, %GuiID%:Font, c404040 S10, Consolas
  Gui, %GuiID%:Add, Text,, Copyright 2012 - * `nAll rights reserved. `nDistributed under GPL license.

  Gui, %GuiID%:Show, xCenter yCenter autosize, About
}


; ----------------------------------------------------------------------------
; DisplayTrayTip()
;
; Displays a tray tip for a period of time.
; ----------------------------------------------------------------------------

DisplayTrayTip(title, text="`n", icon=1) {
  TrayTip, %title%, %text%,, %icon%
  SetTimer, ActivateTrayTipOff, 3000
}


; ----------------------------------------------------------------------------
; ActivateTrayTipOff()
;
; Remove the tray tip.
; ----------------------------------------------------------------------------

ActivateTrayTipOff:
  SetTimer, ActivateTrayTipOff, off
  TrayTip
  Return


; ----------------------------------------------------------------------------
; FlashWindow()
;
; Uses transparency to create a flashing effect on a given window
; specified by hWnd
; ----------------------------------------------------------------------------

FlashWindow(hWnd) {
  SysGet, VirtualWidth, 78
  SysGet, VirtualHeight, 79

  ; Check and store original always-on-top settings
  alwaysOnTop := False
  WinGet, ExStyle, ExStyle, ahk_id %hWnd%
  if (ExStyle & 0x8)
    alwaysOnTop := True

  ; Draw a black background to prevent the transparency from showing through
  WinSet, AlwaysOnTop, On, ahk_id %hWnd%
  WinGetPos, xpos, ypos, wlen, hlen, ahk_id %hWnd%
  Gui, -Border -Caption -AlwaysOnTop
  Gui, Color, Black
  Try {
    ; Not all windows have a visible area for us to draw behind
    Gui, Show, x%xpos% y%ypos% w%wlen% h%hlen%, NA
  }

  ; Flash the window
  Loop, 1 {
    trans := 165
    delay := 20
    Loop {
      WinSet, Transparent, %trans%, ahk_id %hWnd%
      trans := trans + 30
      if (trans >= 255)
        break
      Sleep %delay%
    }
    ;WinSet, Transparent, 255, ahk_id %hWnd%
    WinSet, Transparent, Off, ahk_id %hWnd%

    ; Restore original always-on-top settings
    if not (alwaysOnTop)
      WinSet, AlwaysOnTop, Off, ahk_id %hWnd%
  }

  ; Remove the black background
  Gui, Destroy

  ; Force a redraw
  WinSet, Redraw,, ahk_id %hWnd%
}


