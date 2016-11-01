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

; 11.6.1.2218 SOURCE-ID
; SOURCE-ID       Input source
; ---------       ------------
; fileid          Text file fileid
; -1              String (via EVALUATE)
; 0               User input device

; ### source-id
value source_id, 'source-id', 0

; ### source-buffer
value source_buffer, 'source-buffer', 0

; ### source-buffer-size
constant source_buffer_size, 'source-buffer-size', 256

; ### 'source
variable tick_source, "'source", 0

; ### #source
variable nsource, '#source', 0

; ### source
code source, 'source'                   ; -- c-addr u
; CORE 6.1.2216
; "c-addr is the address of, and u is the number of characters in, the input buffer."
        _from tick_source
        _from nsource
        next
endcode

; ### set-source
code set_source, 'set-source'           ; c-addr u --
        _ nsource
        _ store
        _ tick_source
        _ store
        next
endcode

; ### set-input
code set_input, 'set-input'             ; source-addr source-len source-id --
        _to source_id
        _ set_source
        next
endcode

; ### source-filename
value source_filename, 'source-filename', 0

; ### includable?
code includable?, 'includable?'         ; string -- flag
        _dup
        _ path_file_exists?
        _if .1
        _ path_is_directory?
        _zeq
        _else .1
        _drop
        _false
        _then .1
        next
endcode

; ### path-separator-char
%ifdef WIN64
constant path_separator_char, 'path-separator-char', '\'
%else
constant path_separator_char, 'path-separator-char', '/'
%endif

; ### path-separator-char?
code path_separator_char?, 'path-separator-char?' ; char -- flag
; Accept '/' even on Windows.
%ifdef WIN64
        _dup
        _lit '\'
        _equal
        _if .1
        _drop
        _true
        _return
        _then .1
        ; Fall through...
%endif
        _lit '/'
        _equal
        next
endcode

; ### path-get-directory
code path_get_directory, 'path-get-directory' ; string1 -- string2 | 0
        _ string_from                   ; -- c-addr u
        _begin .1
        _dup
        _while .1
        _oneminus
        _twodup
        _plus
        _cfetch
        _ path_separator_char?
        _if .2
        _dup
        _zeq_if .3
        _oneplus
        _then .3
        _ copy_to_string
        _return
        _then .2
        _repeat .1
        _2drop
        _zero
        next
endcode

; ### tilde-expand-filename
code tilde_expand_filename, 'tilde-expand-filename' ; string1 -- string2
        _ verify_string

        _dup
        _ string_first_char
        _untag_char
        _lit '~'
        _notequal
        _if .1
        _return
        _then .1

        _dup
        _ string_length
        _untag_fixnum
        _lit 1
        _equal
        _if .2
        _drop
        _ user_home
        _ verify_string
        _return
        _then .2
                                        ; -- string
        ; length <> 1
        _lit 1
        _over
        _ string_nth_untagged
        _untag_char
        _ path_separator_char?          ; "~/" or "~\"
        _if .3
        _ user_home
        _ check_string
        _swap
        _ string_from
        _lit 1
        _slashstring
        _ copy_to_string
        _ concat
        _return
        _then .3                        ; -- $addr1

        ; return original string
        next
endcode

; ### resolve-include-filename
code resolve_include_filename, 'resolve-include-filename' ; c-addr u -- string
        _ copy_to_string                ; -- string
        _ tilde_expand_filename         ; -- string

        ; If the argument after tilde expansion is not an absolute pathname,
        ; append it to the directory part of the current source filename.
        _dup
        _ path_is_absolute?
        _zeq_if .1
        _ source_filename
        _?dup_if .2
        _ verify_string
        _ path_get_directory
        _?dup_if .3                     ; -- string directory-string
        _ verify_string
        _swap
        _ verify_string
        _ path_append                   ; -- string
        _then .3
        _then .2
        _then .1

        _ verify_string
        _ canonical_path                ; -- string

        _dup
        _ path_is_directory?
        _if .4
        _drop
        _error "file is a directory"
        _then .4

        ; If the path we've got at this point is includable, we're done.
        _dup                            ; -- string string
        _ includable?                   ; -- string flag
        _if .5
        _return
        _then .5                        ; -- string

        ; Otherwise try appending the default extensions.
        _dup                            ; -- string string
        _quote ".feline"
        _ concat                        ; -- string1 string2
        _dup                            ; -- string1 string2 string2
        _ includable?                   ; -- string1 string2 flag
        _if .6
        _nip                            ; return string2
        _return
        _else .6
        _drop
        _then .6

        _dup                            ; -- string string
        _quote ".forth"
        _ concat                        ; -- string1 string2
        _dup                            ; -- string1 string2 string2
        _ includable?                   ; -- string1 string2 flag
        _if .7
        _nip                            ; return string2
        _return
        _then .7

        _drop

        next
endcode

; ### path-is-absolute?
code path_is_absolute?, 'path-is-absolute?' ; string -- flag
        _ verify_string
%ifdef WIN64
        _dup
        _ string_first_char
        _untag_char
        _ path_separator_char
        _equal
        _if .1                          ; -- string
        mov     rbx, -1
        _return
        _then .1

        _dup
        _ string_length                 ; -- string length
        _untag_fixnum
        _lit 2
        _ ge
        _if .2                          ; -- string
        _lit 1
        _swap
        _ string_nth_untagged
        _untag_char
        _lit ':'
        _equal
        _return
        _then .2

        ; otherwise...
        _false
%else
        ; Linux
        _ string_first_char
        _untag_char
        _ path_separator_char
        _equal
%endif
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

; ### system-file-pathname
code system_file_pathname, 'system-file-pathname' ; c-addr1 u1 -- c-addr2 u2
; Returned values are untagged.
        _ copy_to_string
        _ feline_home
        _quote "src"
        _ path_append
        _swap
        _ path_append
        _ string_from
        next
endcode
