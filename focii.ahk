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
  else if (Which="hwnd") {
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
  global _cInput_Result, _cInput_Value, Box
  global searchHistory1, searchHistory2, searchHistory3, searchHistory4, searchHistory5

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
  Gui, %GuiID%:Margin, 0, 0
  Gui, %GuiID%:Font, Segoe UI c404040 S16
  Gui, %GuiID%:Color, c040404, FFF8DB
  Gui, %GuiID%:Add, ComboBox, % "r5 vBox w400 h30 -VScroll v_cInput_Value", |%searchHistory1%||%searchHistory2%|%searchHistory3%|%searchHistory4%|%searchHistory5%
  Gui, %GuiID%:+AlwaysOnTop -Border -Caption -MaximizeBox -MinimizeBox +ToolWindow
  Gui, %GuiID%:Add, Button, x232 y70 w0 h0 hidden gCInputButton, % "Cancel"
  Gui, %GuiID%:Add, Button, x122 y70 w0 h0 hidden gCInputButton Default, % "OK"
  Gui, %GuiID%:Show, xCenter yCenter autosize x%xpos%

  ; Wait for input
  Loop
    If( _cInput_Result )
      break

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

8GuiEscape:
8GuiClose:
  _cInput_Result := "Close"
Return

CInputButton:
  StringReplace _cInput_Result, A_GuiControl, &,, All
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
    gArrShortcutPath%gCacheSize% = %A_LoopFileLongPath%
    gArrRealPath%gCacheSize% = %targetRealPath%
    gArrDesc%gCacheSize% = %targetDesc%
    gArrIcon%gCacheSize% = %targetIcon%
    gCacheSize := gCacheSize + 1
  }

  pathToSearch := ENV_PROGRAMDATA . "\Microsoft\Windows\Start Menu\Programs\*.*"
  Loop, %pathToSearch%, 0, 1
  {
    FileGetShortcut, %A_LoopFileLongPath%, targetRealPath,,, targetDesc, targetIcon
    gArrShortcutPath%gCacheSize% = %A_LoopFileLongPath%
    gArrRealPath%gCacheSize% = %targetRealPath%
    gArrDesc%gCacheSize% = %targetDesc%
    gArrIcon%gCacheSize% = %targetIcon%
    gCacheSize := gCacheSize + 1
  }

  ; Remove the GUI
  Gui, Destroy
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
  ;
  ; Handle user input
  ;

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


  ;
  ; Off-the-record commands
  ;

  ; Alt-Tab emulation
  if (";" == searchTerm) {
    Send {Alt Down}{Tab Down}{Tab Up}{Alt Up}
    WinGet, hWnd, ID, A
    FlashWindow(hWnd)
    Return
  }

  ; About
  if (":about" == searchTerm || ";about" == searchTerm) {
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
    Return
  }

  ; Reload Focii
  if (":reload" == searchTerm || ";reload" == searchTerm) {
    Reload
    Return
  }

  
  
  ;
  ; From this point on, history is recorded
  ;

  ; Add to history
  AddToHistory(searchTerm)


  ;
  ; Commands
  ;

  ; Focus on desktop
  if ("desk" == searchTerm || "desktop" == searchTerm) {
    WinActivate, Program Manager
    DisplayTrayTip("Activating desktop.")
    Return
  }

  ; Open explorer to path
  if ("@" == firstChar) {
    StringReplace, searchTerm, searchTerm, @

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
    Return
  }

  ; Launch application
  if ("!" == firstChar) {
    global gIsStartMenuItemsCached, gCacheSize

    ; Grab necessary environment variables
    EnvGet, ENV_LOCALAPPDATA, LOCALAPPDATA
    EnvGet, ENV_APPDATA, APPDATA
    EnvGet, ENV_PROGRAMDATA, ALLUSERSPROFILE
    EnvGet, ENV_PATH, PATH

    ; Try to launch the program
    StringReplace, searchTerm, searchTerm, !
    programToExec := searchTerm

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

    ; Search cache
    Loop %gCacheSize% {
      targetShortcutPath := gArrShortcutPath%A_Index%
      targetRealPath     := gArrRealPath%A_Index%
      targetDesc         := gArrDesc%A_Index%
      targetIcon         := gArrIcon%A_Index%

      if (InStr(targetRealPath, programToExec) || InStr(targetShortcutPath, programToExec) || InStr(targetDesc, programToExec)) {
        Try {
          Run, "%targetRealPath%"
        }
        DisplayTrayTip("Launching application.", targetRealPath)
        Return
      }
    }

    DisplayTrayTip("Could not launch application", searchTerm, 2)
    Return
  }

  ; Google search
  StringLeft, firstChar, searchTerm, 1
  if ("?" == firstChar) {
    StringReplace, searchTerm, searchTerm, ?
    Try {
      Run, https://www.google.com/search?q=%searchTerm%
    }
    Return
  }

  ; Window title search (explicit)
  StringLeft, firstChar, searchTerm, 1
  if ("#" == firstChar) {
    StringReplace, searchTerm, searchTerm, #

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
        ActivateWindowHWnd(hWnd, PID, processName, windowTitle)
        break
      }
    }

    ; Window title not found
    if (!found) {
      ; Give up
      DisplayTrayTip("Could not find window title.", searchTerm, 2)
    }
    Return
  }


  ;
  ; Predictive behaviour
  ; (switch windows by interpreting input)
  ;

  ; Split the input by delimiters
  StringSplit, input, searchTerm, !%A_Space%%A_Tab%
  if (ErrorLevel || searchTerm = "")
    Return

  ;
  ; Find window to switch to
  ;
  ; Search term is "program!windowtitle". Parse it for the first
  ; half, which represents the program to search for.
  ;   Hence input1 refers to program
  ;   while input2 refers to (secondary) window title
  ;

  if input1 <>
  {
    ;
    ; When switching, we are switching to a particular window,
    ; associated to a given process, and not just to a given
    ; process. Hence, we ultimately activate a *window*.
    ;
    ; In determining which window, we find out the following:
    ;   PID (PID of the process)
    ;   processName (name of the process)
    ;   hWnd (window handle)
    ;   title (window's title)
    ;
    ; Also, we prioritize search against process name. If it
    ; exists, we then check whether a not a secondary search
    ; term was specified. switch to it. If it doesn't, we then search
    ; against window titles.
    ;

    found := False

    ; Get all running processes (by PID) and search
    RunningProcessPIDs := WinGetAll("PID")
    Loop, Parse, RunningProcessPIDs, `n,
    {
      ; Grab the PID
      PID := A_LoopField                                ; PID
      if (PID == "")
        continue

      ; Grab the process name
      WinGet, processName, ProcessName, ahk_pid %PID%   ; Process name
      if (processName == "")
        continue

      ; Process found (ProcessName), get PID, hWnd and window title
      if (InStr(processName, input1, CaseSensitive=False)) {
        ; Grab the rest of the details
        found := True
        Process, Exist, %processName%
        WinGet, hWnd, ID, ahk_pid %PID%                 ; hWnd
        WinGetTitle, windowTitle, ahk_id %hWnd%         ; Window title

        ; Support for special cases
        ; (don't do the generic window title match)
        if (processName == "chrome.exe" || processName == "canary.exe" || processName == "trillian.exe")
          break

        ; User specified a particular window title of this process to grab,
        ; so we filter out the wrong windows of the right process.
        if (input2 <> "") {
          if (InStr(windowTitle, input2, CaseSensitive=False)) {
            ; Found
            Process, Exist, %processName%
            WinGet, hWnd, ID, ahk_pid %PID%                 ; hWnd
            WinGetTitle, windowTitle, ahk_id %hWnd%         ; Window title
            break
          }

        ; Just a simple search, no particular window title,
        ; so we've already found what we're looking for.
        } else {
          break
        }
      }
    }

    ; Process found
    if (found) {
      ;
      ; Handle special cases (e.g. with tabs)
      ;
      ; Special cases:
      ;   Chrome
      ;   Trillian
      ;

      ; Chrome
      if (processName == "chrome.exe" || processName == "canary.exe") {
        ; Activate Chrome 
        ActivateWindowHWnd(hWnd, PID, processName, windowTitle)

        ; Wait for Chrome to be the active window
        SetTitleMatchMode 2
        IfWinNotActive, ahk_class Chrome_WidgetWin_1,, WinActivate, ahk_class Chrome_WidgetWin_1,
        WinWaitActive, ahk_class Chrome_WidgetWin_1

        ; Get unique window handle
        ControlGet, firstTabHWnd, Hwnd

        ; Secondary search term not empty
        if input2 <>
        {
          ; Loop through tabs in Chrome
          Loop {
            WinGetActiveTitle, Title
            if (InStr(Title, input2, CaseSensitive=False))
              break
            Send {Ctrl Down}{Tab Down}{Tab Up}{Ctrl Up}
            ControlGet, currentTabHWnd, Hwnd
            if (currentTabHWnd == firstTabHWnd)
              break
          }
        }
      }

      ; Trillian
      else if (processName == "trillian.exe") {
        ; Specified a particular window
        if input2 <>
        {
          ; Only activate a valid window and display TrayTip if successful
          SetTitleMatchMode, RegEx
          WinActivate, i)%input2%, Trillian Window
          IfWinActive, i)%input2%, Trillian Window
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
          ActivateWindowHWnd(hWnd, PID, processName, windowTitle)
        }
        
      }

      ; Others (everything else)
      else {
        ; We're done, just activate
        ActivateWindowHWnd(hWnd, PID, processName, windowTitle)
      }
    }

    ; Process not found, try window titles instead
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
          ActivateWindowHWnd(hWnd, PID, processName, windowTitle)
          break
        }
      }

      ; Window title not found
      if (!found) {
        ; Give up
        DisplayTrayTip("Could not find anything.", searchTerm, 2)
      }
    }

    Return
  }

  ; We don't know what to do, just search for it! :)
  ; However, this should never happen.
  else {
    ; Search
    Run, https://www.google.com/search?q=%input2%
  }

  Return
}


; ----------------------------------------------------------------------------
; ActivateWindowHWnd()
;
; Activates the specified window by hWnd, and displays the
; tray tip.
; ----------------------------------------------------------------------------

ActivateWindowHWnd(hWnd, PID, processName, windowTitle) {
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
; ActivateWindowPID()
;
; Activates the specified window by hWnd, and displays the
; tray tip.
; ----------------------------------------------------------------------------

ActivateWindowPID(PID, processName, windowTitle) {
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


