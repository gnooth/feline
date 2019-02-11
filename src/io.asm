; Copyright (C) 2012-2019 Peter Graves <gnooth@gmail.com>

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
code delete_file, 'delete-file'         ; string -> ?
; returns t if successful, f on error
        _ string_raw_data_address
        mov     arg0_register, rbx
        xcall   os_delete_file
        mov     ebx, t_value
        mov     edx, f_value
        test    rax, rax
        cmovs   ebx, edx
        next
endcode

; ### rename-file
code rename_file, 'rename-file'         ; old-name new-name -> ?
; returns t if successful, f on error

        _ string_raw_data_address
        mov     arg1_register, rbx      ; new name
        _drop
        _ string_raw_data_address
        mov     arg0_register, rbx      ; old name

        xcall   os_rename_file          ; rax = 0 if successful, -1 on error

        mov     ebx, t_value
        mov     edx, f_value
        test    rax, rax
        cmovs   ebx, edx

        next
endcode

; ### run-shell-command
code run_shell_command, 'run-shell-command' ; string -> fixnum
; returns fixnum 0 on success
        _ string_raw_data_address
        mov     arg0_register, rbx
        extern  system
        xcall   system
        mov     rbx, rax
        _tag_fixnum
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

; ### date-time
code date_time, 'date-time'             ; -> string
        _lit 256
        _ raw_allocate
        _duptor
        popd    arg0_register
        xcall   os_date_time
        _rfetch
        _dup
        _ zstrlen
        _ copy_to_string
        _rfrom
        _ raw_free
        next
endcode
