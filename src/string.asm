; Copyright (C) 2015-2016 Peter Graves <gnooth@gmail.com>

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

; strings are immutable

; 3 cells: object header, length, hashcode

; character data starts at offset 24
%define STRING_DATA_OFFSET      24

; ### string?
code string?, 'string?'                 ; x -- t|f
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object/0
        _?dup_if .2
        _object_type                    ; -- object-type
        _eq?_literal OBJECT_TYPE_STRING
        _return
        _then .2
        ; Empty handle.
        _f
        _return
        _then .1

        ; Not a handle. Make sure address is in a permissible range.
        _dup                            ; -- x x
        _ in_dictionary_space?          ; -- x flag
        _zeq_if .3
        _dup
        _ in_static_data_area?
        _zeq_if .4
        ; Address is not in a permissible range.
        ; -- x
        mov     ebx, f_value
        _return
        _then .4
        _then .3

        ; -- object
        _object_type                    ; -- object-type
        _eq?_literal OBJECT_TYPE_STRING

        next
endcode

; ### error-not-string
code error_not_string, 'error-not-string' ; x --
        _error "not a string"
        next
endcode

; ### verify-unboxed-string
code verify_unboxed_string, 'verify-unboxed-string' ; string -- string
        ; Make sure address is in a permissible range.
        _dup                            ; -- x x
        _ in_transient_area?            ; -- x flag
        _zeq_if .4                      ; -- x
        _dup
        _ in_dictionary_space?          ; -- x flag
        _zeq_if .5
        _dup
        _ in_static_data_area?
        _zeq_if .6
        ; Address is not in a permissible range.
        _ error_not_string
        _return
        _then .6
        _then .5
        _then .4                        ; -- object

        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_STRING
        _equal
        _if .7
        _return
        _then .7

        _ error_not_string
        next
endcode

; ### check-string
code check_string, 'check-string'       ; handle-or-string -- string
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object|0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_STRING
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _ error_not_string
        _then .1

        ; Not a handle.
        _ verify_unboxed_string

        next
endcode

; ### verify-string
code verify_string, 'verify-string'     ; handle-or-string -- handle-or-string
; Returns argument unchanged.
        _dup
        _ handle?
        _if .1
        _dup
        _handle_to_object_unsafe        ; -- handle object|0
        _dup_if .2
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_STRING
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _ error_not_string
        _then .1

        ; Not a handle.
        _ verify_unboxed_string

        next
endcode

%macro  _string_length 0                ; string -- untagged-length
        _slot1
%endmacro

%macro  _string_set_length 0            ; untagged-length string --
        _set_slot1
%endmacro

%macro  _this_string_length 0           ; -- untagged-length
        _this_slot1
%endmacro

%macro  _this_string_set_length 0       ; untagged-length --
        _this_set_slot1
%endmacro

%macro  _string_hashcode 0              ; string -- tagged-fixnum
        _slot2
%endmacro

%macro  _string_set_hashcode 0          ; tagged-fixnum string --
        _set_slot2
%endmacro

%macro  _this_string_hashcode 0         ; -- tagged-fixnum
        _this_slot2
%endmacro

%macro  _this_string_set_hashcode 0     ; tagged-fixnum --
        _this_set_slot2
%endmacro

; ### string-length
code string_length, 'string-length'     ; string -- length
; Returns a tagged fixnum.
        _ check_string
        _string_length
        _tag_fixnum
        next
endcode

; Strings store their character data inline starting at this + STRING_DATA_OFFSET bytes.
%macro _string_data 0
        lea     rbx, [rbx + STRING_DATA_OFFSET]
%endmacro

%macro _this_string_data 0
        pushrbx
        lea     rbx, [this_register + STRING_DATA_OFFSET]
%endmacro

; ### string-data
code string_data, 'string-data'         ; string -- data-address
        _ check_string                  ; -- string
        _string_data
        next
endcode

%macro  _string_nth_unsafe 0            ; untagged-index string -- untagged-char
        _string_data
        _plus
        _cfetch
%endmacro

%macro  _this_string_nth_unsafe 0       ; untagged-index string -- untagged-char
        _this_string_data
        _plus
        _cfetch
%endmacro

; ### >string
code copy_to_string, '>string'          ; c-addr u -- handle
; Arguments are untagged.
        push    this_register

        _lit STRING_DATA_OFFSET
        _over
        _oneplus                        ; terminal null byte
        _plus                           ; -- c-addr u size
        _ allocate_object               ; -- c-addr u string
        popd    this_register           ; -- c-addr u

        ; Zero all bits of object header.
        xor     eax, eax
        mov     [this_register], rax

        _this_object_set_type OBJECT_TYPE_STRING
        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _f
        _this_string_set_hashcode

        _dup
        _this_string_set_length         ; -- c-addr u

        _tor                            ; -- c-addr             r: -- u

        _this_string_data
        _rfetch
        _ cmove                         ; --                    r: -- u

        ; Store terminal null byte.
        _this_string_data               ; -- data-address       r: -- u
        pop     rax                     ;                       r: --
        add     rbx, rax                ; -- data-address + u
        mov     byte [rbx], 0           ; -- data-address + u

        mov     rbx, this_register      ; -- string

        ; Return handle of allocated string.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### string>
code string_from, 'string>'             ; string -- c-addr u
; Returned values are untagged.
        _ check_string
        _duptor
        _string_data
        _rfrom
        _string_length
        next
endcode

; ### >static-string
code copy_to_static_string, '>static-string' ; c-addr u -- string
; Arguments are untagged.
        _ align_data
        _ here                          ; this will be the address of the string
        _tor

        ; object header
        _lit OBJECT_TYPE_STRING
        _ comma
        ; length
        _dup
        _ comma                         ; -- c-addr u

        ; hashcode
        _f
        _ comma

        _ here                          ; -- c-addr u here
        _over                           ; -- c-addr u here u
        _oneplus                        ; -- c-addr u here u+1
        _ allot
        _ zplace                        ; --

        _rfrom                          ; -- string
        next
endcode

; ### ~string
code destroy_string, '~string'          ; string --
        _ check_string
        _ destroy_string_unchecked
        next
endcode

; ### ~string-unchecked
code destroy_string_unchecked, '~string-unchecked' ; string --
        _dup
        _object_allocated?
        _if .1
        _ in_gc?
        _zeq_if .2
        _dup
        _ release_handle_for_object
        _then .2
        ; Zero out the object header so it won't look like a valid object
        ; after it has been destroyed.
        xor     eax, eax
        mov     [rbx], rax
        _ ifree
        _else .1
        _drop
        _then .1
        next
endcode

; ### string-hashcode
code string_hashcode, 'string-hashcode' ; handle-or-string -- tagged-fixnum|f
        _ check_string
        _string_hashcode
        next
endcode

; ### rehash-string
code rehash_string, 'rehash-string'     ; string --
; Hash function adapted from SBCL.

        _ check_string                  ; -- string

rehash_string_unchecked:
        push    this_register
        popd    this_register           ; --

        _zero                           ; -- accumulator

        _this_string_length
        _zero
        _?do .1

        _i
        _this_string_nth_unsafe         ; -- accum untagged-char
        _plus                           ; -- accum

        mov     rax, rbx
        shl     rax, 10
        add     rbx, rax

        mov     rax, rbx
        shr     rax, 6
        xor     rbx, rax

        _loop .1

        mov     rax, rbx
        shl     rax, 3
        add     rbx, rax

        mov     rax, rbx
        shr     rax, 11
        xor     rbx, rax

        mov     rax, rbx
        shl     rax, 15
        xor     rbx, rax

        _ MOST_POSITIVE_FIXNUM
        _and

        _tag_fixnum
        _this_string_set_hashcode

        pop     this_register
        next
endcode

; ### force-hashcode
code force_hashcode, 'force-hashcode'   ; handle-or-string -- hashcode
        _ check_string
        _dup
        _string_hashcode
        _dup
        _tagged_if .1
        _nip
        _else .1
        _drop
        _dup
        _ rehash_string_unchecked
        _string_hashcode
        _then .1
        next
endcode

; ### as-c-string
code as_c_string, 'as-c-string'         ; c-addr u -- zaddr
; Arguments are untagged.
; Returns a pointer to a null-terminated string.
        _ copy_to_string
        _ string_data
        next
endcode

; ### string-nth-unsafe
code string_nth_unsafe, 'string-nth-unsafe' ; tagged-index handle-or-string -- tagged-char
; No bounds check.
        _swap
        _untag_fixnum
        _swap
        _ check_string
        _string_nth_unsafe
        _tag_char
        next
endcode

; ### string-nth
code string_nth, 'string-nth'           ; tagged-index handle-or-string -- tagged-char
; Return character at index.

        _swap
        _untag_fixnum
        _swap                           ; -- index string

string_nth_untagged:

        _ check_string                  ; -- tagged-index string

        _twodup
        _string_length
        _ult
        _if .1
        _string_nth_unsafe
        _tag_char
        _else .1
        _2drop
        _true
        _abortq "index out of bounds"
        _then .1

        next
endcode

; ### string-first-char
code string_first_char, 'string-first-char' ; string -- char
; Returns first character of string.
; Throws an error if the string is empty.
        _ verify_string
        _zero
        _swap
        _ string_nth_untagged
        next
endcode

; ### string-last-char
code string_last_char, 'string-last-char' ; string -- char
; Returns last character of string.
; Throws an error if the string is empty.
        _ check_string
        _dup
        _string_length
        _dup
        _zeq_if .1
        _2drop
        _true
        _abortq "index out of bounds"
        _else .1
        _swap
        _string_data
        _plus
        _oneminus
        _cfetch
        _then .1

        _tag_char
        next
endcode

; ### string-find-char
code string_find_char, 'string-find-char' ; tagged-char string -- tagged-index | f

        _ check_string

        push    this_register
        popd    this_register           ; -- tagged-char

        _untag_char                     ; -- untagged-char

        _this_string_length
        _zero
        _?do .1
        _i
        _this_string_nth_unsafe
        _over
        _equal
        _if .2
        _drop
        _i
        _tag_fixnum
        _unloop
        jmp     .exit
        _then .2
        _loop .1
        ; not found
        _drop
        _f
.exit:
        pop     this_register
        next
endcode

; ### string-substring
code string_substring, 'string-substring' ; from to string -- substring

        _ check_string

string_substring_unchecked:
        push    this_register
        popd    this_register           ; -- start-index end-index

        _untag_2_fixnums

        _dup
        _this_string_length
        _ugt
        _abortq "end index out of range"
                                        ; -- start-index end-index
        _twodup                         ; -- start-index end-index start-index end-index
        _ugt
        _abortq "start index > end index"
                                        ; -- start-index end-index
        _over
        _minus                          ; -- start-index length
        _this_string_data
        _ underplus
        _ copy_to_string

        pop     this_register
        next
endcode

; ### string-head
code string_head, 'string-head'         ; string n -- substring
        _lit tagged_zero
        _swap
        _ rot
        _ string_substring
        next
endcode

; ### string-tail
code string_tail, 'string-tail'         ; string n -- substring
        _over
        _ string_length
        _ rot
        _ string_substring
        next
endcode

; ### string-skip-whitespace
code string_skip_whitespace, 'string-skip-whitespace' ; start-index string -- index/f
        _ check_string

        push    this_register
        popd    this_register           ; -- start-index

        _ check_index                   ; -- untagged-start-index

        _this_string_length
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
        _this_string_nth_unsafe
        _lit 32
        _ugt
        _if .3
        _i
        _tag_fixnum
        _unloop
        jmp     .exit
        _then .3
        _loop .2

        ; not found
        _f

.exit:
        pop     this_register
        next
endcode

; ### string-skip-to-whitespace
code string_skip_to_whitespace, 'string-skip-to-whitespace' ; start-index string -- index/f
        _ check_string

        push    this_register
        popd    this_register           ; -- start-index

        _ check_index                   ; -- untagged-start-index

        _this_string_length
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
        _this_string_nth_unsafe
        _lit 33
        _ult
        _if .3
        _i
        _tag_fixnum
        _unloop
        jmp     .exit
        _then .3
        _loop .2

        ; not found
        _f

.exit:
        pop     this_register
        next
endcode

; ### .string
code dot_string, '.string'              ; string | sbuf | $addr --
; REVIEW remove support for legacy strings
        _dup_if .1

        ; REVIEW
        _dup
        _ string?
        _tagged_if .4
        _ string_from
        _ type
        _return
        _then .4

        _dup
        _ sbuf?
        _tagged_if .2
        _duptor
        ; FIXME inline
        _ sbuf_data
        _rfrom
        ; FIXME inline
        _ sbuf_length
        _untag_fixnum
        _ type
        _return
        _then .2

        _ count
        _ type
        _else .1
        _drop
        _then .1
        next
endcode

; ### concat
code concat, 'concat'                   ; string1 string2 -- string3
        _swap
        _ string_to_sbuf                ; -- string2 sbuf
        _swap                           ; -- sbuf string2
        _ sbuf_append_string
        _ sbuf_to_string
        next
endcode

; ### string=
code stringequal, 'string='             ; string1 string2 -- t|f
        _ string_from
        _ rot
        _ string_from
        _ strequal                      ; -- -1|0
        _tag_boolean                    ; -- t|f
        next
endcode

; ### string-equal?
code string_equal?, 'string-equal?'     ; object1 object2 -- t|f
; Returns true if both objects are strings and those strings are identical.
        _dup
        _ string?
        _tagged_if .1
        _swap
        _dup
        _ string?
        _tagged_if .2

        ; both objects are strings

        _twodup
        _lit force_hashcode_xt
        _ bi_at                         ; -- seq1 seq2 hashcode1 hashcode2

        _equal
        _zeq_if .3
        _2drop
        _f
        _return
        _then .3

        _ stringequal
        _return
        _then .2
        _then .1

        _2drop
        _f
        next
endcode

; ### path-get-extension
code path_get_extension, 'path-get-extension' ; pathname -- extension | f

        _ check_string

        push    this_register
        mov     this_register, rbx

        _string_length

        _begin .1
        _dup
        _while .1
        _oneminus
        _dup
        _this_string_nth_unsafe

        ; If we find a path separator char before finding a '.', there is no
        ; extension. Return f.
        _dup
        _ path_separator_char?
        _if .2
        _2drop
        _f
        jmp     .exit
        _then .2

        _lit '.'
        _equal
        _if .3
        _tag_fixnum                     ; -- from
        _this_string_length
        _tag_fixnum                     ; -- to
        _this
        _ string_substring_unchecked    ; -- substring
        jmp     .exit
        _then .3
        _repeat .1

        _drop
        _f

.exit:
        pop     this_register
        next
endcode
