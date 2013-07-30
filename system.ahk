; ----------------------------------------------------------------------------
; CacheStartMenuItems()
;
; Builds an in-memory cache of all the details of applications
; that exist on the user's and the common start menu. Also
; shows a GUI.
; ----------------------------------------------------------------------------

g_is_start_menu_items_cached := False
g_cache_size := 0

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
  g_cache_size := 1

  path_to_search := ENV_APPDATA . "\Microsoft\Windows\Start Menu\Programs\*.*"
  Loop, %path_to_search%, 0, 1
  {
    FileGetShortcut, %A_LoopFileLongPath%, target_real_path,,, target_desc, target_icon
    gArrFileName%g_cache_size% = %A_LoopFileName%
    gArrShortcutPath%g_cache_size% = %A_LoopFileLongPath%
    gArrRealPath%g_cache_size% = %target_real_path%
    gArrDesc%g_cache_size% = %target_desc%
    gArrIcon%g_cache_size% = %target_icon%
    g_cache_size := g_cache_size + 1
    ;AddToAutocompleteList("!"A_LoopFileName)
  }

  path_to_search := ENV_PROGRAMDATA . "\Microsoft\Windows\Start Menu\Programs\*.*"
  Loop, %path_to_search%, 0, 1
  {
    FileGetShortcut, %A_LoopFileLongPath%, target_real_path,,, target_desc, target_icon
    gArrFileName%g_cache_size% = %A_LoopFileName%
    gArrShortcutPath%g_cache_size% = %A_LoopFileLongPath%
    gArrRealPath%g_cache_size% = %target_real_path%
    gArrDesc%g_cache_size% = %target_desc%
    gArrIcon%g_cache_size% = %target_icon%
    g_cache_size := g_cache_size + 1
    ;AddToAutocompleteList("!"A_LoopFileName)
  }

  ; Remove the GUI
  Gui, Destroy
}


; ----------------------------------------------------------------------------
; LaunchApplication()
;
; Launches an application by searching the start menu for the link,
; search the path, shortcut path and program description.
; ----------------------------------------------------------------------------

LaunchApplication(program_to_exec) {
  global g_is_start_menu_items_cached, g_cache_size

  ; Grab necessary environment variables
  EnvGet, ENV_LOCALAPPDATA, LOCALAPPDATA
  EnvGet, ENV_APPDATA, APPDATA
  EnvGet, ENV_PROGRAMDATA, ALLUSERSPROFILE
  EnvGet, ENV_PATH, PATH

  ; Manual rebuild cache (command: !!)
  if (program_to_exec == "!") {
    CacheStartMenuItems()
    g_is_start_menu_items_cached := True
    Return
  }

  ; Cache start menu items (first run)
  if (!g_is_start_menu_items_cached) {
    CacheStartMenuItems()
    g_is_start_menu_items_cached := True
  }

  ; Build regex to search for program name
  regex_expr := "i)^"program_to_exec
  regex_expr .= "\."

  ; Search cache (by file name first)
  Loop %g_cache_size% {
    target_file_name     := gArrFileName%A_Index%
    target_shortcut_path := gArrShortcutPath%A_Index%
    target_real_path     := gArrRealPath%A_Index%
    target_desc          := gArrDesc%A_Index%
    target_icon          := gArrIcon%A_Index%

    found := RegExMatch(target_file_name, regex_expr)
    if (found != "" && found != 0) {
      Try {
        Run, "%target_real_path%"
      }
      DisplayTrayTip("Launching application.", target_real_path)
      Return
    }
  }

  Return

  ; Search cache (fuzzy search)
  ;
  ; We disable this for now.
  ;
  Loop %g_cache_size% {
    target_file_name     := gArrFileName%A_Index%
    target_shortcut_path := gArrShortcutPath%A_Index%
    target_real_path     := gArrRealPath%A_Index%
    target_desc          := gArrDesc%A_Index%
    target_icon          := gArrIcon%A_Index%

    if (InStr(target_real_path, program_to_exec) || InStr(target_shortcut_path, program_to_exec) || InStr(target_desc, program_to_exec)) {
      Try {
        Run, "%target_real_path%"
      }
      DisplayTrayTip("Launching application (fuzzy search).", target_real_path)
      Return
    }
  }

  DisplayTrayTip("Could not launch application", program_to_exec, 2)
  Return
}


; ----------------------------------------------------------------------------
; ExplorePath()
;
; Opens explorer to the path specified.
; ----------------------------------------------------------------------------

ExplorePath(search_term) {
  if (FileExist(search_term)) {
    Try {
      ; Try dopus first
      Run, dopus.exe "%search_term%"
    } Catch e {
      ; Default back to explorer
      Run, explorer.exe "%search_term%"
    }
    DisplayTrayTip("Launching explorer.", search_term)
    Return

  } else {
    DisplayTrayTip("Could not launch explorer.", "No such path """ . search_term . """.", 2)
  }
}


; ----------------------------------------------------------------------------
; WebSearch()
;
; Performs a query using the browser, through a search engine.
; This is Google.
; ----------------------------------------------------------------------------

WebSearch(search_term) {
  Try {
    Run, https://www.google.com/search?q=%search_term%
  }
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


