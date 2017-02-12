; Copyright (C) 2012-2017 Peter Graves <gnooth@gmail.com>

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

%macro  _?do 1
        mov     rax, [rbp]              ; limit in rax, start index in rbx
        sub     rax, rbx                ; number of iterations in rax
        ja      %1_ok
        _2drop
        jmp     %1_exit
%1_ok:
        push    rax                     ; r: -- limit
        push    rbx                     ; r: -- limit start-index
        _2drop
        align   DEFAULT_CODE_ALIGNMENT
%1_top:
%endmacro

%macro  _do 1
        _?do    %1
%endmacro

%macro  _loop 1
        add     qword [rsp], 1
        sub     qword [rsp + BYTES_PER_CELL], 1
        jnz     %1_top
        add     rsp, BYTES_PER_CELL * 2
%1_exit:
%endmacro

%macro  _i 0
        pushrbx
        mov     rbx, [rsp]
%endmacro

%macro  _leave 0
        add     rsp, BYTES_PER_CELL * 2
        jmp     %1_exit
%endmacro

%macro  _unloop 0
        add     rsp, BYTES_PER_CELL * 2
%endmacro
