; Copyright (C) 2016-2019 Peter Graves <gnooth@gmail.com>

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

; ### file-exists?
code file_exists?, 'file-exists?'       ; path -- ?
        _ string_raw_data_address
        mov     arg0_register, rbx
        xcall   os_file_status          ; returns 0 if file exists
        test    rax, rax
        mov     eax, f_value
        mov     ebx, t_value
        cmovnz  ebx, eax
        next
endcode

; ### directory?
code directory?, 'directory?'           ; path -- ?
        _ string_raw_data_address
        mov     arg0_register, rbx
        xcall   os_file_is_directory
        test    rax, rax
        mov     eax, t_value
        mov     ebx, f_value
        cmovnz  ebx, eax
        next
endcode

; ### regular-file?
code regular_file?, 'regular-file?'     ; path -- ?
        _dup
        _ directory?
        _tagged_if .1
        mov     ebx, f_value
        _else .1
        ; not a directory
        _ file_exists?
        _then .1
        next
endcode

; ### file-open-read
code file_open_read, 'file-open-read'   ; string -- fd
        _dup
        _ string_raw_data_address
        popd    arg0_register
        xcall   os_file_open_read
        test    rax, rax
        js      .1
        mov     rbx, rax
        _return
.1:
        _ error_file_not_found
        next
endcode

; ### file-open-append
code file_open_append, 'file-open-append'       ; string -> file-output-stream
        _dup
        _ string_raw_data_address
        popd    arg0_register
        xcall   os_file_open_append
        test    rax, rax
        js      .1
        mov     rbx, rax
        _ make_file_output_stream
        next
.1:
        _ error_file_not_found
        next
endcode

; ### file-create-write
code file_create_write, 'file-create-write' ; string -> file-output-stream
        _dup
        _ string_raw_data_address
        mov     arg0_register, rbx
        poprbx
        xcall   os_file_create_write
        test    rax, rax
        js      .error
        mov     rbx, rax
        _ make_file_output_stream
        next
.error:
        ; REVIEW explain reason for failure
        _quote "Unable to create file %s"
        _ format
        _ error
        next
endcode

; ### file-size
code file_size, 'file-size'             ; fd -> tagged-size
        mov     arg0_register, rbx
        xcall   os_file_size
        test    rax, rax
        js      .1
        mov     rbx, rax
        _tag_fixnum
        next
.1:
        _error "file size error"
        next
endcode

; ### file-write-time
code file_write_time, 'file-write-time' ; path -- fixnum
        _ string_raw_data_address
        mov     arg0_register, rbx
        xcall   os_file_write_time
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### file-read-char
code file_read_char, 'file-read-char'   ; fd -> char/f
        mov     arg0_register, rbx
        ; REVIEW os_read_char returns -1 if error or end of file
        xcall   os_read_char
        test    rax, rax
        js      .1
        mov     ebx, eax
        _tag_char
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### file-read-unsafe
code file_read_unsafe, 'file-read-unsafe' ; buffer-address tagged-size fd -> tagged-count
; address and fd are untagged
        _tor
        _ check_index
        _rfrom

        popd    arg0_register           ; fd
        popd    arg2_register           ; untagged size
        popd    arg1_register           ; addr

; arg0_register: fd
; arg1_register: buffer address
; arg2_register: untagged size

        xcall   os_read_file            ; cell os_read_file(cell fd, void *buf, size_t count)
        test    rax, rax
        js      .1
        pushd   rax
        _tag_fixnum                     ; -> tagged-count
        _return
.1:
        _error "error reading from file"
        next
endcode

; ### file-read-line
code file_read_line, 'file-read-line'   ; fd -- string/f
        _dup
        _ file_read_char                ; -- fd char/f
        cmp     rbx, f_value
        jne     .1
        _nip
        _return
.1:                                     ; -- fd char
        _lit 256
        _ new_sbuf_untagged             ; -- fd char sbuf
        _swap                           ; -- fd sbuf char
        jmp     .3
.2:
        _over
        _ file_read_char
.3:
        cmp     rbx, tagged_char(10)
        je      .4
        cmp     rbx, f_value
        je      .4
        _over
        _ sbuf_push
        jmp     .2
.4:
        _drop
        _nip                            ; -- sbuf

        ; check for cr preceding nl
        _dup
        _ sbuf_?last
        _lit tagged_char(13)
        _eq?
        _tagged_if .5
        _dup
        _ sbuf_length
        _lit tagged_fixnum(1)
        _ fixnum_minus
        _over
        _ sbuf_shorten
        _then .5

        _ sbuf_to_string

        next
endcode

; ### file-create-write-fd
code file_create_write_fd, 'file-create-write-fd'       ; string -- fd
        _ string_raw_data_address
        popd    arg0_register
        xcall   os_file_create_write
        test    rax, rax
        js      .1
        pushd   rax                     ; -- fd
        _return
.1:
        _error "unable to create file"
        next
endcode

; ### file-write-char
code file_write_char, 'file-write-char' ; tagged-char fd -> void
        popd    arg1_register           ; fd
        _check_char
        popd    arg0_register
        xcall   os_emit_file            ; void os_emit_file(int c, int fd)
        next
endcode

; ### file-write-string
code file_write_string, 'file-write-string' ; string fd -> void
        _tor
        _ string_from
        _rfrom                          ; -> raw-data-address raw-length fd
        mov     arg0_register, rbx      ; fd
        mov     arg1_register, [rbp + BYTES_PER_CELL] ; raw-data-address
        mov     arg2_register, [rbp]    ; raw-length length
        _3drop
        xcall   os_write_file           ; cell os_write_file(cell fd, void *buf, size_t count)
        test    rax, rax
        jns     .1
        _error "error writing to file"
.1:
        next
endcode

; ### file-write-line
code file_write_line, 'file-write-line' ; string fd --
        _duptor
        _ file_write_string
%ifdef WIN64
        _lit tagged_char(13)
        _rfetch
        _ file_write_char
%endif
        _lit tagged_char(10)
        _rfrom
        _ file_write_char
        next
endcode

; ### file-close
code file_close, 'file-close'           ; fd --
        popd    arg0_register
        xcall   os_close_file
        test    rax, rax
        js      .1
        _return
.1:
        _error "unable to close file"
        next
endcode

; ### file-flush
code file_flush, 'file-flush'           ; fd -> void
        popd    arg0_register
        xcall   os_flush_file
        test    rax, rax
        js      .1
        _return
.1:
        _error "unable to flush file"
        next
endcode

; ### file-contents
code file_contents, 'file-contents'     ; path -- string
        _ file_open_read                ; -- fd
        _duptor
        _ file_size                     ; -- tagged-size
        _dup
        _ feline_allocate               ; -- tagged-size buffer
        _swap                           ; -- buffer tagged-size
        _dupd                           ; -- buffer buffer size
        _rfetch                         ; -- buffer buffer size fd
        _ file_read_unsafe              ; -- buffer tagged-size
        _rfrom
        _ file_close                    ; -- buffer tagged-size

        _dupd
        _untag_fixnum
        _ copy_to_string
        _swap
        _ feline_free
        next
endcode

; ### safe-file-contents
code safe_file_contents, 'safe-file-contents' ; path -> string/f
        _quotation .1
        _ file_contents
        _end_quotation .1
        _quotation .2
        ; -> path error
        _2drop
        _f
        _end_quotation .2
        _ recover
        next
endcode

; ### set-file-contents
code set_file_contents, 'set-file-contents'     ; string path --
        _ file_create_write             ; -> string file-output-stream
        _tuck
        _ file_output_stream_write_string
        _ file_output_stream_close
        next
endcode

; ### copy-file
code copy_file, 'copy-file'     ; from to --
        _swap
        _ file_contents
        _swap
        _ set_file_contents
        next
endcode

; ### file-lines
code file_lines, 'file-lines'           ; path -> vector
        _ file_contents
        _ string_lines
        next
endcode

; ### set-file-lines
code set_file_lines, 'set-file-lines'   ; seq path --
        _ file_create_write_fd          ; -- seq fd
        _swap                           ; -- fd seq
        _quotation .1
        _over
        _ file_write_line
        _end_quotation .1
        _ each
        _ file_close
        next
endcode

; ### path-is-absolute?
code path_is_absolute?, 'path-is-absolute?'     ; string -- ?

        _dup
        _ string_empty?
        _tagged_if .1
        mov     ebx, f_value
        _return
        _then .1

%ifdef WIN64

        _dup
        _ string_first_char
        _ path_separator_char?
        _tagged_if .2
        mov     ebx, t_value
        _return
        _then .2

        ; is second char ':'?
        _dup
        _ string_raw_length
        cmp     rbx, 2
        poprbx
        jb      .3
        _lit tagged_fixnum(1)
        _swap
        _ string_nth_unsafe
        _eq? tagged_char(':')
        _return

.3:
        mov     ebx, f_value

%else

        ; Linux
        _ string_first_char
        _ path_separator_char?

%endif

        next
endcode

; ### path-separator-char
%ifdef WIN64
feline_constant path_separator_char, 'path-separator-char', tagged_char('\')
%else
feline_constant path_separator_char, 'path-separator-char', tagged_char('/')
%endif

; ### path-separator-char?
code path_separator_char?, 'path-separator-char?'       ; char -- ?
; accept '/' even on Windows
%ifdef WIN64
        cmp     rbx, tagged_char('\')
        jne     .1
        mov     ebx, t_value
        _return
.1:
        ; fall through...
%endif
        _eq? tagged_char('/')
        next
endcode

; ### path-extension
code path_extension, 'path-extension'   ; path -- extension/f
        _duptor
        _ string_raw_length
        sub     rbx, 1
        _tag_fixnum
        _rfetch
        _quotation .1
        _dup
        _eq? tagged_char('.')
        _swap
        _ path_separator_char?
        _ feline_or
        _end_quotation .1
        _ find_last_from                ; -- index/f element/f
        _eq? tagged_char('.')
        _tagged_if .2
        _rfrom                          ; -- index string
        _ string_tail
        _else .2
        _rdrop
        mov     ebx, f_value
        _then .2
        next
endcode

; ### path-append
code path_append, 'path-append'         ; string1 string2 -- string3
        _ verify_string
        _swap
        _ verify_string                 ; -- filename path
        _dup
        _ string_last_char
        _ path_separator_char
        cmp     rbx, [rbp]
        _2drop
        je      .1
%ifdef WIN64
        _quote "\"
%else
        _quote "/"
%endif
        _ string_append
.1:
        _swap
        _ string_append
        next
endcode

; ### feline-home
code feline_home, 'feline-home'         ; -- string
        _quote FELINE_HOME
        next
endcode

; ### feline-source-directory
code feline_source_directory, 'feline-source-directory' ; -- string
        _quote FELINE_SOURCE_DIR
        next
endcode

; ### tilde-expand-filename
code tilde_expand_filename, 'tilde-expand-filename' ; string1 -> string2

        _duptor

        _ string_raw_length
        test    rbx, rbx
        _drop
        jnz .1
        _rfrom
        _return

.1:
        ; length > 0
        _rfetch
        _ string_first_char
        cmp     rbx, tagged_char('~')
        _drop
        jz      .2
        _rfrom
        _return

.2:
        _rfetch
        _ string_raw_length
        cmp     rbx, 1
        _drop
        jne .3
        _rdrop
        _ user_home
        _return

.3:
        ; length > 1
        _lit tagged_fixnum(1)
        _rfetch
        _ string_nth
        _ path_separator_char?          ; "~/" or "~\"
        _tagged_if .4
        _ user_home
        _lit tagged_fixnum(2)
        _rfrom
        _ string_tail
        _ path_append
        _return
        _then .4

        ; return original string
        _rfrom
        next
endcode

; ### canonical-path
code canonical_path, 'canonical-path'   ; string1 -> string2/f

        _ tilde_expand_filename

        _ string_raw_data_address       ; -> zaddr1

        mov     arg0_register, rbx
        xcall   os_realpath

        test    rax, rax
        jz      .1

        mov     rbx, rax                ; -> zaddr2
        _dup
        _ zcount
        _ copy_to_string                ; -> zaddr2 string2
        mov     arg0_register, [rbp]
        xcall   os_free
        _nip
        _return

.1:
        ; error
        mov     rbx, f_value
        next
endcode

; ### get-current-directory
code get_current_directory, 'get-current-directory' ; -- string
        _lit 1024
        _ feline_allocate_untagged      ; address in rbx
        mov     arg1_register, 1024
        mov     arg0_register, rbx      ; address
        xcall   os_getcwd
        test    rax, rax
        jz      .1
        mov     rbx, rax
        _dup
        _ zcount
        _ copy_to_string
        _swap
        _ feline_free
        _return

.1:
        ; error
        mov     arg0_register, rbx
        xcall   os_free
        mov     rbx, f_value
        next
endcode

; ### set-current-directory
code set_current_directory, 'set-current-directory'     ; string -- ?
        _ verify_string
        _ string_raw_data_address
        mov     arg0_register, rbx
        xcall   os_chdir
        mov     rbx, rax
        _tag_boolean
        next
endcode

; ### cd
code cd, 'cd'
        _ parse_token
        _dup
        _tagged_if .1
        _ canonical_path
        _ set_current_directory
        _drop                           ; REVIEW error message?
        _else .1
        _drop
        _ get_current_directory
        _ write_string
        _then .1
        next
endcode

; ### make-directory
code make_directory, 'make-directory'   ; string -> void
        _dup
        _ string_raw_data_address
        mov     arg0_register, rbx
%ifdef WIN64
        mov     arg1_register, 0
        extern  CreateDirectoryA
        xcall   CreateDirectoryA
        test    rax, rax
        jz      .error
%else
        mov     arg1_register, 0x1ff
        extern  mkdir
        xcall   mkdir
        test    rax, rax
        jnz     .error
%endif
        _2drop
        next
.error:
        _drop
        _quote "ERROR: Unable to create directory %S."
        _ format
        _ error
        next
endcode

%ifdef WIN64

extern os_find_first_file

; ### find-first-file
code find_first_file, 'find-first-file' ; string -> alien
        _ string_raw_data_address
        mov     arg0_register, rbx

        ; os_find_first_file returns 0 if FindFirstFile returns
        ; INVALID_HANDLE_VALUE
        xcall   os_find_first_file

        mov     rbx, rax
        _tag_fixnum
        next
endcode

extern os_find_next_file

; ### find-next-file
code find_next_file, 'find-next-file'   ; alien -> ?
        _check_fixnum
        mov     arg0_register, rbx
        xcall   os_find_next_file
        test    rax, rax
        jz .1
        mov     ebx, t_value
        next
.1:
        mov     ebx, f_value
        next
endcode

extern os_find_close

; ### find-close
code find_close, 'find-close'           ; alien -> ?
        _check_fixnum
        mov     arg0_register, rbx
        xcall   os_find_close
        test    rax, rax
        jz .1
        mov     ebx, t_value
        next
.1:
        mov     ebx, f_value
        next
endcode

extern os_find_file_filename

; ### find-file-filename
code find_file_filename, 'find-file-filename' ; alien -> alien'
        _check_fixnum
        mov     arg0_register, rbx
        xcall   os_find_file_filename
        mov     rbx, rax
        _tag_fixnum
        next
endcode

%else

; Linux

extern os_opendir

; ### opendir
code feline_opendir, 'opendir'          ; string -> alien
        _ string_raw_data_address
        mov     arg0_register, rbx
        xcall   os_opendir
        mov     rbx, rax
        _tag_fixnum
        next
endcode

extern os_readdir

; ### readdir
code feline_readdir, 'readdir'          ; alien -> alien'
        _check_fixnum
        mov     arg0_register, rbx
        xcall   os_readdir
        mov     rbx, rax
        _tag_fixnum
        next
endcode

extern os_closedir

; ### closedir
code feline_closedir, 'closedir'
        _check_fixnum
        mov     arg0_register, rbx
        xcall   os_closedir
        mov     rbx, rax
        _tag_fixnum
        next
endcode

%endif
