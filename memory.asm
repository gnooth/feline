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

extern os_allocate

; ### allocate
code allocate, 'allocate'               ; u -- a-addr ior
; MEMORY
%ifdef WIN64
        mov     rcx, rbx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        mov     rdi, rbx
%endif
        xcall   os_allocate
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        mov     rbx, rax                ; -- a-addr
        _ dup
        _if allocate1
        _ zero                          ; success
        _else allocate1
        _ minusone                      ; failure
        _then allocate1
        next
endcode

extern os_free

; ### free
code free_, 'free'                      ; a-addr -- ior
; MEMORY
%ifdef WIN64
        mov     rcx, rbx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        mov     rdi, rbx
%endif
        xcall   os_free
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        xor     rbx, rbx                ; ior
        next
endcode
