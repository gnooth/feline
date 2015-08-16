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
        lea     rsp, [rsp + BYTES_PER_CELL]
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

%macro _twodrop 0                       ; inline version of 2DROP
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro _threedrop 0                     ; inline version of 3DROP
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
%endmacro

%macro _nip 0                           ; inline version of NIP
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro _plus 0                          ; inline version of +
        add     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro _oneplus 0                       ; inline version of 1+
        add     rbx, 1                  ; faster than inc rbx
%endmacro

%macro _twoplus 0                       ; inline version of 2+
        add     rbx, 2
%endmacro

%macro _oneminus 0                      ; inline version of 1-
        sub     rbx, 1
%endmacro

%macro _cells 0                         ; inline version of CELLS
        shl     rbx, 3
%endmacro

%macro _cellplus 0                      ; inline version of CELL+
        add     rbx, BYTES_PER_CELL
%endmacro

%macro _cellminus 0                     ; inline version of CELL-
        sub     rbx, BYTES_PER_CELL
%endmacro

%macro _i 0                             ; inline version of I
        pushrbx
        mov     rbx, [rsp]
        add     rbx, [rsp + BYTES_PER_CELL]
%endmacro

%macro _unloop 0                        ; inline version of UNLOOP
        add     rsp, BYTES_PER_CELL * 3
%endmacro

%macro _zeq 0                           ; inline version of 0=
; Win32Forth
        cmp     rbx, 1
        sbb     rbx, rbx
%endmacro

%macro _zlt 0                           ; inline version of 0<
; Win32Forth
        sar     rbx, 63
%endmacro

%macro _ntolink 0                       ; inline version of N>LINK
        sub     rbx, BYTES_PER_CELL * 2 + 2
%endmacro
