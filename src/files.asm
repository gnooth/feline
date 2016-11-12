; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

extern os_open_file

; ### file-open-read
code file_open_read, 'file-open-read'   ; string -- fd
        _ string_data
%ifdef WIN64
        ; args in rcx, rdx, r8, r9
        popd    rcx
        mov     rdx, GENERIC_READ
%else
        ; args in rdi, rsi, rdx, rcx
        popd    rdi
        xor     esi, esi
%endif
        xcall   os_open_file
        test    rax, rax
        js      .1
        pushd   rax                     ; -- fd
        _return
.1:
        _error "unable to open file"
        next
endcode

extern os_file_size

; ### file-size
code file_size, 'file-size'             ; fd -- tagged-size
; FILE
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
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

extern os_read_char

; ### file-read-char
code file_read_char, 'file-read-char'   ; fd -- char/f
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
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

extern os_read_file

; ### file-read-unsafe
code file_read_unsafe, 'file-read-unsafe' ; addr tagged-size fd -- count
; Address and fd are untagged.
        _tor
        _ check_index
        _rfrom
%ifdef WIN64
        popd    rcx                     ; fd
        popd    r8                      ; size
        popd    rdx                     ; addr
%else
        popd    rdi
        popd    rdx
        popd    rsi
%endif
        xcall   os_read_file
        test    rax, rax
        js      .1
        pushd   rax
        _tag_fixnum                     ; -- count
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

extern os_create_file

; ### file-create-write
code file_create_write, 'file-create-write' ; string -- fd
        _ string_data
%ifdef WIN64
        mov     rdx, GENERIC_WRITE
        popd    rcx
%else
        mov     rsi, 1
        popd    rdi
%endif
        xcall   os_create_file
        test    rax, rax
        js      .1
        pushd   rax                     ; -- fd
        _return
.1:
        _error "unable to create file"
        next
endcode

extern os_write_file

; ### file-write-char
code file_write_char, 'file-write-char' ; tagged-char fd --
        _swap
        _untag_char
        _swap
%ifdef WIN64
        ; args in rcx, rdx, r8, r9
        popd    rdx
        popd    rcx
%else
        ; args in rdi, rsi, rdx, rcx
        popd    rsi
        popd    rdi
%endif
        xcall   os_emit_file            ; void os_emit_file(int c, int fd)
        next
endcode

; ### file-write-unsafe
code file_write_unsafe, 'file-write-unsafe' ; addr tagged-size fd -- count
; Address and fd are untagged.
        _tor
        _ check_index
        _rfrom
%ifdef WIN64
        popd    rcx                     ; fd
        popd    r8                      ; size
        popd    rdx                     ; addr
%else
        popd    rdi
        popd    rdx
        popd    rsi
%endif
        xcall   os_write_file
        test    rax, rax
        jns     .1
        _error "error writing to file"
.1:
        next
endcode

; ### file-write-line
code file_write_line, 'file-write-line' ; string fd --
        _tor
        _dup
        _ string_data
        _swap
        _ string_length
        _rfetch
        _ file_write_unsafe

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

extern os_close_file

; ### file-close
code file_close, 'file-close'           ; fd --
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_close_file
        test    rax, rax
        js      .1
        _return
.1:
        _error "unable to close file"
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

; ### ?file-contents
code safe_file_contents, '?file-contents' ; path -- string/f
        _quotation .1
        _ file_contents
        _end_quotation .1
        _quotation .2
        ; -- path error
        _2drop
        _f
        _end_quotation .2
        _ recover
        next
endcode

; ### file-lines
code file_lines, 'file-lines'           ; path -- vector
        _ file_open_read                ; -- fd
        _lit 256
        _ new_vector_untagged           ; -- fd vector
.1:
        _over
        _ file_read_line                ; -- fd vector string/f
        _dup
        _tagged_if .2
        _over
        _ vector_push
        jmp .1
        _else .2
        ; reached end of file
        _drop
        _swap
        _ file_close
        _then .2
        next
endcode

; ### set-file-lines
code set_file_lines, 'set-file-lines'  ; seq path --
        _ file_create_write             ; -- seq fd
        _swap                           ; -- fd seq
        _quotation .1
        _over
        _ file_write_line
        _end_quotation .1
        _ each
        _ file_close
        next
endcode

; ### regular-file?
code regular_file?, 'regular-file?'     ; path -- ?
        _dup
        _ path_is_directory?
        _if .1
        mov     rbx, f_value
        _else .1
        ; not a directory
        _ path_file_exists?
        _then .1
        next
endcode

; ### path-append
code path_append, 'path-append'         ; string1 string2 -- string3
        _ verify_string
        _swap
        _ verify_string
        _swap

        _dup
        _ path_is_absolute?
        _if .1
        _nip
        _return
        _then .1

        _swap                           ; -- filename path
        _dup
        _ string_last_char
        _ path_separator_char
        _notequal
        _if .2
%ifdef WIN64
        _quote "\"
%else
        _quote "/"
%endif
        _ concat
        _then .2
        _swap
        _ concat
        next
endcode

; ### feline-home
code feline_home, 'feline-home'         ; -- string
        _quote FELINE_HOME
        next
endcode

; ### directory?
code directory?, 'directory?'           ; path -- ?
        _ path_is_directory?
        _tag_boolean
        next
endcode

; ### cd
code cd, 'cd'
        _ parse_token
        _dup
        _tagged_if .1
        _ tilde_expand_filename
        _ set_current_directory
        _drop                           ; REVIEW error message?
        _else .1
        _drop
        _ current_directory
        _ write_string
        _then .1
        next
endcode
