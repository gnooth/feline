; Copyright (C) 2012-2019 Peter Graves <gnooth@gmail.com>

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

; ### __raw_allocate
code __raw_allocate, '__raw_allocate', SYMBOL_INTERNAL
; call with raw size in arg0_register
; returns raw address in rax
        _os_malloc
        test    rax, rax
        jz      error_out_of_memory
        next
endcode

; ### raw_allocate
code raw_allocate, 'raw_allocate', SYMBOL_INTERNAL
; raw-size -> raw-address
        mov     arg0_register, rbx
        _os_malloc
        test    rax, rax
        mov     rbx, rax
        jz      error_out_of_memory
        next
endcode

; ### raw_realloc
code raw_realloc, 'raw_realloc', SYMBOL_INTERNAL
; raw-address raw-size -> new-raw-address
        mov     arg1_register, rbx
        mov     arg0_register, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _os_realloc
        test    rax, rax
        mov     rbx, rax
        jz      error_out_of_memory
        next
endcode

; ### raw_free
code raw_free, 'raw_free', SYMBOL_INTERNAL ; raw-address -> void
        mov     arg0_register, rbx
        poprbx
        _os_free
        next
endcode

; ### raw_erase_bytes
code raw_erase_bytes, 'raw_erase_bytes', SYMBOL_INTERNAL
; raw-address raw-count --
%ifdef WIN64
        push    rdi                     ; rdi is callee-saved on Windows
%endif
        xor     al, al                  ; 0 in al
        mov     rcx, rbx                ; count in rcx
        mov     rdi, [rbp]
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        jrcxz   .1                      ; do nothing if count = 0
        rep     stosb
.1:
%ifdef WIN64
        pop     rdi
%endif
        next
endcode

; ### raw_erase_cells
code raw_erase_cells, 'raw_erase_cells', SYMBOL_INTERNAL
; raw-address raw-count --
%ifdef WIN64
        push    rdi                     ; rdi is callee-saved on Windows
%endif
        xor     eax, eax                ; 0 in rax
        mov     rcx, rbx                ; count in rcx
        mov     rdi, [rbp]
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        jrcxz   .1                      ; do nothing if count = 0

        align   DEFAULT_CODE_ALIGNMENT
.2:
        mov     [rdi], rax
        sub     rcx, 1
        jz      .1
        mov     [rdi + BYTES_PER_CELL], rax
        sub     rcx, 1
        jz      .1
        mov     [rdi + BYTES_PER_CELL * 2], rax
        sub     rcx, 1
        jz      .1
        mov     [rdi + BYTES_PER_CELL * 3], rax
        add     rdi, BYTES_PER_CELL * 4
        sub     rcx, 1
        jz      .1
        jmp     .2
.1:
%ifdef WIN64
        pop     rdi
%endif
        next
endcode
