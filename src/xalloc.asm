; Copyright (C) 2016-2020 Peter Graves <gnooth@gmail.com>

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

file __FILE__

; initialized in initialize_dynamic_code_space (in main.c)
asm_global code_space_, 0
asm_global code_space_free_, 0
asm_global code_space_limit_, 0

%define USE_XALLOC

%ifdef USE_XALLOC

; ### xalloc
code xalloc, 'xalloc'                   ; raw-size -> raw-address
        mov     rax, [code_space_free_]

        add     rbx, rax
        cmp     rbx, [code_space_limit_]
        jge     .1

        ; REVIEW
        ; 16-byte alignment
        add     rbx, 0x0f
        and     bl, 0xf0

        mov     [code_space_free_], rbx

        mov     rbx, rax
        _return

.1:
        _ ?nl
        _write "FATAL: no code space"
        _ nl
        xcall os_bye

        next
endcode

; ### xfree
code xfree, 'xfree'                     ; raw-address -> void
        ; for now, do nothing
        _drop

        next
endcode

%endif

; ### raw_allocate_executable
code raw_allocate_executable, 'raw_allocate_executable', SYMBOL_INTERNAL
; raw-size -> raw-address

%ifdef USE_XALLOC

        _ xalloc

%else

        mov     arg0_register, rbx
%ifdef WIN64
        xcall   os_allocate_executable
%else
        xcall   os_malloc
%endif
        mov     rbx, rax

%endif

        next
endcode

; ### raw_free_executable
code raw_free_executable, 'raw_free_executable', SYMBOL_INTERNAL
; raw-address -> void

%ifdef USE_XALLOC

        _ xfree

%else

        mov     arg0_register, rbx
%ifdef WIN64
        xcall   os_free_executable
%else
        xcall   os_free
%endif
        _drop

%endif

        next
endcode
