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

%macro  _do_common 0
        mov     rdx, [rbp]              ; limit in rdx
        mov     rax, $8000000000000000  ; offset loop limit by $8000000000000000
        add     rdx, rax
        push    rdx                     ; r: -- leave-addr limit
        sub     rbx, rdx                ; subtract modified limit from index
        push    rbx                     ; r: -- leave-addr limit index
        _2drop
%endmacro

%macro  _do 1
        mov     rax, %1_exit            ; leave-addr in rax
        push    rax                     ; r: -- leave-addr
        _do_common
%1_top:
%endmacro

%macro  _?do 1
        mov     rax, %1_exit            ; leave-addr in rax
        push    rax                     ; r: -- leave-addr
        cmp     rbx, [rbp]
        jne     %1_ok
        _2drop
        ret                             ; same as jumping to %1_exit
%1_ok:
        _do_common
%1_top:
%endmacro

%macro  _loop 1
        inc     qword [rsp]
        jno     %1_top
        add     rsp, BYTES_PER_CELL * 3
%1_exit:
%endmacro

%macro  _i 0
        pushrbx
        mov     rbx, [rsp]
        add     rbx, [rsp + BYTES_PER_CELL]
%endmacro

%macro  _leave 0
        add     rsp, BYTES_PER_CELL * 2
        ret                             ; same as jumping to %1_exit
%endmacro

%macro  _unloop 0
        add     rsp, BYTES_PER_CELL * 3
%endmacro
