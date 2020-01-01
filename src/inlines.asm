; Copyright (C) 2012-2020 Peter Graves <gnooth@gmail.com>

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

%macro  _tor 0                          ; >R
        push    rbx
        _drop
%endmacro

%macro  _rfetch 0                       ; R@
        _dup
        mov     rbx, [rsp]
%endmacro

%macro  _rfrom 0                        ; R>
        _dup
        pop     rbx
%endmacro

%macro  _duptor 0                       ; DUP >R
        push    rbx
%endmacro

%macro  _rdrop 0                        ; RDROP
        lea     rsp, [rsp + BYTES_PER_CELL]
%endmacro

%macro  _tworfrom 0
        mov     [rbp - BYTES_PER_CELL], rbx
        pop     rbx
        pop     qword [rbp - BYTES_PER_CELL * 2]
        lea     rbp, [rbp - BYTES_PER_CELL * 2]
%endmacro

%macro  _fetch 0                        ; @
        mov     rbx, [rbx]
%endmacro

%macro  _cfetch 0                       ; C@
        movzx   ebx, byte [rbx]
%endmacro

%macro  _wfetch 0                       ; W@
        movzx   ebx, word [rbx]
%endmacro

%macro  _lfetch 0                       ; L@
        mov     ebx, [rbx]
%endmacro

%macro  _store 0                        ; !
        mov     rax, [rbp]
        mov     [rbx], rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _cstore 0                       ; C!
        mov     al, [rbp]
        mov     [rbx], al
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _wstore 0                       ; W!
        mov     ax, [rbp]
        mov     [rbx], ax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _lstore 0                       ; L!
        mov     eax, [rbp]
        mov     [rbx], eax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _dup 0
        mov     [rbp - BYTES_PER_CELL], rbx
        lea     rbp, [rbp - BYTES_PER_CELL]
%endmacro

%macro  _twodup 0                       ; 2DUP
        mov     rax, [rbp]
        lea     rbp, [rbp - BYTES_PER_CELL * 2]
        mov     [rbp], rax
        mov     [rbp + BYTES_PER_CELL], rbx
%endmacro

%macro  _?dup 0
        test    rbx, rbx
        jz      %%skip
        _dup
%%skip:
%endmacro

%macro  _swap 0
        mov     rax, rbx
        mov     rbx, [rbp]
        mov     [rbp], rax
%endmacro

%macro  _nip 0
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _2nip 0
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _3nip 0
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
%endmacro

%macro  _over 0
        mov     [rbp - BYTES_PER_CELL], rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp - BYTES_PER_CELL]
%endmacro

; This is the Factor/Feline version of pick.
%macro  _pick 0
        _dup
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _plus 0                         ; +
        add     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _oneplus 0                      ; 1+
        add     rbx, 1                  ; faster than inc rbx
%endmacro

%macro  _minus 0                        ; -
        neg     rbx
        add     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _oneminus 0                     ; 1-
        sub     rbx, 1
%endmacro

%macro  _swapminus 0                    ; SWAP-
        sub     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _star 0
        imul    rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _twostar 0                      ; 2*
        shl     rbx, 1
%endmacro

%macro  _cells 0                        ; CELLS
        shl     rbx, 3
%endmacro

%macro  _cellplus 0                     ; CELL+
        add     rbx, BYTES_PER_CELL
%endmacro

%macro  _cellminus 0                    ; CELL-
        sub     rbx, BYTES_PER_CELL
%endmacro

%macro  _zeq 0                          ; 0=
; Win32Forth
        cmp     rbx, 1
        sbb     rbx, rbx
%endmacro

%macro  _ult 0                          ; u<
; Win32Forth
        cmp     [rbp], rbx
        sbb     rbx, rbx
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _ugt 0                          ; u>
; Win32Forth
        cmp     rbx, [rbp]
        sbb     rbx, rbx
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _ge 0                           ; >=
        cmp     [rbp], rbx
        setge   bl
        neg     bl
        movsx   rbx, bl
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _zlt 0                          ; 0<
; Win32Forth
        sar     rbx, 63
%endmacro

%macro  _zge 0
        _zlt
        not     rbx
%endmacro

%macro  _equal 0                        ; =
        cmp     rbx, [rbp]
        sete    bl
        neg     bl
        movsx   rbx, bl
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _notequal 0                     ; <>
        cmp     rbx, [rbp]
        setne   bl
        neg     bl
        movsx   rbx, bl
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _max 0                          ; n1 n2 -- n
        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        cmp     rax, rbx
        cmovge  rbx, rax
%endmacro

%macro  _dupd 0                         ; dupd
        mov     rax, [rbp]
        mov     [rbp - BYTES_PER_CELL], rax
        lea     rbp, [rbp - BYTES_PER_CELL]
%endmacro

%macro  _dropswap 0                     ; DROP SWAP
        mov     rax, [rbp]
        mov     rbx, [rbp + BYTES_PER_CELL]
        mov     [rbp + BYTES_PER_CELL], rax
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _and 0
        and     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _and_literal 1
        and     rbx, %1
%endmacro

%macro  _or 0
        or      rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _not 0
        mov     eax, TRUE
        cmp     rbx, NIL
        mov     ebx, NIL
        cmove   ebx, eax
%endmacro

%macro _nil? 0
        mov     eax, NIL
        cmp     rbx, rax
        mov     ebx, TRUE
        cmovne  ebx, eax
%endmacro

%macro  _tuck 0                         ; x1 x2 -- x2 x1 x2
        mov     rax, [rbp]              ; x1 in rax, x2 in rbx
        mov     [rbp], rbx
        mov     [rbp - BYTES_PER_CELL], rax
        lea     rbp, [rbp - BYTES_PER_CELL]
%endmacro

%macro  _lshift 0                       ; x1 u  -- x2
        mov     ecx, ebx
        _drop
        shl     rbx, cl
%endmacro

%macro  _rshift 0                       ; x1 u  -- x2
        mov     ecx, ebx
        _drop
        shr     rbx, cl
%endmacro
