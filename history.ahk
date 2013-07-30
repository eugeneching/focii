; ----------------------------------------------------------------------------
; AddToAutocompleteList(), ClearAutocompleteList()
;
; Handles the autocomplete list.
; ----------------------------------------------------------------------------

ClearAutocompleteList() {
  global autocomplete_list
  autocomplete_list := ""
}

AddToAutocompleteList(term) {
  global autocomplete_list
  autocomplete_list := autocomplete_list . "|"term
}


; ----------------------------------------------------------------------------
; AddToHistory()
;
; Adds a search term to the history.
; ----------------------------------------------------------------------------

AddToHistory(item) {
  ; Assume global
  global

  history_size := 5

  ; Make room for new entry
  loop_count := history_size - 1
  Loop, %loop_count% {
    first_index := history_size - A_Index + 1
    next_index  := first_index - 1
    if searchHistory%first_index% =
      searchHistory%first_index% = <<history slot unused>>
    if searchHistory%next_index% =
      searchHistory%next_index% = <<history slot unused>>
    searchHistory%first_index% := searchHistory%next_index%
  }
  searchHistory1 := item
}


; ----------------------------------------------------------------------------
; Initialize()
;
; Initialize the autocomplete list.
; ----------------------------------------------------------------------------

Initialize() {
  global is_autocomplete_setup

  if (!is_autocomplete_setup) {
    ClearAutocompleteList()
    AddToAutocompleteList(":about")
    AddToAutocompleteList(";about")
    AddToAutocompleteList(":reload")
    AddToAutocompleteList(";reload")
    AddToAutocompleteList("desktop")
    AddToAutocompleteList("desk")
    AddToAutocompleteList("!<program name or description>")
    AddToAutocompleteList("@<path to open>")
    AddToAutocompleteList("#<window title>")
    is_autocomplete_setup := true
  }
}


