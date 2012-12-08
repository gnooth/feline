; Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

%macro  next    0
        ret
%endmacro

%macro  _return 0
        ret
%endmacro

%macro  pushrbx 0
        mov     [rbp - BYTES_PER_CELL], rbx
        lea     rbp, [rbp - BYTES_PER_CELL]
%endmacro

%macro  poprbx  0
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  pushd   1
        pushrbx
        mov     rbx, %1
%endmacro

%macro  popd    1
        mov     %1, rbx
        poprbx
%endmacro

%macro  _       1
        call    %1
%endmacro

%macro  _lit    1
        pushd   %1
%endmacro

%define link    0

%macro  head 2-4 0, 0                   ; label, name, flags, inline size
global %1
%strlen len     %2
        [section .data]
        dq      %1                      ; cfa
; %1_lfa  equ     $
        dq      link
        db      %3                      ; flags
        db      %4                      ; inline size
%1_nfa  equ     $
%define link    %1_nfa
        db      len                     ; length byte
        db      %2                      ; name
        __SECT__
%endmacro

%macro  code 2-4 0, 0
head  %1, %2, %3, %4
section .text
%1:
%endmacro

%macro  endcode 0-1
%endmacro

%macro  variable 3                      ; label, name, value
head  %1, %2
section .data
global %1_data
%1_data:
        dq      %3
section .text
%1:
        pushrbx
        mov     rbx, %1_data
        next
%endmacro

%macro  _dotq 1
section .data
%strlen  len     %1
%%string:
        db      len                     ; length byte
        db      %1                      ; string
        db      0                       ; null byte at end
section .text
        pushrbx
        mov     rbx, %%string
        call    count
        call    type
%endmacro

%macro  _abortq 1
section .data
%strlen  len     %1
%%string:
        db      len                     ; length byte
        db      %1                      ; string
        db      0                       ; null byte at end
section .text
        pushrbx
        mov     rbx, %%string
        call    count
        call    parenabortquote
%endmacro

%macro  _string 1
section .data
%strlen  len     %1
%%string:
        db      len                     ; length byte
        db      %1                      ; string
        db      0                       ; null byte at end
section .text
        pushrbx
        mov     rbx, %%string
        call    count
%endmacro

%macro  _if 1
        %push if
        section .text
;         mov     rax, rbx
;         poprbx
;         test    rax, rax
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jz      %1_ifnot
%endmacro

%macro  _else 1
%ifctx if
        %repl   else
        section .text
        jmp     %1_then
%1_ifnot:
%else
        %error  "expected _if before _else"
%endif
%endmacro

%macro  _then 1
%ifctx if
%1_ifnot:
        %pop
%elifctx else
%1_then:
        %pop
%else
        %error  "expected _if or _else before _then"
%endif
%endmacro

%macro  _begin 1
section .text
%1_begin:
%endmacro

%macro _again 1
section .text
        jmp     %1_begin
%endmacro

%macro _while 1
        popd    rax                     ; flag in RAX
        or      rax, rax
        je      %1_end
%endmacro

%macro _repeat 1
section .text
        jmp     %1_begin
%1_end:
%endmacro

%macro  _until 1
        popd    rax
        or      rax, rax
        jz      %1_begin
%endmacro

%macro _do 1
        _ parendo
        dq      %1_exit
%1_top:
%endmacro

%macro _?do 1
        _ paren?do
        dq      %1_exit
%1_top:
%endmacro

%macro _loop 1
        _ parenloop
        dq      %1_top
%1_exit:
%endmacro

%macro _tor 0                           ; inline version of >R
        push    rbx
        poprbx
%endmacro

%macro _rfetch 0                        ; inline version of R@
        pushrbx
        mov     rbx, [rsp]
%endmacro

%macro _rfrom 0                         ; inline version of R>
        pushrbx
        pop     rbx
%endmacro

%macro _duptor 0                        ; inline version of DUP>R
        push    rbx
%endmacro

%macro _rfromdrop 0                     ; inline version of R>DROP
        add     rsp, BYTES_PER_CELL
%endmacro

%macro _fetch 0                         ; inline version of @
        mov     rbx, [rbx]
%endmacro

%macro _cfetch 0                        ; inline version of C@
        movzx   rbx, byte [rbx]
%endmacro

%macro _dup 0                           ; inline version of DUP
        pushrbx
%endmacro

%macro _drop 0                          ; inline version of DROP
        poprbx
%endmacro

%macro _nip 0                           ; inline version of NIP
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro
