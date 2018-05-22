:: build.BAT

:: xiaolaba, 2018-05-22
:: source code path, C:\DIY\2018-05-18_screen_translator\
:: masm32 path, C:\masm32

set assembler_path=c:\masm32\bin
set source_path=C:\DIY\2018-05-18_screen_translator\

::: delete temp and generated file, source code remains
::del /q hook*.obj
::del /q hook*.lst
::del /q hook*.ilk
::del /q hook*.res
::del /q hook*.pdb
::del /q hook*.exe
::del /q hook*.dll
::del /q hook*.lib
::del /q hook*.exp
::pause

:::::: produce hookapifar.res
%assembler_path%\rc hookapifar.rc


pause

:::::: produce hookapifarmain.exe
%assembler_path%\ml /Fl /c /coff /Zi /Cp hookapifarmain.asm

pause

%assembler_path%\link /subsystem:windows /DEBUG /DEBUGTYPE:CV hookapifarmain.obj hookapifar.res

pause

:::::: produce hookapifar.dll 
%assembler_path%\ml /c /coff /Zi /Cp hookapifar.asm

pause

%assembler_path%\link /subsystem:windows /DEBUG /DEBUGTYPE:CV hookapifar.obj /Dll /Section:.bss,S /Def:%source_path%\hookapifar.def


pause

:: delete temp and generated file, source code & exe /dll remains
del /q hook*.obj
del /q hook*.lst
del /q hook*.ilk
del /q hook*.res
del /q hook*.pdb
::del /q hook*.exe
::del /q hook*.dll
del /q hook*.lib
del /q hook*.exp