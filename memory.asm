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
        _ dup
        _if .1
        _zero                          ; success
        _else .1
        ; failed!
        _lit -59                        ; THROW code (Forth 2012 Table 9.1)
        _then .1
        next
endcode

extern os_free

; ### free
code free_, 'free'                      ; a-addr -- ior
; MEMORY
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_free
        xor     ebx, ebx                ; ior
        next
endcode
