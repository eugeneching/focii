
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


