;;;; 2018-MAY-19, upload to GITHUB, by xiaolaba
;;;; source codes, some error, copy from, very aged,
;;;; http://www.wangchao.net.cn/bbsdetail_873811.html
;;;; https://blog.csdn.net/bcbobo21cn/article/details/70473867
;;;; https://blog.csdn.net/hyblusea/article/details/1363808

;;;; Tool required
;;;; http://www.masm32.com/download.htm
;;;; very wrong format by copy from those web page, reformat to proper win32 asm, assembly ok;
;;;; 2018-MAY-20

.386
.model flat,stdcall
option casemap:none
;******************************************************************************************

;***************************
include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
includelib c:\masm32\lib\kernel32.lib
include c:\masm32\include\user32.inc
includelib c:\masm32\lib\user32.lib
include c:\masm32\include\gdi32.inc
includelib c:\masm32\lib\gdi32.lib
;******************************************************************************************


;****************************
jmpinto struct; jump table
  a db ?
  newapi dd ?
  b db ?
  d db ?
jmpinto ends

HookApi proto :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
_SetWindowText proto :DWORD,:DWORD,:DWORD
NTextOutA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
NTextOutW PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
NExtTextOutA PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
NExtTextOutW PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
_ptextout typedef PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD
ptextout typedef ptr _ptextout
_pexttextout typedef PROTO :DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD,:DWORD
pexttextout typedef ptr _pexttextout
;******************************************************************************************


;*****************************
.data?
hText  dd ?
Hhost  dd ?

.data
hHook dd 0
code_ta db 10 dup(0)
code_tw db 10 dup(0)
code_ea db 10 dup(0)
code_ew db 10 dup(0)
tajmpinto jmpinto<0,0,0,0>
twjmpinto jmpinto<0,0,0,0>
eajmpinto jmpinto<0,0,0,0>
ewjmpinto jmpinto<0,0,0,0>
OldTextOutA ptextout 0
OldTextOutW ptextout 0
OldExtTextOutA pexttextout 0
OldExtTextOutW pexttextout 0
hProcess dd ?
PHandle dd 0
PId dd 0
numused dd 0
szTextOutA db "TextOutA",0
szTextOutW db "TextOutW",0
szExtTextOutA db "ExtTextOutA",0
szExtTextOutW db "ExtTextOutW",0
szGdi32 db "gdi32.dll",0
szFile db "c:\dbg.debug",0
settext dd 0
FileHeader db 0ffh,0feh
;******************************************************************************************


;*********************************************
.code
DllMain proc hInst:HINSTANCE,reason:DWORD,reserved1:DWORD; hook API
.if reason==DLL_PROCESS_ATTACH
 push hInst
 pop hProcess
 invoke GetCurrentProcessId
 mov PId,eax
 invoke OpenProcess,PROCESS_ALL_ACCESS,FALSE,PId
 .if(eax==0)
  mov eax,FALSE
  ret
 .endif
 mov PHandle,eax 
 mov eax,hProcess
 .if(eax!=Hhost)  ;XP, last API output Charecter, but preservce ohter 3 API
    ;  invoke HookApi,addr szGdi32,addr szTextOutA,addr NTextOutA,addr code_ta,addr OldTextOutA, addr tajmpinto
    ;  invoke HookApi,addr szGdi32,addr szTextOutW,addr NTextOutW,addr code_tw,addr OldTextOutW, addr twjmpinto
    ;  invoke HookApi,addr szGdi32,addr szExtTextOutA,addr NExtTextOutA,addr code_ea,addr OldExtTextOutA, addr eajmpinto
      invoke HookApi,addr szGdi32,addr szExtTextOutW,addr NExtTextOutW,addr code_ew,addr OldExtTextOutW,addr ewjmpinto
 .endif
 
 mov eax,TRUE
 ret
.elseif reason==DLL_PROCESS_DETACH  ; unhook API
 mov eax,hProcess
 .if(eax!=Hhost)
;  invoke WriteProcessMemory,PHandle,OldTextOutA,addr code_ta,sizeof code_ta,addr numused
;  invoke WriteProcessMemory,PHandle,OldTextOutW,addr code_tw,sizeof code_tw,addr numused 
;  invoke WriteProcessMemory,PHandle,OldExtTextOutA,addr code_ea,sizeof code_ea,addr numused 
  invoke WriteProcessMemory,PHandle,OldExtTextOutW,addr code_ew,sizeof code_ew,addr numused
 .endif
 mov eax,TRUE
 ret
.endif
  mov eax,TRUE
  ret
DllMain endp
;//////////////////////////////////////////////////////////////////////////////////////////


;///////////////////////////////////
MouseProc proc nCode:DWORD,wParam:DWORD,lParam:DWORD  ;name MOUSE, but actual is keybroad hook
  local mousepos:POINT
  local rect:RECT
  LOCAL hWnd:HWND
  .if wParam==VK_CONTROL  ;if control key down
   invoke GetCursorPos,addr mousepos
   invoke WindowFromPoint,mousepos.x,mousepos.y
   mov hWnd,eax
   invoke ScreenToClient,hWnd,addr mousepos
   push mousepos.x
   pop rect.left
   push mousepos.y
   pop rect.top
   push mousepos.x
   pop rect.right
   inc rect.right
   push mousepos.y
   pop rect.bottom
   inc rect.bottom
   invoke InvalidateRect,hWnd,addr rect,TRUE ;msg re-paint
  .endif
  invoke CallNextHookEx,hHook,nCode,wParam,lParam
  ret
MouseProc endp


InstallHook proc _hStatic:DWORD,_Hhost  ;install hook
   push _Hhost
   pop Hhost
   push _hStatic
   pop hText
   invoke SetWindowsHookEx,WH_KEYBOARD,addr MouseProc,hProcess,NULL
   mov hHook,eax
   ret
InstallHook endp

UnInstallHook proc
 invoke UnhookWindowsHookEx,hHook
 ret
UnInstallHook endp
;//////////////////////////////////////////////////////////////////////////////////////////


;///////////////////////////////////
HookApi proc uses ebx edi esi szlib,szproc,lpfunc,lpbuffer,lpOld,lpjmpinto;hook up API
  ;save first bits
  local hDll,lpproc
  local meminfo:MEMORY_BASIC_INFORMATION
  local numdid
  mov esi,lpjmpinto
  assume esi:ptr jmpinto
  invoke RtlZeroMemory,esi,sizeof jmpinto
  mov [esi].a,0b8h
  mov eax,lpfunc
  mov [esi].newapi,eax
  mov [esi].b,0ffh
  mov [esi].d,0e0h
  invoke LoadLibrary,szlib
  mov hDll,eax
  invoke GetProcAddress,hDll,szproc
  mov edi,lpOld
  mov dword ptr[edi],eax
  invoke VirtualQueryEx,PHandle,[edi],addr meminfo,sizeof meminfo
  invoke VirtualProtectEx,PHandle,meminfo.BaseAddress,0ah,PAGE_EXECUTE_READWRITE,addr meminfo.Protect
  invoke GetLastError
  invoke ReadProcessMemory,PHandle,[edi],lpbuffer,10,addr numdid
  invoke WriteProcessMemory,PHandle,[edi],esi,sizeof jmpinto,addr numdid
  ret
HookApi endp
;//////////////////////////////////////////////////////////////////////////////////////////


;///////////////////////////////////
_SetWindowText proc uses ebx edi esi hWnd,lpBuffer,cbCount; C:\DBG.DEBUG start obtained
  ;all words
  local written
  local lpMultiByteStr[256]:BYTE
  local @end[2]:BYTE
  invoke RtlZeroMemory,addr lpMultiByteStr,sizeof lpMultiByteStr
  invoke CreateFile,addr szFile,GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,OPEN_EXISTING,NULL,NULL
  mov hText,eax
  ;invoke WriteFile,hText,addr FileHeader,2,addr written,NULL
  invoke SetFilePointer,hText,NULL,NULL,FILE_END
  ;invoke WideCharToMultiByte,CP_ACP,WC_COMPOSITECHECK,lpBuffer,255,addr lpMultiByteStr,sizeof lpMultiByteStr,NULL,NULL
  invoke WriteFile,hText,lpBuffer,cbCount,addr written,NULL
  ;mov @end,0
  ;mov @end+1,'#'
  ;invoke WriteFile,hText,addr @end,2,addr written,NULL
  invoke CloseHandle,hText
  ;SendMessage,hWnd,WM_CHAR,'#',1
  ret
_SetWindowText endp
;//////////////////////////////////////////////////////////////////////////////////////////


;///////////////////////////////////
NTextOutA proc uses ebx edi esi hdc,nXStart,nYStart,lpString,cbString; 4 API hooked
  pusha
  invoke WriteProcessMemory,PHandle,OldTextOutA,addr code_ew,sizeof code_ew,addr numused
  push cbString
  mov eax,cbString
  add cbString,eax
  invoke GetAsyncKeyState,VK_CONTROL
  and eax,8000h
  .if eax
   invoke _SetWindowText,hText,lpString,cbString
  .endif
  pop cbString
  popa
  invoke OldTextOutA,hdc,nXStart,nYStart,lpString,cbString
  invoke WriteProcessMemory,PHandle,OldTextOutA,addr tajmpinto,sizeof tajmpinto,addr numused
  ret 
  NTextOutA endp
  NTextOutW proc uses ebx edi esi hdc,nXStart,nYStart,lpString,cbString
  pusha
  invoke WriteProcessMemory,PHandle,OldTextOutW,addr code_ew,sizeof code_ew,addr numused
  push cbString
  mov eax,cbString
  add cbString,eax
  invoke GetAsyncKeyState,VK_CONTROL
  and eax,8000h
  .if eax
   invoke _SetWindowText,hText,lpString,cbString
  .endif
  pop cbString
  popa
  invoke OldTextOutW,hdc,nXStart,nYStart,lpString,cbString
  invoke WriteProcessMemory,PHandle,OldTextOutW,addr twjmpinto,sizeof twjmpinto,addr numused
  ret 
NTextOutW endp
  
NExtTextOutA proc uses ebx edi esi hdc,X,Y,fuOptions,lprc,lpString,cbCount,lpDx
  pusha
  invoke WriteProcessMemory,PHandle,OldExtTextOutA,addr code_ew,sizeof code_ew,addr numused
  push cbCount
  mov eax,cbCount
  add cbCount,eax
  invoke GetAsyncKeyState,VK_CONTROL
  and eax,8000h
  .if eax
   invoke _SetWindowText,hText,lpString,cbCount
  .endif
  pop cbCount
  popa
  invoke OldExtTextOutA,hdc,X,Y,fuOptions,lprc,lpString,cbCount,lpDx
  invoke WriteProcessMemory,PHandle,OldExtTextOutA,addr ewjmpinto,sizeof eajmpinto,addr numused
  ret
NExtTextOutA endp
  
NExtTextOutW proc uses ebx edi esi hdc,X,Y,fuOptions,lprc,lpString,cbCount,lpDx
  pusha
  invoke WriteProcessMemory,PHandle,OldExtTextOutW,addr code_ew,sizeof code_ew,addr numused
  push cbCount
  mov eax,cbCount
  add cbCount,eax
  invoke GetAsyncKeyState,VK_CONTROL
  and eax,8000h
  .if eax
   invoke _SetWindowText,hText,lpString,cbCount
  .endif
  pop cbCount
  popa
  invoke OldExtTextOutW,hdc,X,Y,fuOptions,lprc,lpString,cbCount,lpDx
  invoke WriteProcessMemory,PHandle,OldExtTextOutW,addr ewjmpinto,sizeof ewjmpinto,addr numused
  ret 
NExtTextOutW endp

end DllMain

