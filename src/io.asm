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

; ### errno
value os_errno, 'errno', 0

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

; ### path-is-directory?
code path_is_directory?, 'path-is-directory?' ; string -- flag
        _ verify_string
        _ string_raw_data_address
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_file_is_directory
        test    rax, rax
        jz      .1
        mov     rax, -1
.1:
        mov     rbx, rax
        next
endcode

; ### path-file-exists?
code path_file_exists?, 'path-file-exists?' ; string -- ?
        _ string_from
        _ file_status
        _nip
        _zeq
        _tag_boolean
        next
endcode

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

; ### get-environment-variable
code get_environment_variable, 'get-environment-variable' ; name -- value
        _ string_raw_data_address
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
        jmp     .2
.1:
        xor     ebx, ebx
.2:
        _ copy_to_string
        next
endcode

; ### errno-to-string
code errno_to_string, 'errno-to-string' ; n -- string
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_strerror
        mov     rbx, rax
        _ zcount
        _ copy_to_string
        next
endcode
