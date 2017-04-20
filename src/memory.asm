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

; ### resize
subroutine resize                       ; addr size -- new-addr
%ifdef WIN64
        mov     rdx, rbx                ; size in rdx
        mov     rcx, [rbp]              ; addr in rcx
%else
        mov     rsi, rbx                ; size
        mov     rdi, [rbp]              ; addr
%endif
        lea     rbp, [rbp + BYTES_PER_CELL]
        xcall   os_resize
        mov     rbx, rax
        test    rbx, rbx
        jz .1
        ret
.1:
        ; failed!
        _error "resize failed"
        ret
endsub

; ### raw-allocate
code raw_allocate, 'raw-allocate'       ; raw-size -- raw-address
        mov     arg0_register, rbx
        xcall   os_malloc
        test    rax, rax
        jz .1
        ; allocation succeeded
        mov     rbx, rax
        _return
.1:
        ; failed!
        _error "allocation failed"
        next
endcode

; ### raw-free
code raw_free, 'raw-free'               ; raw-address --
        mov     arg0_register, rbx
        xcall   os_free                 ; "The free() function returns no value."
        poprbx
        next
endcode
