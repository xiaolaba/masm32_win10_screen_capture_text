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
;*********************************************************************************************************************
include c:\masm32\include\windows.inc
include c:\masm32\include\kernel32.inc
includelib c:\masm32\lib\kernel32.lib
include c:\masm32\include\user32.inc
includelib c:\masm32\lib\user32.lib
;**********************************************************************************************************************
DialogMain proto :DWORD,:DWORD,:DWORD,:DWORD
InstallHookA typedef proto :DWORD,:DWORD
InstallHookB typedef ptr InstallHookA
UnInstallHookA typedef proto
UnInstallHookB typedef ptr UnInstallHookA
;***********************************************************************************************************************
.const
IDD_MAIN equ 1000
IDC_WORD equ 1001
;***********************************************************************************************************************
.data?
numused dd ?
hProcess dd ?
hText dd ?
.data

FileHeader db 0ffh,0feh
szlib db "hookapifar.dll",0
hlib dd 0
InstallHook InstallHookB 0
UnInstallHook UnInstallHookB 0
szinstall db "InstallHook",0
szuninstall db "UnInstallHook",0
szClassNotePad db "Notepad",0
;;;;;; win10 previlage control ? no output file at all.
;;szFile db "c:\dbg.debug",0  ; output result
;;try user account and desktop for debug log, my user account is "user1", path is following, change file name to debug.txt
szFile db "c:\Users\user1\Desktop\debug.txt"

hNotepad dd ?
written dd 0
;***************************************************************************************************************************
.code
_main:
  invoke GetModuleHandle,NULL
  mov hProcess,eax
  invoke LoadLibrary,addr szlib
  mov hlib,eax
  invoke GetLastError
  invoke GetProcAddress,hlib,addr szinstall
  mov InstallHook,eax
  invoke GetProcAddress,hlib,addr szuninstall
  mov UnInstallHook,eax
  invoke CreateFile,addr szFile,GENERIC_READ or GENERIC_WRITE,FILE_SHARE_READ or FILE_SHARE_WRITE,NULL,CREATE_ALWAYS,NULL,NULL
  mov hText,eax
  invoke WriteFile,hText,addr FileHeader,2,addr written,NULL  ;UNICODE
  invoke CloseHandle,hText
  invoke DialogBoxParam,hProcess,IDD_MAIN,NULL,DialogMain,NULL
  invoke ExitProcess,NULL
;///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
DialogMain proc uses ebx edi esi hWnd,uMsg,wParam,lParam

local _buffer[100]:BYTE
local hdc:HDC
local mousepos:POINT
local rect:RECT
local keystate[256]:BYTE

.if uMsg==WM_CLOSE
  invoke EndDialog,hWnd,NULL
  invoke UnInstallHook
.elseif uMsg==WM_INITDIALOG
  invoke SetWindowPos,hWnd,HWND_TOPMOST,0,0,0,0,SWP_NOSIZE
  invoke InstallHook,hText,hProcess
.else
  mov eax,FALSE
  ret
.endif
  mov eax,TRUE
  ret
DialogMain endp

end _main


;#include <c:\masm32\include\resource.h>
;#define IDD_MAIN 1000
;#define IDC_WORD 1001

;IDD_MAIN DIALOG DISCARDABLE 0, 0, 187, 60
;STYLE DS_MODALFRAME | WS_POPUP | WS_CAPTION | WS_SYSMENU
;CAPTION "getword"
;FONT 10, "System"
;BEGIN
;hookapifar.obj /Dll /Section:.bss,S /Def:f:/technique/hookapifar.def
;EDITTEXT IDC_WORD,16,22,149,12,ES_LEFT
;END

