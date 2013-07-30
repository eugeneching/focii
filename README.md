The goal of Focii is to:

> Make window switching a keyboard only affair, and let me get to any
> window (unless it's hidden), using a small number of keystrokes that
> I can easily remember.

### Find a window

The main keystroke is `ctrl-;`. This is a global key-binding that opens
the main focii search window. In this window, you can enter a search term.
It will then find a window that best matches that search term.

The search window looks like a small bar in the middle of the screen. If
you have multiple screens, it's going to appear on the screen where your
mouse cursor is. This may change.

And here's how it searches:

  - Among program names (e.g. chrome.exe, firefox.exe, winword.exe)
  - Among window titles (i.e. the text that's *usually* in the title bar)

And really that's it. The key thing to remember is that it is going to
open the *first* correct match it finds. Note that is searches against
*program names* (the name of the executable, for instance), and not the
common name of the program (e.g. Microsoft Word).


### Can I be more specific?

Actually you can. You can search amongst programs *and* their window title,
at the same time. Meaning, for instance, you have 20 Microsoft Word windows
open, and you want to find the one that is display the "readme.doc" file.

Then you can do this search query:

    word!readme

And it's going to open the first document that is open is Microsoft Word.
The assumption is that the program name "Word" matches "Microsoft Word" and
not something like "Wordpad", for instance. If there is ambiguity, you just
need to be more specific:

    winword!readme 


### Oops, it got it wrong, now what?

Focii gives you two methods to recourse if it gives you the wrong window.
The first is to switch among windows that matches the search term, but
was not the first match. The key-binding is:

    win-;

The second method of recourse is for you to switch among windows of the
same application, no matter what those windows are. They key-binding is:

    alt-;

The exception to the `alt-;` is if the window is not a Windows (the operating
system) recognized window. A good example are tabs (i.e. browser tabs, for
instance). These tabs are implemented not in a way that Windows can trivially
enumerate, and hence Focii doesn't switch among them. However, most
applications that implements tabs allows you to switch easily among them
anyway. A seemingly consistent standard is `ctrl-tab`.

Hence, I believe and hope that with these key combinations at your disposal, it
becomes fairly quick and easy to get to the window you want, keyboard-style.


### Auxillary utilities

Focii also gives you some other goodies, if you will. 


#### Flashing current window

First of all, when you switch between windows, it flashes the active window. 
This gives you a visual cue where you are. In addition, if you lose track
(since you're not using the mouse), hitting:

    ctrl-alt-;

will flash the current active window.


#### Starting a program

In the spirit of a launcher, typing

    !<program-name>

will have Focii search the start menu for a matching name, and *start* that
process. Note that this is not window switching. I'd also like to say that this
is not Focii's main aim, and hence may not be the most intelligent or advanced
launching mechanism around ;)



