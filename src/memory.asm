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

file __FILE__

; ### raw-realloc
code raw_realloc, 'raw-realloc'         ; addr size -- new-addr
        mov     arg1_register, rbx
        mov     arg0_register, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        xcall   os_realloc
        test    rax, rax
        mov     rbx, rax
        jz .1
        _return
.1:
        _error "resize failed"
        next
endcode

; ### raw-allocate
code raw_allocate, 'raw-allocate'       ; raw-size -- raw-address
        mov     arg0_register, rbx
        xcall   os_malloc
        test    rax, rax
        mov     rbx, rax
        jz .1
        _return
.1:
        _error "allocation failed"
        next
endcode

; ### raw-free
code raw_free, 'raw-free'               ; raw-address --
        mov     arg0_register, rbx
        poprbx
        xcall   os_free
        next
endcode

; ### erase
code erase, 'erase'                     ; addr u --
; CORE EXT
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

; ### raw-erase-cells
code raw_erase_cells, 'raw-erase-cells' ; raw-address raw-count --
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
