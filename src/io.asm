; Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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

; ### errno
value os_errno, 'errno', 0

extern os_key

; ### key
code key, 'key'
        xcall   os_key
        pushd   rax
        next
endcode

extern os_key_avail

; ### key?
code key?, 'key?'
        xcall   os_key_avail
        pushd   rax
        next
endcode

; ### #rows
value nrows, '#rows', 0

; ### #cols
value ncols, '#cols', 0

; ### #out
value nout, '#out', 0

; For Windows, the Forth standard handles are initialized in prep_terminal().
; The values here are correct for Linux.

; ### stdin
value forth_stdin,  'stdin',  0

; ### stdout
value forth_stdout, 'stdout', 1

; ### stderr
value forth_stderr, 'stderr', 2

; For Windows, OUTPUT-FILE is initialized by calling STANDARD-OUTPUT in COLD.

; ### output-file
value output_file, 'output-file', 1

; ### standard-output
code standard_output, 'standard-output'
%ifndef WINDOWS_UI
        _ forth_stdout
        _to output_file
%endif
        next
endcode

; ### (emit)
code iemit, '(emit)'
        cmp     rbx, 10
        je      .1
        inc     qword [nout_data]
        jmp     .2
.1:
        xor     eax, eax
        mov     [nout_data], rax
.2:
        _ output_file
        _ emit_file
        next
endcode

%ifdef WINDOWS_UI
extern c_emit
; ### wemit
code wemit, 'wemit'                     ; char --
        popd    rcx
        xcall   c_emit
        next
endcode
; ### emit
deferred emit, 'emit', wemit
%else
; ### emit
deferred emit, 'emit', iemit
%endif

extern os_emit_file

; ### emit-file
code emit_file, 'emit-file'             ; char fileid --
%ifdef WIN64
        popd    rdx
        popd    rcx
%else
        popd    rsi
        popd    rdi
%endif
        xcall   os_emit_file
        next
endcode

; ### (type)
code itype, '(type)'                    ; addr n --
        add     [nout_data], rbx
        _ output_file
        _ write_file
        _lit -75
        _ ?throw
        next
endcode

%ifdef WINDOWS_UI
extern c_type
; ### wtype
code wtype, 'wtype'                     ; addr n --
        popd    rdx
        popd    rcx
        xcall   c_type
        next
endcode
; ### type
deferred type, 'type', wtype
%else
; ### type
deferred type, 'type', itype
%endif

; ### cr
code cr, 'cr'
%ifdef WIN64
        _lit 13
        _ emit
%endif
        _lit 10
        _ emit
        next
endcode

; ### ?cr
code ?cr, '?cr'
        mov     rax, [nout_data]
        test    rax, rax
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

section .data
spaces_data:
        times 256 db ' '

; ### spaces
code spaces, 'spaces'                   ; n --
; CORE "If n is greater than zero, display n spaces."
        _dup
        _lit 256
        _ ult
        _if .0
        pushd   spaces_data
        _swap
        _ type
        _return
        _then .0

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
        _ minus
        _lit 1
        _ max
        _ spaces
        next
endcode

%ifdef WINDOWS_UI
extern c_repaint
; ### repaint
code repaint, 'repaint'
        popd    rcx
        xcall   c_repaint
        next
endcode
%endif

; ### bin
code bin, 'bin', IMMEDIATE
; FILE
; "Modify the implementation-defined file access method fam1 to
; additionally select a 'binary', i.e., not line oriented, file
; access method, giving access method fam2."
        ; nothing to do
        next
endcode

extern os_file_status

; ### file-status
code file_status, 'file-status'         ; c-addr u -- x ior
; FILE EXT
; "If the file exists, ior is zero; otherwise ior is the implementation-defined I/O result code."
        _ as_c_string
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_file_status
        or      rax, rax
        jnz      .1
        pushd   rax
        pushd   rax
        next
.1:
        _zero
        _lit -1
        next
endcode

extern os_file_is_directory

; ### file-is-directory?
code file_is_directory, 'file-is-directory?' ; c-addr u -- -1 | 0
        _ as_c_string
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_file_is_directory
        test    rax, rax
        jz      .1
        mov     rax, -1
.1:
        pushd   rax
        next
endcode

; ### file-exists?
code file_exists, 'file-exists?'        ; c-addr u -- -1 | 0
        _ file_status
        _nip
        _zeq
        next
endcode

extern os_open_file

; ### (open-file)
code iopen_file, '(open-file)'          ; zaddr fam -- fileid ior
%ifdef WIN64
        popd    rdx                     ; fam in rdx
        popd    rcx                     ; zaddr in rcx
%else
        popd    rsi                     ; fam in rsi
        popd    rdi                     ; zaddr in rdi
%endif
        xcall   os_open_file
        test    rax, rax
        js      .1
        pushd   rax                     ; fileid
        pushd   0                       ; ior
        next
.1:
        ; error
        _ os_errno
        _ forth_strerror
        _to msg
        _lit -1                         ; "fileid is undefined"
        _lit -1                         ; error!
        next
endcode

; ### open-file
code open_file, 'open-file'             ; c-addr u fam -- fileid ior
; FILE
        _tor
        _ as_c_string
        _rfrom
        _ iopen_file
        next
endcode

extern os_create_file

; ### create-file
code create_file, 'create-file'         ; c-addr u fam -- fileid ior
        _tor
        _ as_c_string
        _rfrom
%ifdef WIN64
        popd    rdx                     ; fam in rdx
        popd    rcx                     ; zaddr in rcx
%else
        popd    rsi                     ; fam in rsi
        popd    rdi                     ; zaddr in rdi
%endif
        xcall   os_create_file
        test    rax, rax
        js      .1
        pushd   rax                     ; fileid
        pushd   0                       ; ior
        next
.1:
        _lit -1                         ; "fileid is undefined"
        _lit -1                         ; error!
        next
endcode

extern os_read_file

; ### read-file
code read_file, 'read-file'             ; c-addr u1 fileid -- u2 ior
%ifdef WIN64
        popd    rcx                     ; fileid
        popd    r8                      ; u1
        popd    rdx                     ; c-addr
%else
        popd    rdi
        popd    rdx
        popd    rsi
%endif
        xcall   os_read_file
        test    rax, rax
        js      .1
        pushd   rax                     ; u2
        pushd   0                       ; ior
        next
.1:
        _ os_errno
        _ forth_strerror
        _to msg
        _lit -1
        _lit -70                        ; error!
        next
endcode

extern os_read_char

; ### read-char
code read_char, 'read-char'             ; fileid -- char | -1
%ifdef WIN64
        mov     rcx, rbx                ; fileid
%else
        mov     rdi, rbx
%endif
        xcall   os_read_char
        mov     rbx, rax
        next
endcode

; ### last-char
code last_char, 'last-char'             ; c-addr u -- char
        test    rbx, rbx
        jz .1
        _plus
        _oneminus
        _cfetch
        next
.1:
        _nip                            ; return 0 if no chars
        next
endcode

; ### read-line
code read_line, 'read-line'             ; bufaddr bufsize fileid -- u flag ior

; locals:
%define fileid  local0
%define bufaddr local1
%define bufsize local2
%define filepos local3

        _locals_enter
        popd    fileid
        popd    bufsize
        popd    bufaddr

        pushd   fileid
        _ file_position
        _ throw
        _dtos
        popd    filepos

        pushd   bufaddr
        pushd   bufsize
        pushd   fileid
        _ read_file                     ; -- #bytes-read ior
        _ throw                         ; -- #bytes-read
        test    rbx, rbx
        jnz .1
        ; rbx = 0, end of file
        mov     [rbp - BYTES_PER_CELL], rbx
        mov     [rbp - BYTES_PER_CELL * 2], rbx
        lea     rbp, [rbp - BYTES_PER_CELL * 2] ; -- 0 0 0
        jmp     .exit
.1:                                     ; -- #bytes-read
        pushd   bufaddr
        _swap
        _lit 10
        _ scan                          ; -- addr u
        _if .2
        ; found lf                      ; -- addr
        sub     rbx, bufaddr            ; -- u
        pushd   filepos                 ; -- u filepos
        add     rbx, [rbp]              ; -- u filepos+u
        _oneplus                        ; advance past linefeed
        _stod
        pushd   fileid
        _ reposition_file
        _ throw                         ; -- u

        ; check for cr preceding lf
        pushd bufaddr                   ; -- u bufaddr
        _over                           ; -- u bufaddr u
        _ last_char                     ; -- u char
        cmp     rbx, 13
        poprbx                          ; -- u
        jnz     .3
        _oneminus
.3:
        _else .2
        sub     rbx, bufaddr            ; -- u
        _then .2

        _true
        _zero
.exit:
        _locals_leave
        next

%undef fileid
%undef bufaddr
%undef bufsize
%undef filepos

endcode

extern os_write_file

; ### write-file
code write_file, 'write-file'           ; c-addr u1 fileid -- ior
%ifdef WIN64
        popd    rcx                     ; fileid
        popd    r8                      ; u1
        popd    rdx                     ; c-addr
%else
        popd    rdi
        popd    rdx
        popd    rsi
%endif
        xcall   os_write_file
        or      rax, rax
        js      .1
        pushd   0                       ; ior
        next
.1:
        _lit -1                         ; error!
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
        _lit 2
%else
        _lit lf
        _lit 1
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
%else
        popd    rdi
%endif
        xcall   os_close_file
        pushd   rax
        next
endcode

extern os_file_size

; ### file-size
code file_size, 'file-size'             ; fileid -- ud ior
; FILE
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_file_size
        test    rax, rax
        js      .1
        pushd   rax                     ; ud
        _ stod
        pushd   0                       ; ior
        next
.1:
        _lit -1                         ; "ud is undefined if ior is non-zero."
        _ stod
        _lit -1                         ; error!
        next
endcode

extern os_file_position

; ### file-position
code file_position, 'file-position'     ; fileid -- ud ior
; FILE
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_file_position
        mov     rbx, rax
        test    rbx, rbx
        js      .1
        _ stod                          ; -- ud
        pushd   0                       ; -- ud ior
        next
.1:
        _lit -1                         ; "ud is undefined if ior is non-zero"
        _lit -1                         ; error!
        next
endcode

extern os_reposition_file

; ### reposition-file
code reposition_file, 'reposition-file' ; ud fileid -- ior
; We ignore the upper 64 bits of the 128-bit offset.
%ifdef WIN64
        mov     rcx, rbx                        ; fileid in RCX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; 64-bit offset in RDX
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%else
        mov     rdi, rbx                        ; fileid
        mov     rsi, [rbp + BYTES_PER_CELL]     ; 64-bit offset
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endif
        xcall   os_reposition_file
        test    rax, rax
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
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%else
        mov     rdi, rbx                        ; fileid
        mov     rsi, [rbp + BYTES_PER_CELL]     ; 64-bit offset
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endif
        xcall   os_resize_file
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
        _ as_c_string
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_delete_file
        mov     ebx, eax
        next
endcode

extern os_rename_file

; ### rename-file
code rename_file, 'rename-file'         ; c-addr1 u1 c-addr2 u2 -- ior
        ; -- old new
        _ as_c_string                   ; new name
        _ rrot
        _ as_c_string                   ; old name
        ; -- new old
%ifdef WIN64
        popd    rcx                     ; old name
        popd    rdx                     ; new name
%else
        popd    rdi                     ; old name
        popd    rsi                     ; new name
%endif
        xcall   os_rename_file
        pushrbx
        mov     rbx, rax
        next
endcode

extern os_flush_file

; ### flush-file
code flush_file, 'flush-file'           ; fileid -- ior
; FILE EXT
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_flush_file
        mov     rbx, rax
        next
endcode

extern os_ms

; ### ms
code ms, 'ms'
; FACILITY EXT
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_ms
        next
endcode

extern os_system

; ### system
code system_, 'system'                  ; c-addr u --
        _ as_c_string
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_system
        next
endcode

; ### sh
code sh, 'sh'
        _lit 10
        _ parse
        _ ?dup
        _if .1
        _ system_
        _else .1
        _drop
        _then .1
        next
endcode

extern os_getenv

; ### getenv
code getenv_, 'getenv'                  ; c-addr1 u1 -- c-addr2 u2
        _ as_c_string
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_getenv
        pushd   rbx
        mov     rbx, rax
        pushd   rbx
        test    rbx, rbx
        jz      .1
        _ zstrlen
        next
.1:
        xor     ebx, ebx
        next
endcode

extern os_getcwd

; ### get-current-directory
code get_current_directory, 'get-current-directory'
; c-addr u -- c-addr
%ifdef WIN64
        popd    rdx
        popd    rcx
%else
        popd    rsi
        popd    rdi
%endif
        xcall   os_getcwd
        pushd   rax
        next
endcode

; ### current-directory
code current_directory, 'current-directory'     ; -- $addr
        _ tempstring
        _dup
        _oneplus                        ; skip over count byte
        _lit 255
        _ get_current_directory
        _ zstrlen
        _over
        _ cstore                        ; count byte
        next
endcode

extern os_chdir

; ### set-current-directory
code set_current_directory, 'set-current-directory'     ; $addr -- flag
; returns true on success, 0 on failure
        _string_to_zstring
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_chdir
        mov     rbx, rax
        next
endcode

; ### cd
code cd, 'cd'
        _ blword
        _dupcfetch
        _if .1
        _ tilde_expand_filename
        _ set_current_directory
        _drop
        _else .1
        _drop
        _ current_directory
        _ counttype
        _then .1
        next
endcode

section .data
feline_home_data:
%strlen len     FELINE_HOME
        db      len
        db      FELINE_HOME
        db      0

; ### feline-home
code feline_home, 'feline-home'         ; -- $addr
        pushrbx
        mov     ebx, feline_home_data   ; assumes 32-bit address
        next
endcode

extern os_realpath

; ### canonical-path
code canonical_path, 'canonical-path'   ; string1 -- string2
        _ string_data                   ; -- zaddr1
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_realpath
        pushd   rax                     ; -- zaddr2
        _ dup
        _ zcount
        _ copy_to_transient_string      ; -- string2
        _ swap
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_free
        poprbx
        next
endcode

extern os_strerror

; ### strerror
code forth_strerror, 'strerror'         ; n -- c-addr u
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_strerror
        pushd   rax
        _ zcount
        _ copy_to_temp_string
        next
endcode

extern os_time_and_date

; ### time&date
code itime_and_date, 'time&date'
; FACILITY EXT
        _ tempstring                    ; -- buffer
        _duptor
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall os_time_and_date
        _rfetch                         ; -- buffer
        _lfetch                         ; -- sec
        _rfetch
        mov     ebx, [rbx + 4]          ; -- sec min
        _rfetch
        mov     ebx, [rbx + 8]          ; -- sec min hour
        _rfetch
        mov     ebx, [rbx + 12]         ; -- sec min hour day
        _rfetch
        mov     ebx, [rbx + 16]
        add     ebx, 1                  ; -- sec min hour day month
        _rfrom
        mov     ebx, [rbx + 20]
        add     ebx, 1900               ; -- sec min hour day month year
        next
endcode
