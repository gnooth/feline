; Copyright (C) 2016-2017 Peter Graves <gnooth@gmail.com>

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

; 6 cells: object header, string, raw index, line, line start, file

; set in constructor, read only thereafter
%macro  _lexer_string 0                 ; lexer -- string
        _slot1
%endmacro

%macro  _this_lexer_string 0            ; -- string
        _this_slot1
%endmacro

%macro  _this_lexer_set_string 0        ; string --
        _this_set_slot1
%endmacro

; untagged index of current character
%macro  _lexer_raw_index 0              ; lexer -- index
        _slot2
%endmacro

%define this_lexer_raw_index    this_slot2

%macro  _this_lexer_raw_index 0         ; -- index
        _this_slot2
%endmacro

%macro  _lexer_set_raw_index 0          ; index lexer --
        _set_slot2
%endmacro

%macro  _this_lexer_set_raw_index 0     ; index --
        _this_set_slot2
%endmacro

; untagged line number
%macro  _lexer_line_number 0            ; lexer -- line-number
        _slot3
%endmacro

%macro  _this_lexer_line_number 0       ; -- line-number
        _this_slot3
%endmacro

%macro  _lexer_set_line_number 0        ; line-number lexer --
        _set_slot3
%endmacro

%macro  _this_lexer_set_line_number 0   ; line-number --
        _this_set_slot3
%endmacro

; untagged index of first character of current line
%macro  _lexer_raw_line_start 0         ; lexer -- untagged-index
        _slot4
%endmacro

%macro  _this_lexer_raw_line_start 0    ; -- untagged-index
        _this_slot4
%endmacro

%macro  _this_lexer_set_raw_line_start 0        ; untagged-index --
        _this_set_slot4
%endmacro

%macro  _lexer_file 0                   ; lexer -- file
        _slot5
%endmacro

%macro  _lexer_set_file 0               ; file lexer --
        _set_slot5
%endmacro

%macro  _this_lexer_file 0              ; -- file
        _this_slot5
%endmacro

%macro  _this_lexer_set_file 0          ; file --
        _this_set_slot5
%endmacro

%macro  _this_lexer_string_nth_unsafe 0
        _this_lexer_string              ; -- handle
        _handle_to_object_unsafe        ; -- string
        _string_nth_unsafe              ; -- untagged-char
%endmacro

; ### lexer?
code lexer?, 'lexer?'                   ; handle -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _eq? OBJECT_TYPE_LEXER
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-lexer
code error_not_lexer, 'error-not-lexer' ; x --
        ; REVIEW
        _error "not a lexer"
        next
endcode

; ### verify-lexer
code verify_lexer, 'verify-lexer'       ; handle -- handle
        _dup
        _ lexer?
        _tagged_if .1
        _return
        _then .1

        _ error_not_lexer
        next
endcode

; ### check-lexer
code check_lexer, 'check-lexer'         ; x -- lexer
        _ deref
        test    rbx, rbx
        jz      error_not_lexer
        movzx   eax, word [rbx]
        cmp     eax, OBJECT_TYPE_LEXER
        jne     error_not_lexer
        next
endcode

; ### lexer-string
code lexer_string, 'lexer-string'       ; lexer -- string
        _ check_lexer
        _lexer_string
        next
endcode

; ### lexer-index
code lexer_index, 'lexer-index'         ; lexer -- tagged-index
        _ check_lexer
        _lexer_raw_index
        _tag_fixnum
        next
endcode

; ### lexer-set-index
code lexer_set_index, 'lexer-set-index' ; tagged-index lexer --
        _ check_lexer
        _swap
        _ check_index                   ; -- lexer untagged-index
        _swap
        _lexer_set_raw_index
        next
endcode

; ### lexer-at-end?
code lexer_at_end?, 'lexer-at-end?'     ; lexer -- ?
        _dup
        _ lexer_index
        _swap
        _ lexer_string
        _ string_length
        _fixnum_ge
        next
endcode

; ### lexer-line-number
code lexer_line_number, 'lexer-line-number' ; -- line
        _ check_lexer
        _lexer_line_number
        _tag_fixnum
        next
endcode

; ### lexer-line-start
code lexer_line_start, 'lexer-line-start' ; -- tagged-index
        _ check_lexer
        _lexer_raw_line_start
        _tag_fixnum
        next
endcode

; ### lexer-char
code lexer_char, 'lexer-char'           ; lexer -- char
        _ check_lexer
        _dup
        _lexer_raw_index
        _tag_fixnum
        _swap
        _lexer_string
        _ string_nth
        next
endcode

; ### lexer-file
code lexer_file, 'lexer-file'           ; lexer -- file
        _ check_lexer
        _lexer_file
        next
endcode

; ### lexer-set-file
code lexer_set_file, 'lexer-set-file'   ; file lexer --
        _ check_lexer
        _lexer_set_file
        next
endcode

; ### lexer-location
code lexer_location, 'lexer-location'   ; lexer -- 3array/f
        _ check_lexer
        push    this_register
        mov     this_register, rbx
        poprbx
        _this_lexer_file
        _this_lexer_line_number
        _tag_fixnum
        _this_lexer_raw_index
        _this_lexer_raw_line_start
        _minus
        _tag_fixnum
        _ three_array
        pop     this_register
        next
endcode

; ### location
code location, 'location'       ; -- 3array/f
        _ lexer
        _ get
        _dup
        _tagged_if .1
        _ lexer_location
        _else .1
        _drop
        _f
        _then .1
        next
endcode

; ### <lexer>
code new_lexer, '<lexer>'               ; string -- lexer
; 6 cells: object header, string, raw index, line, line start, file

        _lit 6
        _ allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- object callable

        _this_object_set_type OBJECT_TYPE_LEXER

        _ verify_string
        _this_lexer_set_string

        _f
        _this_lexer_set_file

        pushrbx
        mov     rbx, this_register      ; -- lexer

        ; Return handle.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### lexer-line
code lexer_line, 'lexer-line'           ; lexer -- string

        _ check_lexer

        push    this_register
        mov     this_register, rbx
        poprbx

        _lit tagged_char(10)
        _this_lexer_raw_line_start
        _tag_fixnum
        _this_lexer_string
        _ string_index_from             ; -- index/f

        _dup
        _tagged_if .1
        _this_lexer_raw_line_start
        _tag_fixnum
        _swap
        _this_lexer_string
        _else .1
        _drop
        _this_lexer_raw_line_start
        _tag_fixnum
        _this_lexer_string
        _dup
        _ string_length
        _swap
        _then .1

        _ string_substring

        pop     this_register
        next
endcode

; ### lexer-next-line
code lexer_next_line, 'lexer-next-line' ; lexer --

        _ check_lexer

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_lexer_raw_index
        _this_lexer_string
        _ string_length
        _untag_fixnum

        _twodup
        _ ge
        _if .1
        _2drop
        jmp     .exit
        _then .1                        ; -- untagged-start-index untagged-length

        _swap
        _do .2
        _i
        _this_lexer_string_nth_unsafe
        _lit 10
        _equal
        _if .3
        _this_lexer_line_number
        _oneplus
        _this_lexer_set_line_number
        _i
        _oneplus
        _dup
        _this_lexer_set_raw_index
        _this_lexer_set_raw_line_start
        _unloop
        jmp     .exit
        _then .3
        _loop .2

        ; reached end of string without finding a newline
        _this_lexer_string
        _ string_length
        _untag_fixnum
        _this_lexer_set_raw_index

.exit:
        pop     this_register
        next
endcode

; ### lexer-string-skip-whitespace
code lexer_string_skip_whitespace, 'lexer-string-skip-whitespace' ; lexer -- index/f

        _ check_lexer

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_lexer_raw_index
        _this_lexer_string
        _ string_length
        _untag_fixnum
        _twodup
        _ ge
        _if .1
        _2drop
        _f
        jmp     .exit
        _then .1                        ; -- untagged-start-index untagged-length

        _swap
        _do .2
        _i
        _this_lexer_string_nth_unsafe   ; -- untagged-char

        ; check for newline
        cmp     rbx, 10
        jne     .3

        ; char is a newline
        poprbx                          ; --
        _this_lexer_line_number
        _oneplus
        _this_lexer_set_line_number
        _i
        _oneplus
        _this_lexer_set_raw_line_start
        jmp     .4

.3:
        ; char is not a newline
        _lit 32
        _ugt
        _if .5
        _i
        _tag_fixnum
        _unloop
        jmp     .exit
        _then .5
.4:
        _loop .2

        _f

.exit:
        pop     this_register
        next
endcode

; ### lexer-skip-blank
code lexer_skip_blank, 'lexer-skip-blank' ; lexer -- index/f
        _dup
        _ lexer_string_skip_whitespace

        _duptor

        _dup
        _tagged_if .1
        _swap
        _ lexer_set_index
        _else .1
        _drop
        _dup
        _ lexer_string
        _ string_length
        _swap
        _ lexer_set_index
        _then .1

        _rfrom

        next
endcode

; : skip-blank ( )
;     lexer-index lexer-string string-skip-whitespace ( -- index/f )
;     [ lexer-index! ] [ lexer-string length lexer-index! ] if* ;

; ### skip-blank
code skip_blank, 'skip-blank'           ; lexer --
        _ check_lexer

skip_blank_unchecked:

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_lexer_raw_index
        _tag_fixnum
        _this_lexer_string
        _ string_skip_whitespace        ; -- index/f

        _dup
        _tagged_if .1
        _untag_fixnum
        _this_lexer_set_raw_index
        _else .1
        _drop
        _this_lexer_string
        _ string_length
        _untag_fixnum
        _this_lexer_set_raw_index
        _then .1

        pop     this_register
        next
endcode

; : skip-word ( )
;     lexer-index lexer-string string-skip-to-whitespace ( -- index/f )
;     [ lexer-index! ] [ lexer-string length lexer-index! ] if* ;

; ### skip-word
code skip_word, 'skip-word'             ; lexer -- index
        _ check_lexer

skip_word_unchecked:

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_lexer_raw_index
        _tag_fixnum
        _this_lexer_string
        _ string_skip_to_whitespace     ; -- index/f

        _dup
        _tagged_if .1
        _untag_fixnum
        _this_lexer_set_raw_index
        _else .1
        _drop
        _this_lexer_string
        _ string_length
        _untag_fixnum
        _this_lexer_set_raw_index
        _then .1

        _this_lexer_raw_index
        _tag_fixnum

        pop     this_register
        next
endcode

; ### lexer-skip-quoted-string
code lexer_skip_quoted_string, 'lexer-skip-quoted-string' ; lexer --

        _ check_lexer

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_lexer_raw_index
        _oneplus
        _this_lexer_set_raw_index

        _this_lexer_raw_index
        _this_lexer_string
        _ string_length
        _untag_fixnum
        _twodup
        _ ge
        _if .1
        jmp     .error
        _then .1                        ; -- untagged-start-index untagged-length

        _swap
        _do .2
        _i
        _this_lexer_string_nth_unsafe   ; -- untagged-char
        _dup
        _lit '"'
        _equal
        _if .3
        _drop
        _i
        _oneplus
        _this_lexer_set_raw_index
        _unloop
        jmp     .exit
        _then .3

        ; check for newline
        _lit 10
        _equal
        _if .4
        _this_lexer_line_number
        _oneplus
        _this_lexer_set_line_number
        _i
        _oneplus
        _this_lexer_set_raw_line_start
        _then .4

        _loop .2

.error:
        _error "unterminated string"

.exit:
        pop     this_register
        next
endcode

; ### lexer-parse-token
code lexer_parse_token, 'lexer-parse-token' ; lexer -- string/f
        _dup
        _ lexer_skip_blank              ; -- lexer index/f

        _dup
        _tagged_if_not .1
        _2drop
        _f
        _return
        _then .1                        ; -- lexer index

        _over
        _ lexer_char
        _lit tagged_char('"')
        _eq?
        _tagged_if .2
        _over
        _ lexer_skip_quoted_string
        _over
        _ lexer_index                   ; -- lexer from to
        _ rot
        _ lexer_string
        _ string_substring
        _return
        _then .2

        _over
        _ skip_word
        _twodup
        _ eq?
        _tagged_if .3
        _3drop
        _f
        _else .3
        _ rot
        _ lexer_string
        _ string_substring
        _then .3

        next
endcode

; ### .lexer
code dot_lexer, '.lexer'                ; lexer --
        _ check_lexer

        push    this_register
        mov     this_register, rbx
        poprbx

        _quote "LEXER{ "
        _ write_string

        _this_lexer_string
        _ string_length
        _lit tagged_fixnum(40)
        _ fixnum_le
        _tagged_if .1

        _this_lexer_string
        _ dot_object

        _else .1

        _lit tagged_char('"')
        _ write_char

        _this_lexer_string
        _lit tagged_fixnum(37)
        _ string_head
        _ write_string

        _quote "..."
        _ write_string

        _lit tagged_char('"')
        _ write_char

        _then .1

        _ space

        _this_lexer_raw_index
        _tag_fixnum
        _ dot_object
        _ space

        _this_lexer_line_number
        _tag_fixnum
        _ dot_object
        _ space

        _this_lexer_raw_line_start
        _tag_fixnum
        _ dot_object
        _ space

        _this_lexer_file
        _ dot_object

        _write " }"

        pop     this_register
        next
endcode
