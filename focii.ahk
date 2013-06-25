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

Hence, Focii has different modes of operations:

  * Command mode
  * Switch mode
      - Switch-by-process mode
      - Switch-by-title mode
      - Hybrid mode

Focii has a very simple UI, which is a text box. It is triggered by the
default key combination of:

     Ctrl-;

upon which a box will be displayed in the middle of the active screen.
Focii then expects a command, which Focii will interpret in one of two
major modes (command mode, switch mode). These are described next.


## Command Mode

Command mode is simple, and all commands come with a prefix as the first
char (e.g. '!', '?'). Prefixes setse Focii into command mode, and the
prefix itself determines the command, and everything after the prefix is
interpreted as arguments to the command.

The following lists Focii's commands:

    * !program    : Launches an application
    * @directory  : Opens explorer to that directory
    * #window     : Matches window titles and switches to that window
    * ?searchterm : Searches the internet for search term
    * :about      : Displays "about" information
    * :reload     : Reloads Focii (only for non-compiled versions)
    * ;           : Switch to previous window (alt-tab)

Note that ':' commands also permit the use of ';' as an alternative.


## Switch Mode

Everything else puts Focii into switch mode, where the objective is to
specify a precise window to switch to, and switch to it.

A switch command takes two forms (using the example of notepad):

  1. notepad
  2. notepad!mytextfile

In the case above, "notepad" is the primary search term, and "mytextfile"
is the secondary search term.

As detailed above, switch mode has three sub-modes. The three modes are
linked, and falls through to each other in order to keep the interface
as intuitive as possible.

### Switch-by-process mode
When a search term is directly entered into
Focii, this is the default mode. In this mode, all the running processes
enumerated, and the best match (against the shortest name) is used. If
a match is found and there is no secondary search term, Focii switches
to the topmost window of that process. If there is a secondary search
term, Focii enters Hybrid mode.

### Switch-by-title mode
If a process cannot be found using the primary
search term at all, Focii abandons switch-by-process mode and enters
switch-by-title mode. In this mode, the primary search term is taken
to match against all the window titles of all existing windows. If
a match is found and there is no secondary search term, Focii switches
to that window that it found. If there is a secondary search term,
Focii enteres Hybrid mode. If a match is not found, Focii gives up.

### Hybrid mode
Hybrid mode deals with secondary search terms. It also
assumes that a suitable process/window has been found, but you have
specified something more specific (in the secondary search term).
In this scenario, Focii will use the secondary search term to match
against the window titles of all the windows that belongs to that
process, matching it as best as it can. Hence, in the example above,
"notepad!mytextfile" will try to switch to the notepad window (if
there are multiple) that has "mytextfile" in its window title. If
it cannot match, it will open whichever notepad window it can find.


## Special Applications

Focii also has support for specific programs that have the idea of
tabs. Examples of this would be browsers, and IM clients. Since each
program is different, there is no generic way for Focii to be able
to switch to, for instance, a given tab in a browser. Hence,
specific support is implemented for certain programs.


## Visual Indicators

Focii will flash the window that it activates, as a visual indicator
of which window it selects.


## Primary/Secondary Search Term Separators

Focii accepts both the '!' character (as above) and the <space>
character as search term separators. Hence, "notepad mytextfile" works
in the same way as the example above. Note that separators are _not_
respected or cared for in command mode.


---  

Eugene Ching  
(codejury)  

eugene@enegue.com  
www.codejury.com  
@eugeneching  

*/


;-----------------------------------------------------------------------------
; Includes
;-----------------------------------------------------------------------------

#include chrome.ahk
#include trillian.ahk
#include interface.ahk
#include window.ahk
#include system.ahk


;-----------------------------------------------------------------------------
; Focii Shortcuts
;-----------------------------------------------------------------------------

gGroupIndex := 1

^;::
  Activate()
  Return

!;::
  SwitchAmongRelatedWindows()
  Return

^!;::
  ; Flash it
  WinGet, currentHWnd, ID, A
  FlashWindow(currentHWnd)
  Return

+!;::
  SwitchToAltTabWindow()
  Return



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


; ----------------------------------------------------------------------------
; AddToHistory()
;
; Adds a search term to the history.
; ----------------------------------------------------------------------------

AddToHistory(item) {
  ; Assume global
  global

  historySize := 5

  ; Make room for new entry
  loopCount := historySize - 1
  Loop, %loopCount% {
    firstIndex := historySize - A_Index + 1
    nextIndex  := firstIndex - 1
    if searchHistory%firstIndex% = 
      searchHistory%firstIndex% = <<history slot unused>>
    if searchHistory%nextIndex% = 
      searchHistory%nextIndex% = <<history slot unused>>
    searchHistory%firstIndex% := searchHistory%nextIndex%
  }
  searchHistory1 := item
}


; ----------------------------------------------------------------------------
; Activate()
;
; Searches for a suitable match against the search term entered,
; and activates the corresponding window.
; ----------------------------------------------------------------------------

Activate() {
  ; Globals
  global searchHistory1, searchHistory2, searchHistory3, searchHistory4, searchHistory5
  global currHWnd, currPID, currProcessName, currWindowTitle

  ; Display input box
  searchTerm := PowerBox()

  ; Bail if there's nothing to do
  if (searchTerm == "" || searchTerm == "<<history slot unused>>")
    Return
 
  ; Grab first char
  StringLeft, firstChar, searchTerm, 1


  ; Off-the-record commands
  ;
  ; These are direct commands to Focii, which are not recorded
  ; as part of the search history since they don't make much sense
  ; there.
  ;

  ; About
  if (":about" == searchTerm || ";about" == searchTerm) {
    AboutBox()
    Return
  }

  ; Reload Focii
  if (":reload" == searchTerm || ";reload" == searchTerm) {
    Reload
    Return
  }

  ; Focus on desktop
  if ("desk" == searchTerm || "desktop" == searchTerm) {
    WinActivate, Program Manager
    DisplayTrayTip("Activating desktop.")
    Return
  }

  
  ; Commands
  ;
  ; Also, these are no longer "off-the-record". Hence, from 
  ; this point on, history is recorded.

  AddToHistory(searchTerm)


  ; Open explorer to path
  ;
  if ("@" == firstChar) {
    StringReplace, searchTerm, searchTerm, @
    ExplorePath(searchTerm)
    Return
  }

  ; Launch application
  ;
  if ("!" == firstChar) {
    StringReplace, searchTerm, searchTerm, !
    LaunchApplication(searchTerm)
    Return
  }

  ; Google search
  ;
  StringLeft, firstChar, searchTerm, 1
  if ("?" == firstChar) {
    StringReplace, searchTerm, searchTerm, ?
    WebSearch(searchTerm)
    Return
  }

  ; Window title search (explicit)
  ;
  StringLeft, firstChar, searchTerm, 1
  if ("#" == firstChar) {
    StringReplace, searchTerm, searchTerm, #
    ActivateWindowByTitle(searchTerm)
    Return
  }


  ; Predictive behaviour
  ; (switch windows by interpreting input)
  ;

  ; Split the input by delimiters
  StringSplit, input, searchTerm, !%A_Space%%A_Tab%
  if (ErrorLevel || searchTerm = "")
    Return

  ; Find window to switch to
  ;
  ; Search term is "programName!programWindowtitle". Parse it for the first
  ; half, which represents the program to search for.
  ;   Hence input1 refers to program
  ;   while input2 refers to (secondary) window title
  ;

  programName := input1
  programWindowTitle := input2

  if programName <>
  {
    ; When switching, we are switching to a particular window,
    ; associated to a given process, and not just to a given
    ; process. Hence, we ultimately activate a *window*.
    ;

    ; Search priority:
    ;   |_ process name
    ;       |_ search term (e.g. internal tabs)
    ;
    ;   |_ window title
    ;

    found := False

    ; Get all running processes (by PID) and search
    ;RunningProcessPIDs := WinGetAll("PID")
    RunningProcessHWnds := WinGetAll("hWnd")
    ;Loop, Parse, RunningProcessPIDs, `n,
    Loop, Parse, RunningProcessHWnds, `n,
    {
      ; Grab the PID
      hWnd := A_LoopField
      if (hWnd == "")   ; hWnd
        continue

      ; Grab the process name
      WinGet, processName, ProcessName, ahk_id %hWnd%   ; Process name
      if (processName == "")
        continue

      ; Process found (ProcessName), get PID, hWnd and window title
      if (InStr(processName, programName, CaseSensitive=False)) {
        ; Grab the rest of the details
        Process, Exist, %processName%
        WinGet, PID, PID, ahk_id %hWnd%                 ; PID
        WinGetTitle, windowTitle, ahk_id %hWnd%         ; Window title

        ; Support for special cases
        ; (don't do the generic window title match)
        if (processName == "chrome.exe" || processName == "canary.exe")
          break

        ; User specified a particular window title of this process to grab,
        ; so we filter out the wrong windows of the right process.
        if (programWindowTitle <> "") {
          if (InStr(windowTitle, programWindowTitle, CaseSensitive=False)) {
            found := True
            break
          } else {
            continue
          }

        ; Just a simple search, no particular window title,
        ; so we've already found what we're looking for.
        } else {
          found := True
          break
        }
      }
    }

    ; Process found
    ; 
    ; We are ready to switch to the process. If there are special
    ; cases that we are interested in, handle them as well.
    ;
    if (found) {
      ; Special case: Chrome
      if (processName == "chrome.exe" || processName == "canary.exe") {
        HandleChrome(hWnd, PID, processName, windowTitle)
      }

      ; Default: Others
      else {
        ActivateWindowByHWnd(hWnd, PID, processName, windowTitle)
      }
    }

    ; Process not found
    ;
    ; We couldn't directly match a process. We now try to directly
    ; match window titles instead.
    ;
    if (!found) {
      ; Get window titles and search
      windowTitles := WinGetAll("Title")
      Loop, Parse, windowTitles, `n,
      {
        ; Found (window title), get PID, ProcessName and hWnd
        If (InStr(A_LoopField, SearchTerm, CaseSensitive=False)) {
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

      ; Nothing was found
      ;
      ; We couldn't get any match at all. Give up.
      ;
      if (!found) {
        DisplayTrayTip("Could not find anything.", searchTerm, 2)
      }
    }

    Return
  }

  ; We don't know what to do, just search for it! :)
  ; However, this should never happen.
  else {
    ; Search
    Run, https://www.google.com/search?q=%windowTitle%
  }

  Return
}


