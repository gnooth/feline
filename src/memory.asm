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

file __FILE__

extern os_allocate

; ### allocate
code allocate, 'allocate'               ; u -- a-addr ior
; MEMORY
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_allocate
        mov     rbx, rax                ; -- a-addr
        test    rbx, rbx
        jz .1
        _zero                           ; success
        _return
.1:
        ; failed!
        _lit -59                        ; THROW code (Forth 2012 Table 9.1)
        next
endcode

extern os_resize

; ### resize
code resize, 'resize'                   ; a-addr1 u -- a-addr2 ior
%ifdef WIN64
        mov     rdx, rbx                ; u in rdx
        mov     rcx, [rbp]              ; a-addr1 in rcx
        push    rcx                     ; save a copy
%else
        mov     rsi, rbx                ; u
        mov     rdi, [rbp]              ; a-addr1
        push    rdi                     ; save a copy
%endif
        lea     rbp, [rbp + BYTES_PER_CELL]
        xcall   os_resize
        mov     rbx, rax
        pop     rdx                     ; copy of a-addr1 in rdx
        test    rbx, rbx
        jz .1
        _zero                           ; success
        _return
.1:
        ; failed!
        mov     rbx, rdx                ; a-addr2 = a-addr1
        _lit -61                        ; THROW code (Forth 2012 Table 9.1)
        next
endcode

; ### -allocate
code iallocate, '-allocate'             ; size -- a-addr
; A version of ALLOCATE that returns the address of the allocated space if
; the allocation is successful and otherwise calls THROW with the numeric
; code specified by Forth 2012.
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_allocate
        test    rax, rax
        jz .1
        ; allocation succeeded
        mov     rbx, rax                ; -- a-addr
        _return
.1:
        ; failed!
        mov     rbx, -59                ; Forth 2012 Table 9.1
        _ forth_throw
        ; not reached
        next
endcode

extern os_free

; ### free
code forth_free, 'free'                 ; a-addr -- ior
; MEMORY
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_free
        xor     ebx, ebx                ; "The free() function returns no value."
        next
endcode

; ### -free
code ifree, '-free'                     ; a-addr --
; a version of FREE that doesn't return the meaningless ior
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_free                 ; "The free() function returns no value."
        poprbx
        next
endcode

extern os_allocate_executable

; ### allocate-executable
code allocate_executable, 'allocate-executable' ; size -- addr
%ifdef WIN64
        mov     rcx, rbx
        xcall   os_allocate_executable
%else
        mov     rdi, rbx
        xcall   os_allocate
%endif
        mov     rbx, rax                ; -- addr
        next
endcode

extern os_free_executable

; ### free-executable
code free_executable, 'free-executable' ; addr --
%ifdef WIN64
        mov     rcx, rbx
        xcall   os_free_executable
%else
        mov     rdi, rbx
        xcall   os_free
%endif
        poprbx
        next
endcode
