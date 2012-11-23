; Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

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

extern c_key

code key, 'key'
%ifdef WIN64
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%endif
        call    c_key
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        pushd   rax
        next
endcode

extern c_emit

code paren_emit, '(emit)'
%ifdef WIN64
        popd    rcx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        popd    rdi
%endif
        call    c_emit
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        next
endcode

variable nout, '#out', 0

code emit, 'emit'
        cmp     rbx, 10
        je      .1
        inc     qword [nout_data]
        jmp     .2
.1:
        xor     eax, eax
        mov     [nout_data], eax
.2:
        jmp    paren_emit
endcode

code type, 'type'                       ; addr n --
        mov     rcx, rbx                ; count in rcx
        mov     rdx, [rbp]              ; addr in rdx
        add     rbp, BYTES_PER_CELL
        mov     rbx, [rbp]
        add     rbp, BYTES_PER_CELL
        jrcxz   .2
.1:
        movzx   rax, byte [rdx]
        pushd   rax
        push    rcx
        push    rdx
        _ emit
        pop     rdx
        pop     rcx
        inc     rdx
        loop    .1
.2:
        next
endcode

code cr, 'cr'
        _lit 10
        _ emit
        next
endcode

code ?cr, '?cr'
        mov     rax, [nout_data]
        or      rax, rax
        jz     .1
        _ cr
.1:
        next
endcode

code space, 'space'                     ; --
; CORE
        _lit ' '
        _ emit
        next
endcode

code spaces, 'spaces'                   ; n --
; CORE "If n is greater than zero, display n spaces."
        popd    rcx
        or      rcx, rcx
        jle     .2
.1:
        push    rcx
        _ space
        pop     rcx
        loop    .1
.2:
        next
endcode

code topos, '>pos'                      ; +n --
        _ nout
        _ fetch
        _ minus
        _ one
        _ max
        _ spaces
        next
endcode

code readonly, 'r/o'                    ; -- 0
        pushrbx
        xor     ebx, ebx
        next
endcode

code writeonly, 'w/o'                   ; -- 1
        pushrbx
        mov     ebx, 1
        next
endcode

code readwrite, 'r/w'                   ; -- 2
        push rbx
        mov     ebx, 2
        next
endcode

extern c_file_status

code file_status, 'file-status'         ; c-addr u -- x ior
; "If the file exists, ior is zero; otherwise ior is the implementation-defined I/O result code."
        _ here                          ; FIXME use syspad or something similar
        _ zplace
        _ here
%ifdef WIN64
        popd    rcx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        popd    rdi
%endif
        call    c_file_status
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        or      rax, rax
        jnz      .1
        pushd   rax
        pushd   rax
        next
.1:
        _ zero
        _ minusone
        next
endcode

extern c_open_file

code open_file, 'open-file'             ; c-addr u fam -- fileid ior
        _ rrot                          ; -- fam c-addr u
        _ here                          ; FIXME use syspad or something similar
        _ zplace                        ; -- fam
        _ here                          ; -- fam here
        _ swap                          ; -- here fam
%ifdef WIN64
        popd    rdx
        popd    rcx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 0x28
%else
        popd    rsi
        popd    rdi
%endif
        call    c_open_file
%ifdef WIN64
        add     rsp, 0x28
        pop     rbp
%endif
        or      rax, rax
        js      .1
        pushd   rax                     ; fileid
        pushd   0                       ; ior
        next
.1:
        _ minusone                      ; "fileid is undefined"
        _ minusone                      ; error!
        next
endcode

extern c_read_file

code read_file, 'read-file'             ; c-addr u1 fileid -- u2 ior
%ifdef WIN64
        popd    rcx                     ; fileid
        popd    r8                      ; u1
        popd    rdx                     ; c-addr
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 0x28
%else
        popd    rdi
        popd    rdx
        popd    rsi
%endif
        call    c_read_file
%ifdef WIN64
        add     rsp, 0x28
        pop     rbp
%endif
        or      rax, rax
        js      .1
        pushd   rax                     ; u2
        pushd   0                       ; ior
        next
.1:
        _ minusone
        _ minusone                      ; error!
        next
endcode

extern c_read_char

code read_char, 'read-char'             ; fileid -- char | -1
%ifdef WIN64
        popd    rcx                     ; fileid
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 0x28
%else
        popd    rdi
%endif
        call    c_read_char
%ifdef WIN64
        add     rsp, 0x28
        pop     rbp
%endif
        pushd   rax
        next
endcode

code read_line, 'read-line'             ; c-addr u1 fileid -- u2 flag ior
        _ rrot                          ; -- fileid c-addr u1
        _ ?dup
        _if read_line1
        _ dup                           ; -- fileid c-addr u1 u1
        _ tor                           ; -- fileid c-addr u1           r: u1
        _ rrot                          ; -- u1 fileid c-addr
        _ rfrom                         ; -- u1 fileid c-addr u1        r: --
        _ zero
        _do read_line2                  ; -- u1 fileid c-addr
        _ over                          ; -- u1 fileid c-addr fileid
        _ read_char                     ; -- u1 fileid c-addr [ char | -1 ]
        _ dup
        _ zlt
        _if read_line3                  ; -- u1 fileid c-addr [ char | -1 ]
        ; end of file
        _ fourdrop                      ; --
        _ i
        _ dup
        _ zne                           ; false flag if i = 0
        _ zero
        _ unloop
        _return
        _then read_line3
        _ dup
        _lit 10
        _ equal
        _if read_line4
        ; end of line
        _ fourdrop
        _ i
        _ true
        _ zero
        _ unloop
        _return
        _then read_line4
        _ over                          ; -- u1 fileid c-addr char c-addr
        _ i
        _ plus
        _ cstore                        ; -- u1 fileid c-addr
        _loop read_line2
        ; fall through
        _ twodrop                       ; -- u2
        _ true                          ; -- u2 flag
        _ zero                          ; -- u2 flag ior
        _else read_line1
        _ twodrop
        _ zero
        _ true
        _ zero
        _then read_line1
        next
endcode

extern c_write_file

code write_file, 'write-file'           ; c-addr u1 fileid -- u2 ior
%ifdef WIN64
        popd    rcx                     ; fileid
        popd    r8                      ; u1
        popd    rdx                     ; c-addr
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 0x28
%else
        popd    rdi
        popd    rdx
        popd    rsi
%endif
        call    c_write_file
%ifdef WIN64
        add     rsp, 0x28
        pop     rbp
%endif
        or      rax, rax
        js      .1
        pushd   0                       ; ior
        next
.1:
        _ minusone                      ; error!
        next
endcode

extern c_close_file

code close_file, 'close-file'           ; fileid -- ior
%ifdef WIN64
        popd    rcx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        popd    rdi
%endif
        call    c_close_file
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        pushd   rax
        next
endcode

extern c_file_size

code file_size, 'file-size'             ; fileid -- ud ior
%ifdef WIN64
        popd    rcx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        popd    rdi
%endif
        call    c_file_size
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        or      rax, rax
        js      .1
        pushd   rax                     ; ud
        _ stod
        pushd   0                       ; ior
        next
.1:
        _ minusone                      ; "fileid is undefined"
        _ minusone                      ; error!
        next
endcode
