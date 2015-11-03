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

%define DEBUG_MEMORY    0

%if DEBUG_MEMORY
value bytes_allocated, 'bytes-allocated', 0
value bytes_freed, 'bytes-freed', 0
%endif

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

; ### -allocate
code iallocate, '-allocate'             ; size -- a-addr
; A version of ALLOCATE that returns the address of the allocated space if
; the allocation is successful and otherwise calls THROW with the numeric
; code specified by Forth 2012.
%if DEBUG_MEMORY > 1
        _ ?cr
        _dotq "-ALLOCATE "
        _ dup
        _ decdot
%endif
%if DEBUG_MEMORY
        push    rbx
        add     [bytes_allocated_data], rbx
        add     rbx, 16
%endif
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
%if DEBUG_MEMORY
        pop     rax                     ; size
        mov     [rbx], rax
        add     rbx, 16
%endif
        _return
.1:
%if DEBUG_MEMORY
        pop     rbx
%endif
        ; failed!
        mov     rbx, -59                ; Forth 2012 Table 9.1
        _ throw
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
%if DEBUG_MEMORY
        sub     rbx, 16
        mov     rax, [rbx]              ; size
        add     [bytes_freed_data], rax
%endif
%if DEBUG_MEMORY > 1
        pushd  rax
        _ ?cr
        _dotq "-FREE "
        _ decdot
%endif
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_free                 ; "The free() function returns no value."
        poprbx
        next
endcode

; ### report-allocations
code report_allocations, 'report-allocations'
%if DEBUG_MEMORY
        _dotq "["
        _ bytes_allocated
        _ decdot
        _dotq "bytes allocated, "
        _ bytes_freed
        _ decdot
        _dotq "bytes freed, "
        _ bytes_allocated
        _ bytes_freed
        _ minus
        _ decdot
        _dotq "bytes not freed]"
%endif
        next
endcode
