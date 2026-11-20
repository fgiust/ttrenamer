@ echo off
path=d:\engineer\assembler\tasm\bin\
tasm32 -z ttr
tlink32 -Tpe -aa -x -c ttr , TrueType_Renamer.exe,, import32,,res\window.res
if exist ttr.obj del ttr.obj
if exist "TrueType Renamer.exe" del "TrueType Renamer.exe"
if exist "TrueType_Renamer.exe" ren "TrueType_Renamer.exe" "TrueType Renamer.exe"

rem pause