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
%macro  _lexer_index 0                  ; lexer -- index
        _slot2
%endmacro

%macro  _this_lexer_index 0             ; -- index
        _this_slot2
%endmacro

%macro  _lexer_set_index 0              ; index lexer --
        _set_slot2
%endmacro

%macro  _this_lexer_set_index 0         ; index --
        _this_set_slot2
%endmacro

; untagged line number
%macro  _lexer_line 0                   ; lexer -- line
        _slot3
%endmacro

%macro  _this_lexer_line 0              ; -- line
        _this_slot3
%endmacro

%macro  _lexer_set_line 0               ; line lexer --
        _set_slot3
%endmacro

%macro  _this_lexer_set_line 0          ; line --
        _this_set_slot3
%endmacro

; untagged index of first character of current line
%macro  _lexer_line_start 0             ; lexer -- index
        _slot4
%endmacro

%macro  _this_lexer_line_start 0        ; -- index
        _this_slot4
%endmacro

%macro  _lexer_set_line_start 0         ; index lexer --
        _set_slot4
%endmacro

%macro  _this_lexer_set_line_start 0    ; index --
        _this_set_slot4
%endmacro

%macro  _this_lexer_string_nth_unsafe 0
        _this_lexer_string              ; -- handle
        _handle_to_object_unsafe        ; -- string
        _string_nth_unsafe
%endmacro

; ### lexer?
code lexer?, 'lexer?'                   ; handle -- ?
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _eq?_literal OBJECT_TYPE_LEXER
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
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object/0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _eq?_literal OBJECT_TYPE_LEXER
        _tagged_if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_lexer
        next
endcode

; ### lexer-string
code lexer_string, 'lexer-string'       ; lexer -- string
        _ check_lexer
        _lexer_string
        next
endcode

; ### lexer-index
code lexer_index, 'lexer-index'         ; lexer -- index
        _ check_lexer
        _lexer_index
        _tag_fixnum
        next
endcode

; ### lexer-set-index
code lexer_set_index, 'lexer-set-index' ; index lexer --
        _ check_lexer
        _swap
        _ check_index
        _swap
        _lexer_set_index
        next
endcode

; ### <lexer>
code lexer, '<lexer>'                   ; string -- lexer
; 5 cells: object header, string, index

        _lit 5
        _ allocate_cells

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- object callable

        _this_object_set_type OBJECT_TYPE_LEXER

        _ verify_string
        _this_lexer_set_string

        pushrbx
        mov     rbx, this_register      ; -- lexer

        ; Return handle.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### lexer-string-skip-whitespace
code lexer_string_skip_whitespace, 'lexer-string-skip-whitespace' ; lexer -- index/f

        _ check_lexer

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_lexer_index
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
        _this_lexer_string_nth_unsafe
        _lit 32
        _ugt
        _if .3
        _i
        _tag_fixnum
        _unloop
        jmp     .exit
        _then .3
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

        _this_lexer_index
        _tag_fixnum
        _this_lexer_string
        _ string_skip_whitespace        ; -- index/f

        _dup
        _tagged_if .1
        _untag_fixnum
        _this_lexer_set_index
        _else .1
        _drop
        _this_lexer_string
        _ string_length
        _untag_fixnum
        _this_lexer_set_index
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

        _this_lexer_index
        _tag_fixnum
        _this_lexer_string
        _ string_skip_to_whitespace     ; -- index/f

        _dup
        _tagged_if .1
        _untag_fixnum
        _this_lexer_set_index
        _else .1
        _drop
        _this_lexer_string
        _ string_length
        _untag_fixnum
        _this_lexer_set_index
        _then .1

        _this_lexer_index
        _tag_fixnum

        pop     this_register
        next
endcode

; ### lexer-parse-token
code lexer_parse_token, 'lexer-parse-token' ; lexer -- string
        _dup
        _ lexer_skip_blank              ; -- lexer index/f

        _dup
        _tagged_if_not .1
        _2drop
        _f
        _return
        _then .1

        _over
        _ skip_word
        _twodup
        _ eq?
        _tagged_if .2
        _3drop
        _f
        _else .2
        _ rot
        _ lexer_string
        _ string_substring
        _then .2

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

        _this_lexer_index
        _tag_fixnum
        _ dot_object

        _this_lexer_line
        _tag_fixnum
        _ dot_object

        _this_lexer_line_start
        _tag_fixnum
        _ dot_object

        _quote "}"
        _ write_string

        pop     this_register
        next
endcode
