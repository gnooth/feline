; Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

%ifdef WIN64_NATIVE
%macro  xcall   1
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
        test    rsp, 0x0f
        jnz     %%fixstack
        call    %1
        jmp     %%out
%%fixstack:
        sub     rsp, 8
        call    %1
        add     rsp, 8
%%out:
        add     rsp, 32
        pop     rbp
%endmacro
%else
; Linux
%define xcall   call
%endif

%macro  _       1
        call    %1
%endmacro

%macro  _lit    1
        pushd   %1
%endmacro

%define current_file    0

%macro  file    1
%strlen len     %1
section .text
        align   8
%%name:
        db      len
        db      %1
        db      0
%define current_file    %%name
%endmacro

%define link    0

%macro  head 2-4 0, 0                   ; label, name, flags, inline size
global %1
%strlen len     %2
        section .data
        align   8
%1_pfa:
        section .text
        align   8
%1_xt:
        dq      %1                      ; address of code
        dq      0                       ; comp field
        dq      link                    ; link field
        dq      %1_pfa                  ; address of parameter field in data area
        db      %3                      ; flags
        db      %4                      ; inline size
        dq      current_file            ; pointer to source file name
        dq      __LINE__                ; source line number
%1_nfa:
        db      len                     ; length byte
        db      %2                      ; name
%define link    %1_nfa                  ; link field points to name field
%endmacro

%macro  code 2-4 0, 0
        head %1, %2, %3, %4
        section .text
        align   8
%1:
%endmacro

%macro  endcode 0-1
%endmacro

%macro  inline 2
        %push inline
        head %1, %2, 0, %$ret - %1
        section .text
        align   8
%1:
%endmacro

%macro  endinline 0
        section .text
%$ret:
        ret
        %pop inline
%endmacro

%macro  deferred 3                      ; label, name, action
        head %1, %2, 0, 0
        section .data
        global %1_data
        align   8
%1_data:
        dq      %3_xt
        section .text
        align   8
%1:
        mov     rax, %1_data
        mov     rax, [rax]
        jmp     [rax]
        ret                             ; for decompiler
%endmacro

%macro  variable 3                      ; label, name, value
        head  %1, %2
        section .data
        global %1_data
        align   8
%1_data:
        dq      %3
        section .text
%1:
        pushrbx
        mov     rbx, %1_data
        next
%endmacro

%macro  value 3                         ; label, name, value
        head  %1, %2
        section .data
        global %1_data
        align   8
%1_data:
        dq      %3
        section .text
%1:
        pushrbx
        mov     rbx, %1_data
        mov     rbx, [rbx]
        next
%endmacro

%macro  _to 1                           ; label
        mov     rax, %1_data
        mov     [rax], rbx
        poprbx
%endmacro

%macro  _plusto 1                       ; label
        mov     rax, %1_data
        add     [rax], rbx
        poprbx
%endmacro

%macro  _dotq 1
section .data
%strlen len     %1
%%string:
        db      len                     ; length byte
        db      %1                      ; string
        db      0                       ; null byte at end
section .text
        pushrbx
        mov     rbx, %%string
        call    counttype
%endmacro

%macro  _abortq 1
section .data
%strlen len     %1
%%string:
        db      len                     ; length byte
        db      %1                      ; string
        db      0                       ; null byte at end
section .text
        pushrbx
        mov     rbx, %%string
        call    parenabortquote
%endmacro

%macro  _cquote 1                       ; -- c-addr
section .data
%strlen len     %1
%%string:
        db      len                     ; length byte
        db      %1                      ; string
        db      0                       ; null byte at end
section .text
        pushrbx
        mov     rbx, %%string
%endmacro

%macro  _squote 1                       ; -- c-addr u
section .data
%strlen len     %1
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
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jz      %1_ifnot
%endmacro

%macro  _zeq_if 1
        %push if
        section .text
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jnz      %1_ifnot
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
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        je      %1_end
%endmacro

%macro _repeat 1
section .text
        jmp     %1_begin
%1_end:
%endmacro

%macro  _until 1
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jz      %1_begin
%endmacro

%macro _drop 0                          ; DROP
        poprbx
%endmacro

%macro _twodrop 0                       ; 2DROP
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro _threedrop 0                     ; 3DROP
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
%endmacro

%macro _do_common 0
        mov     rdx, [rbp]              ; limit in rdx
        mov     rax, $8000000000000000  ; offset loop limit by $8000000000000000
        add     rdx, rax
        push    rdx                     ; r: -- leave-addr limit
        sub     rbx, rdx                ; subtract modified limit from index
        push    rbx                     ; r: -- leave-addr limit index
        _twodrop
%endmacro

%macro _do 1
        mov     rax, %1_exit            ; leave-addr in rax
        push    rax                     ; r: -- leave-addr
        _do_common
%1_top:
%endmacro

%macro _?do 1
        mov     rax, %1_exit            ; leave-addr in rax
        push    rax                     ; r: -- leave-addr
        cmp     rbx, [rbp]
        jne     %1_ok
        _twodrop
        ret                             ; same as jumping to %1_exit
%1_ok:
        _do_common
%1_top:
%endmacro

%macro _loop 1
        inc     qword [rsp]
        jno     %1_top
        add     rsp, BYTES_PER_CELL * 3
%1_exit:
%endmacro

%macro _i 0                             ; I
        pushrbx
        mov     rbx, [rsp]
        add     rbx, [rsp + BYTES_PER_CELL]
%endmacro

%macro _leave 0                         ; LEAVE
        add     rsp, BYTES_PER_CELL * 2
        ret                             ; same as jumping to %1_exit
%endmacro

%macro _unloop 0                        ; UNLOOP
        add     rsp, BYTES_PER_CELL * 3
%endmacro
