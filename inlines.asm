; Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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
        poprbx
%endmacro

%macro  _rfetch 0                       ; R@
        pushrbx
        mov     rbx, [rsp]
%endmacro

%macro  _rfrom 0                        ; R>
        pushrbx
        pop     rbx
%endmacro

%macro  _duptor 0                       ; DUP >R
        push    rbx
%endmacro

%macro  _rfromdrop 0                    ; R> DROP
        lea     rsp, [rsp + BYTES_PER_CELL]
%endmacro

%macro  _fetch 0                        ; @
        mov     rbx, [rbx]
%endmacro

%macro  _cfetch 0                       ; C@
        movzx   rbx, byte [rbx]
%endmacro

%macro  _lfetch 0                       ; L@
        mov     ebx, [rbx]
%endmacro

%macro  _dup 0                          ; DUP
        pushrbx
%endmacro

%macro  _dupcfetch 0                    ; DUP C@
        _dup
        _cfetch
%endmacro

%macro  _?dup 0
        test    rbx, rbx
        jz      %%skip
        pushrbx
%%skip:
%endmacro

%macro  _swap 0                         ; SWAP
        mov     rax, rbx
        mov     rbx, [rbp]
        mov     [rbp], rax
%endmacro

%macro  _nip 0                          ; NIP
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _over 0                         ; OVER
        mov     [rbp - BYTES_PER_CELL], rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp - BYTES_PER_CELL]
%endmacro

%macro  _plus 0                         ; +
        add     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _oneplus 0                      ; 1+
        add     rbx, 1                  ; faster than inc rbx
%endmacro

%macro  _twoplus 0                      ; 2+
        add     rbx, 2
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

%macro  _twostar 0                      ; 2*
        shl     rbx, 1
%endmacro

%macro  _cell 0                         ; CELL
        pushrbx
        mov     rbx, BYTES_PER_CELL
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

%macro  _zlt 0                          ; 0<
; Win32Forth
        sar     rbx, 63
%endmacro

%macro  _notequal 0
        cmp     rbx, [rbp]
        setne   bl
        neg     bl
        movsx   rbx, bl
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _negate 0                       ; NEGATE
        neg     rbx
%endmacro

%macro  _overplus 0                     ; OVER +
        add     rbx, [rbp]
%endmacro

%macro  _overminus 0                    ; OVER -
        sub     rbx, [rbp]
%endmacro

%macro  _overswap 0                     ; OVER SWAP
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

%macro  _plusdup 0                      ; + DUP
        add     rbx, [rbp]
        mov     [rbp], rbx
%endmacro

%macro  _string_to_zstring 0            ; $>z
        _oneplus
%endmacro

%macro  _dtos 0                         ; D>S
        _drop
%endmacro

%macro  _stod 0                         ; S>D
        _dup
        _zlt
%endmacro

%macro  _count 0                        ; COUNT
        mov     al, [rbx]
        inc     rbx
        pushrbx
        movzx   rbx, al
%endmacro
