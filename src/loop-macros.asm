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

%macro  _register_do_range 1            ; limit start-index --
        %define count_register  r12
        %define index_register  r13
        mov     rax, [rbp]
        sub     rax, rbx                ; count in rax
        jg      %1_ok
        ; not ok
        _2drop
        jmp     %1_exit2
%1_ok:
        push    count_register
        push    index_register
        mov     count_register, rax
        mov     index_register, rbx
        _2drop
        align   DEFAULT_CODE_ALIGNMENT
%1_top:
%endmacro

%macro  _register_do_times 1            ; count --
        %define count_register  r12
        %define index_register  r13
        test    rbx, rbx
        jg      %1_ok                   ; count must be > 0
        ; not ok
        _drop
        jmp     %1_exit2
%1_ok:
        push    count_register
        push    index_register
        mov     count_register, rbx
        xor     index_register, index_register
        _drop
        align   DEFAULT_CODE_ALIGNMENT
%1_top:
%endmacro

%macro  _register_loop 1
        add     index_register, 1
        sub     count_register, 1
        jnz     %1_top
%1_exit:
        pop     index_register
        pop     count_register
%1_exit2:
        %undef  count_register
        %undef  index_register
%endmacro

%macro  _register_raw_loop_index 0      ; -- untagged-index
        _dup
        mov     rbx, index_register
%endmacro

%macro  _register_loop_leave 1
        jmp     %1_exit
%endmacro

%macro  _register_loop_unloop 0
        pop     index_register
        pop     count_register
%endmacro

%macro  _?do 1                          ; limit start-index --
        mov     rax, [rbp]              ; limit in rax, start index in rbx
        sub     rax, rbx                ; number of iterations in rax
        jg      %1_ok
        _2drop
        jmp     %1_exit
%1_ok:
        push    rax                     ; r: -- limit
        push    rbx                     ; r: -- limit start-index
        _2drop
        align   DEFAULT_CODE_ALIGNMENT
%1_top:
%endmacro

%macro  _do 1                           ; limit start-index --
        _?do    %1
%endmacro

%macro  _do_times 1                     ; count --
        test    rbx, rbx
        jg      %1_ok                   ; count must be > 0
        ; nothing to do
        _drop
        jmp     %1_exit
%1_ok:
        push    rbx                     ; r: -- limit
        push    0                       ; r: -- limit start-index
        _drop
        align   DEFAULT_CODE_ALIGNMENT
%1_top:
%endmacro

%macro  _loop 1
%ifdef index_register
        _register_loop  %1
%else
        add     qword [rsp], 1
        sub     qword [rsp + BYTES_PER_CELL], 1
        jnz     %1_top
        add     rsp, BYTES_PER_CELL * 2
%1_exit:
%endif
%endmacro

%macro  _raw_loop_index 0               ; -- untagged-index
%ifdef index_register
        _register_raw_loop_index
%else
        _dup
        mov     rbx, [rsp]
%endif
%endmacro

%macro  _tagged_loop_index 0            ; -- tagged-index
        _raw_loop_index
        _tag_fixnum
%endmacro

; DEPRECATED
%macro  _i 0                            ; -- untagged-index
%ifdef index_register
        _register_raw_loop_index
%else
        _dup
        mov     rbx, [rsp]
%endif
%endmacro

%macro  _leave 1
%ifdef index_register
        _register_loop_leave %1
%else
        add     rsp, BYTES_PER_CELL * 2
        jmp     %1_exit
%endif
%endmacro

%macro  _unloop 0
%ifdef index_register
        _register_loop_unloop
%else
        add     rsp, BYTES_PER_CELL * 2
%endif
%endmacro
