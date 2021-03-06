; Copyright (C) 2012-2021 Peter Graves <gnooth@gmail.com>

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

; ### delete-file
code delete_file, 'delete-file'         ; string -> ?
; Returns true if successful, nil on error.
        _ string_raw_data_address
        mov     arg0_register, rbx
        xcall   os_delete_file          ; os_delete_file returns 0 if successful
        mov     ebx, TRUE
        mov     edx, NIL
        test    rax, rax
        cmovnz  ebx, edx
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
code errno_to_string, 'errno-to-string' ; n -> string
        mov     arg0_register, rbx
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

; ### os-time
code os_time, 'os-time'                 ; -> fixnum
        mov     arg0_register, 0
        xcall   time
        _dup
        mov     rbx, rax
        _tag_fixnum
        next
endcode
