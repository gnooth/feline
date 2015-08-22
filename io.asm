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

extern os_key

; ### key
code key, 'key'
%ifdef WIN64
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%endif
        xcall   os_key
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        pushd   rax
        next
endcode

extern os_key_avail

; ### key?
code key?, 'key?'
%ifdef WIN64
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%endif
        xcall   os_key_avail
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        pushd   rax
        next
endcode

extern os_emit

; ### (emit)
code paren_emit, '(emit)'
%ifdef WIN64
        popd    rcx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        popd    rdi
%endif
        xcall    os_emit
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        next
endcode

variable nout, '#out', 0

; ### emit
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

; ### type
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

; ### cr
code cr, 'cr'
        _lit 10
        _ emit
        next
endcode

; ### ?cr
code ?cr, '?cr'
        mov     rax, [nout_data]
        or      rax, rax
        jz     .1
        _ cr
.1:
        next
endcode

; ### space
code space, 'space'                     ; --
; CORE
        _lit ' '
        _ emit
        next
endcode

; ### spaces
code spaces, 'spaces'                   ; n --
; CORE "If n is greater than zero, display n spaces."
        popd    rcx
        test    rcx, rcx
        jle     .2
.1:
        push    rcx
        _ space
        pop     rcx
        loop    .1
.2:
        next
endcode

; ### backspaces
code backspaces, 'backspaces'           ; n --
        popd    rcx
        test    rcx, rcx
        jle     .2
.1:
        push    rcx
        _lit 8
        _ emit
        pop     rcx
        loop    .1
.2:
        next
endcode

; ### >pos
code topos, '>pos'                      ; +n --
        _ nout
        _fetch
        _ minus
        _ one
        _ max
        _ spaces
        next
endcode

; ### r/o
code readonly, 'r/o'                    ; -- 0
        pushrbx
%ifdef WIN64_NATIVE
        mov     ebx, GENERIC_READ
%else
        mov     ebx, 0
%endif
        next
endcode

; ### w/o
code writeonly, 'w/o'                   ; -- 1
        pushrbx
%ifdef WIN64_NATIVE
        mov     ebx, GENERIC_WRITE
%else
        mov     ebx, 1
%endif
        next
endcode

; ### r/w
code readwrite, 'r/w'                   ; -- 2
        pushrbx
%ifdef WIN64_NATIVE
        mov     ebx, GENERIC_READ|GENERIC_WRITE
%else
        mov     ebx, 2
%endif
        next
endcode

; ### bin
code bin, 'bin', IMMEDIATE
        next
endcode

extern os_file_status

; ### file-status
code file_status, 'file-status'         ; c-addr u -- x ior
; "If the file exists, ior is zero; otherwise ior is the implementation-defined I/O result code."
        _ here                          ; FIXME use $buf
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
        xcall   os_file_status
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

extern os_file_is_directory

; ### file-is-directory?
code file_is_directory, 'file-is-directory?' ; c-addr u -- -1 | 0
        _ here
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
        xcall   os_file_is_directory
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        test    rax, rax
        jz      .1
        mov     rax, -1
.1:
        pushd   rax
        next
endcode

; ### file-exists?
code file_exists, 'file-exists?'
        _ file_status
        _nip
        _zeq
        next
endcode

; ### open-file
code open_file, 'open-file'             ; c-addr u fam -- fileid ior
; FILE
        _tor
        _ to_stringbuf
        _ string_to_zstring
        _rfrom
        _ paren_open_file
        next
endcode

extern os_open_file

; ### (open-file)
code paren_open_file, '(open-file)'     ; zaddr fam -- fileid ior
%ifdef WIN64
        popd    rdx
        popd    rcx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        popd    rsi
        popd    rdi
%endif
        xcall   os_open_file
%ifdef WIN64
        add     rsp, 32
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

extern os_create_file

; ### create-file
code create_file, 'create-file'         ; c-addr u fam -- fileid ior
        _ rrot                          ; -- fam c-addr u
        _ here                          ; FIXME use $buf
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
        xcall   os_create_file
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

extern os_read_file

; ### read-file
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
        xcall    os_read_file
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

extern os_read_char

; ### read-char
code read_char, 'read-char'             ; fileid -- char | -1
%ifdef WIN64
        mov     rcx, rbx                ; fileid
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 0x28
%else
        mov     rdi, rbx
%endif
        xcall    os_read_char
%ifdef WIN64
        add     rsp, 0x28
        pop     rbp
%endif
        mov     rbx, rax
        next
endcode

; ### last-char
code last_char, 'last-char'             ; c-addr u -- char
        _ ?dup
        _if last_char1
        _ plus
        _oneminus
        _cfetch
        _else last_char1
        _ drop
        _ zero
        _then last_char1
        next
endcode

; ### read-line
code read_line, 'read-line'             ; c-addr u1 fileid -- u2 flag ior
        _ rrot                          ; -- fileid c-addr u1
        _ ?dup
        _if read_line1
        _duptor                         ; -- fileid c-addr u1           r: -- u1
        _ rrot                          ; -- u1 fileid c-addr
        _rfrom                          ; -- u1 fileid c-addr u1        r: --
        _ zero
        _do read_line2                  ; -- u1 fileid c-addr
        _ over                          ; -- u1 fileid c-addr fileid
        _ read_char                     ; -- u1 fileid c-addr [ char | -1 ]
        _dup
        _zlt
        _if read_line3                  ; -- u1 fileid c-addr [ char | -1 ]
        ; end of file
        _ fourdrop                      ; --
        _i
        _dup
        _ zne                           ; false flag if i = 0
        _ zero
        _unloop
        _return
        _then read_line3
        _dup
        _lit 10
        _ equal
        _if read_line4
        ; end of line                   ; -- u1 fileid c-addr 10
        _ drop                          ; -- u1 fileid c-addr
        _ rrot                          ; -- c-addr u1 fileid
        _ twodrop                       ; -- c-addr
        _i                              ; -- c-addr i
        _ last_char                     ; -- char
        _lit 13
        _ equal
        _if read_line5                  ; CR precedes LF
        _i
        _oneminus
        _else read_line5                ; no CR
        _i
        _then read_line5
        _ true
        _ zero
        _unloop
        _return
        _then read_line4
        _ over                          ; -- u1 fileid c-addr char c-addr
        _i
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

extern os_write_file

; ### write-file
code write_file, 'write-file'           ; c-addr u1 fileid -- ior
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
        xcall    os_write_file
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

section .data
crlf:
        db      13
lf:
        db      10

; ### write-line
code write_line, 'write-line'           ; c-addr u1 fileid -- ior
        _duptor
        _ write_file                    ; -- ior        r: -- fileid
%ifdef WIN64
        _lit crlf
        _ two
%else
        _lit lf
        _ one
%endif
        _ rfrom
        _ write_file                    ; -- ior ior'
        _ or
        next
endcode

extern os_close_file

; ### close-file
code close_file, 'close-file'           ; fileid -- ior
%ifdef WIN64
        popd    rcx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        popd    rdi
%endif
        xcall    os_close_file
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        pushd   rax
        next
endcode

extern os_file_size

; ### file-size
code file_size, 'file-size'             ; fileid -- ud ior
; FILE
%ifdef WIN64
        popd    rcx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        popd    rdi
%endif
        xcall    os_file_size
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
        _ minusone                      ; "ud is undefined if ior is non-zero."
        _ stod
        _ minusone                      ; error!
        next
endcode

extern os_file_position

; ### file-position
code file_position, 'file-position'     ; fileid -- ud ior
; FILE
%ifdef WIN64
        mov     rcx, rbx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        mov     rdi, rbx
%endif
        xcall    os_file_position
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        mov     rbx, rax
        test    rbx, rbx
        js      .1
        _ stod                          ; -- ud
        pushd   0                       ; -- ud ior
        next
.1:
        _ minusone                      ; "ud is undefined if ior is non-zero"
        _ minusone                      ; error!
        next
endcode

extern os_reposition_file

; ### reposition-file
code reposition_file, 'reposition-file' ; ud fileid -- ior
; We ignore the upper 64 bits of the 128-bit offset.
%ifdef WIN64
        mov     rcx, rbx                        ; fileid in RCX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; 64-bit offset in RDX
        add     rbp, BYTES_PER_CELL * 2
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        mov     rdi, rbx                        ; fileid
        mov     rsi, [rbp + BYTES_PER_CELL]     ; 64-bit offset
        add     rbp, BYTES_PER_CELL * 2
%endif
        xcall    os_reposition_file
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        or      rax, rax
        js      .1
        xor     rbx, rbx                ; success
        next
.1:
        mov     rbx, -1                 ; error
        next
endcode

extern os_resize_file

; ### resize-file
code resize_file, 'resize-file'         ; ud fileid -- ior
; We ignore the upper 64 bits of the 128-bit offset.
%ifdef WIN64
        mov     rcx, rbx                        ; fileid in RCX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; 64-bit offset in RDX
        add     rbp, BYTES_PER_CELL * 2
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        mov     rdi, rbx                        ; fileid
        mov     rsi, [rbp + BYTES_PER_CELL]     ; 64-bit offset
        add     rbp, BYTES_PER_CELL * 2
%endif
        xcall    os_resize_file
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        or      rax, rax
        js      .1
        xor     rbx, rbx                ; success
        next
.1:
        mov     rbx, -1                 ; error
        next
endcode

extern os_delete_file

; ### delete-file
code delete_file, 'delete-file'         ; c-addr u -- ior
        _ here
        _ zplace
        _ here
%ifdef WIN64
        mov     rcx, rbx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        mov     rdi, rbx
%endif
        xcall    os_delete_file
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        mov     ebx, eax
        next
endcode

extern os_rename_file

; ### rename-file
code rename_file, 'rename-file'         ; c-addr1 u1 c-addr2 u2 -- ior
        sub     rsp, ((MAX_PATH + 16) & $1f0) * 2
        pushrbx
        mov     rbx, rsp                ; new name
        _ zplace                        ; -- c-addr1 u1
        pushrbx
        lea     rbx, [rsp + MAX_PATH]   ; old name
        _ zplace                        ; --
%ifdef WIN64
        lea     rcx, [rsp + MAX_PATH]   ; old name
        mov     rdx, rsp                ; new name
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        lea     rdi, [rsp + MAX_PATH]   ; old name
        mov     rsi, rsp                ; new name
%endif
        xcall    os_rename_file
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        pushrbx
        mov     rbx, rax
        add     rsp, ((MAX_PATH + 16) & $1f0) * 2
        next
endcode

extern os_flush_file

; ### flush-file
code flush_file, 'flush-file'           ; fileid -- ior
; FILE EXT
%ifdef WIN64
        mov     rcx, rbx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        mov     rdi, rbx
%endif
        xcall    os_flush_file
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        mov     rbx, rax
        next
endcode

extern os_ms

; ### ms
code ms, 'ms'
; FACILITY EXT
%ifdef WIN64
        popd    rcx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        popd    rdi
%endif
        xcall   os_ms
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        next
endcode

extern os_system

; ### system
code system_, 'system'                  ; c-addr u --
        _ here                          ; FIXME use $buf
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
        xcall   os_system
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        next
endcode

extern os_getenv

; ### getenv
code getenv_, 'getenv'                  ; c-addr1 u1 -- c-addr2 u2
        _ here
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
        xcall   os_getenv
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        pushd   rbx
        mov     rbx, rax
        pushd   rbx
        test    rbx, rbx
        jz      .1
        call    zstrlen
        next
.1:
        xor     ebx, ebx
        next
endcode

extern os_getcwd

; ### getcwd
code getcwd_, 'getcwd'
%ifdef WIN64
        popd    rdx
        popd    rcx
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%else
        popd    rsi
        popd    rdi
%endif
        xcall   os_getcwd
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        pushd   rax
        next
endcode

extern os_forth_home

; ### forth-home
code forth_home, 'forth-home'          ; -- zaddr
%ifdef WIN64
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%endif
        xcall   os_forth_home
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        pushd   rax
        next
endcode
