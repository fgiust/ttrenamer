
```
Pretty old, isn't it? 
This is the first program I ever wrote, back when I was learning assembly 
language one summer in my youth.
No tools, no AI, just programming at its most barebones... Saving the source
code here for old times' sake.
```


TrueType Renamer for Windows
=================================

Rename Truetype Font files to the font's real name.
With 32-bit versions of Windows you can have names longer than 8.3 chars,
so why those stupid short names? TrueType renamer is a small (12k!) utility
that can automatically change the original's font's filename to the typeface's
real name. No more ttf432.ttf or arbi__.ttf, but "Bookman Old Style" or 
"Arial Bold Italic"...

Minimum Requirements
====================
A 486 with Window$ 95, 98 or NT
About 1k of free memory ;)


Instructions
============

Simply run the program and select the folder containing the font files you
wish to rename. Press OK and TrueType Renamer will rename any *.ttf file found
in the folder.
The renaming process happens in background, during this you can see a small
icon in the tray area. At the end TrueType Renamer will display the number of
files renamed.
That's all... TrueType Renamer does just that!

TrueType Renamer is useful if you have a TrueType collection and you want to
see fonts' names without installing them or without using any stupid program.
It also helps you not to have duplicated files.

Warning: if you try to rename files in your 'windows\fonts' folder you will get 
error messages for fonts currently used by system (your shell fonts). TrueType 
Renamer will rename any other file, but not those ones. It' better to rename
fonts BEFORE install them!


Notes
=====
TrueType Renamer is written totally in assembler (only tool used for writing 
its code: Notepad!). This means that this program is small and fast. It doesn't
require any overbloated dll!
In writing this program I referred to "Micro$oft TrueType 1.0 Font File 
Specification, v.1.65". The way used to read font names is developed only with
information found in this document.
TrueType Renamer uses fastest system to access font files!


(c) 1998 Fabrizio Giustina