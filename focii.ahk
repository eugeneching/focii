/*

        ,---,.
      ,'  .' |                      ,--,     ,--,
    ,---.'   |   ,---.            ,--.'|   ,--.'|
    |   |   .'  '   ,'\           |  |,    |  |,
    :   :  :   /   /   |   ,---.  `--'_    `--'_
    :   |  |-,.   ; ,. :  /     \ ,' ,'|   ,' ,'|
    |   :  ;/|'   | |: : /    / ' '  | |   '  | |
    |   |   .''   | .; :.    ' /  |  | :   |  | :
    '   :  '  |   :    |'   ; :__ '  : |__ '  : |__
    |   |  |   \   \  / '   | '.'||  | '.'||  | '.'|
    |   :  \    `----'  |   :    :;  :    ;;  :    ;
    |   | ,'             \   \  / |  ,   / |  ,   /
    `----'                `----'   ---`-'   ---`-'


Focii is a window focusing (switching) tool designed to replace Alt-Tab
with a far more accurate mechanism. It allows you to pin-point, through
text, a given window that you want to focus on.


---

Eugene Ching
(codejury)

eugene@enegue.com
www.codejury.com
@eugeneching

*/


;-----------------------------------------------------------------------------
; Globals
;-----------------------------------------------------------------------------

g_group_index := 0


;-----------------------------------------------------------------------------
; Includes
;-----------------------------------------------------------------------------

#include chrome.ahk
#include trillian.ahk
#include interface.ahk
#include window.ahk
#include system.ahk
#include history.ahk
#include shortcuts.ahk


;-----------------------------------------------------------------------------
; Initialization / Globals
;-----------------------------------------------------------------------------

; Detect 32-bit or 64-bit Windows

WIN64 := ""
IfExist, C:\Program Files (x86)\*
  WIN64 := "yes"


; Environment paths

EnvGet, ENV_LOCALAPPDATA, LOCALAPPDATA
EnvGet, ENV_APPDATA, APPDATA
EnvGet, ENV_PROGRAMDATA, ALLUSERSPROFILE
EnvGet, ENV_PATH, PATH

if (WIN64) {
  ; Windows 64-bit
  BITS := " (x86)"
  ENV_PROGRAMFILES32 := "C:\Program Files (x86)"
  ENV_PROGRAMFILES64 := "C:\Program Files"
  ENV_WINDIR := "C:\windows"

} else {
  ; Windows 32-bit
  BITS := ""
  ENV_PROGRAMFILES32 := "C:\Program Files"
  ENV_WINDIR := "C:\windows"
}

; Globals
cfg_flash_window_on_activate := 1



; ----------------------------------------------------------------------------
; Focii()
;
; Searches for a suitable match against the search term entered,
; and activates the corresponding window.
; ----------------------------------------------------------------------------

Focii() {
  ; Globals
  ; global searchHistory1, searchHistory2, searchHistory3, searchHistory4, searchHistory5
  global g_group_index
  global cfg_flash_window_on_activate

  Initialize()
      
  ; Display input box
  search_term := PowerBox()

  ; Bail if there's nothing to do
  if (search_term == "" || search_term == "<<history slot unused>>")
    return

  ; Grab first char
  StringLeft, first_char, search_term, 1

  ; Off-the-record commands
  ;
  ; These are direct commands to Focii, which are not recorded
  ; as part of the search history since they don't make much sense
  ; there.
  ;

  ; About
  if (":about" == search_term || ";about" == search_term) {
    AboutBox()
    return
  }

  ; Reload Focii
  if (":reload" == search_term || ";reload" == search_term) {
    reload
    return
  }

  ; Focus on desktop
  if ("desk" == search_term || "desktop" == search_term) {
    WinActivate, Program Manager
    DisplayTrayTip("Activating desktop.")
    return
  }

  ; Toggle flash
  if (":flash" == search_term || ";flash" == search_term) {
    if (cfg_flash_window_on_activate == 0) {
      cfg_flash_window_on_activate = 1
    } else {
      cfg_flash_window_on_activate = 0
    }
    return
  }


  ; Commands
  ;
  ; Also, these are no longer "off-the-record". Hence, from
  ; this point on, history is recorded.

  AddToHistory(search_term)

  ; Open explorer to path
  if ("@" == first_char) {
    StringReplace, search_term, search_term, @
    ExplorePath(search_term)
    return
  }

  ; Launch application
  if ("!" == first_char) {
    StringReplace, search_term, search_term, !
    LaunchApplication(search_term)
    return
  }

  ; Google search
  StringLeft, first_char, search_term, 1
  if ("?" == first_char) {
    StringReplace, search_term, search_term, ?
    WebSearch(search_term)
    return
  }

  ; Window title search (explicit)
  StringLeft, first_char, search_term, 1
  if ("#" == first_char) {
    StringReplace, search_term, search_term, #
    FindWindowByTitle(search_term)
    return
  }


  ; Find window to switch to
  ;
  ; Search term is "<program-name>!<window-title>". Parse it for 
  ; the first half, which represents the program to search for.
  ;
  ; Search priority:
  ;   |_ process name
  ;       |_ window title (e.g. internal tabs)
  ;
  ;   |_ window title only
  ;

  ; ---------------------------------------------------------------
  ; Search by program name, and filter by window title
  ; ---------------------------------------------------------------  
  
  hWnd := FindWindowByProgramNameAndTitle(search_term)

  if (hWnd != -1) {
    g_group_index++
    ActivateWindowByHWnd(hWnd)
    return hWnd
  }

  ; ---------------------------------------------------------------
  ; Not found, search by window title
  ; ---------------------------------------------------------------  
  hWnd := FindWindowByTitle(search_term)

  if (hWnd != -1) {
    g_group_index++
    ActivateWindowByHWnd(hWnd)
    return hWnd
  }

  ; ---------------------------------------------------------------
  ; Can't find anything!
  ; ---------------------------------------------------------------  
  DisplayTrayTip("Could not find anything.", search_term, 2)
  return
}



