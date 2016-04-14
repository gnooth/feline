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

; Stringbuffers

; ### sbuf?
code sbuf?, 'sbuf?'                     ; object -- flag
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_SBUF
        _equal
        _then .2
        _else .1
        xor     ebx, ebx
        _then .1
        next
endcode

; ### error-not-sbuf
code error_not_sbuf, 'error-not-sbuf'   ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not an sbuf"
        next
endcode

; ### check-sbuf
code check_sbuf, 'check-sbuf'           ; handle -- sbuf
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object|0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_SBUF
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_sbuf
        next
endcode

; %macro _sbuf_length 0                   ; sbuf -- length
;         _slot1
; %endmacro

; ### sbuf-length
code sbuf_length, 'sbuf-length'         ; handle -- length
        _ check_sbuf
        _sbuf_length
        _tag_fixnum
        next
endcode

; %macro _sbuf_set_length 0               ; sbuf length --
;         _set_slot1
; %endmacro

; %macro _sbuf_data 0
;         _slot2
; %endmacro

; ### sbuf-data
code sbuf_data, 'sbuf-data'             ; sbuf -- data-address
        _ check_sbuf
        _sbuf_data
        next
endcode

; %macro _sbuf_set_data 0
;         _set_slot2
; %endmacro

; %macro _sbuf_capacity 0
;         _slot3
; %endmacro

; ### sbuf-capacity
code sbuf_capacity, 'sbuf-capacity'     ; sbuf -- capacity
        _ check_sbuf
        _sbuf_capacity
        next
endcode

; %macro _sbuf_set_capacity 0
;         _set_slot3
; %endmacro

; ### make-sbuf-internal
code make_sbuf_internal, 'make-sbuf-internal' ; capacity -- sbuf

; locals:
%define capacity        local0
%define sbuf            local1

%ifdef USE_TAGS
        _dup
        _fixnum?
        _if .1
        _untag_fixnum
        _then .1
%endif

        _locals_enter

        popd    capacity

        _lit 32                         ; -- 32
        _dup
        _ allocate_object               ; -- 32 sbuf

        popd    sbuf                    ; -- 32
        pushd   sbuf
        _swap
        _ erase                         ; --
        pushd   sbuf
        _lit OBJECT_TYPE_SBUF
        _object_set_type                ; --

        pushd   sbuf
        _lit OBJECT_ALLOCATED_BIT
        _object_set_flags               ; --

        pushd   capacity
        _oneplus                        ; terminal null byte
        _ iallocate
        pushd   sbuf
        _swap
        _sbuf_set_data

        pushd   sbuf
        pushd   capacity
        _sbuf_set_capacity              ; --

        pushd   sbuf

        _locals_leave
        next

%undef capacity
%undef sbuf

endcode

; ### make-sbuf
code make_sbuf, 'make-sbuf'             ; capacity -- handle
        _ make_sbuf_internal
        _ new_handle
        next
endcode

; ### <sbuf>
code new_sbuf, '<sbuf>'                 ; capacity -- sbuf
        _ make_sbuf_internal            ; -- sbuf
        _dup
        _sbuf_data                      ; -- sbuf data-address
        _over
        _sbuf_capacity                  ; -- sbuf data-address capacity
        _oneplus
        _ erase                         ; -- sbuf
        _ new_handle
        next
endcode

; ### >sbuf
code copy_to_sbuf, '>sbuf'              ; c-addr u -- handle

; locals:
%define u      local0
%define c_addr local1
%define sbuf   local2

        _locals_enter
        popd    u
        popd    c_addr

        pushd   u
        _ make_sbuf_internal
        popd    sbuf

        pushd   c_addr
        pushd   sbuf
        _sbuf_data
        pushd   u                       ; -- c-addr data-address u
        _ cmove                         ; --

        _zero
        pushd   sbuf
        _sbuf_data
        pushd   u
        _plus
        _cstore

        pushd   sbuf
        pushd   u
        _sbuf_set_length

        pushd   sbuf
        _ new_handle

        _locals_leave

        next

%undef u
%undef c_addr
%undef sbuf

endcode

; ### string>sbuf
code string_to_sbuf, 'string>sbuf'      ; handle-or-string -- handle
        _ string_from
        _ copy_to_sbuf
        next
endcode

; ### sbuf>
code sbuf_from, 'sbuf>'                 ; handle -- c-addr u
        _ check_sbuf
        _duptor
        _sbuf_data
        _rfrom
        _sbuf_length
        next
endcode

; ### sbuf>string
code sbuf_to_string, 'sbuf>string'      ; handle -- string
        _ sbuf_from
        _ copy_to_string
        next
endcode

; ### sbuf>transient-string
code sbuf_to_transient_string, 'sbuf>transient-string' ; sbuf -- string
        _ sbuf_from
        _ copy_to_transient_string
        next
endcode

; ### ~sbuf
code destroy_sbuf, '~sbuf'              ; handle --
        _ check_sbuf                    ; -- sbuf|0
        _ destroy_sbuf_unchecked
        next
endcode

; ### ~sbuf-unchecked
code destroy_sbuf_unchecked, '~sbuf-unchecked' ; sbuf --
        _dup
        _zeq_if .1
        _drop
        _return
        _then .1

        _dup
        _object_allocated?
        _if .2
        _dup
        _sbuf_data
        _ ifree

        _ in_gc?
        _zeq_if .4
        _dup
        _ release_handle_for_object
        _then .4
        ; Zero out the object header so it won't look like a valid object
        ; after it has been freed.
        xor     eax, eax
        mov     [rbx], rax
        _ ifree
        _else .2
        _drop
        _then .2
        next
endcode

; %macro _sbuf_check_index 0              ; sbuf index -- flag
;         _swap
;         _sbuf_length                    ; -- index length
;         _ult                            ; -- flag
; %endmacro

; ### sbuf-check-index
code sbuf_check_index, 'sbuf-check-index' ; handle index -- flag
        _swap
        _ check_sbuf                    ; -- index sbuf
        _swap
        _sbuf_check_index
        next
endcode

; ### sbuf-char
code sbuf_char, 'sbuf-char'             ; sbuf index -- char
; REVIEW Return character at index, or 0 if index is out of range.
        _twodup
        _ sbuf_check_index
        _if .1
        _swap                           ; -- index sbuf
        _ sbuf_data                     ; -- index data-address
        _plus
        _cfetch
        _else .1
        _2drop
        _zero
        _then .1
        next
endcode

; %macro _sbuf_set_nth_unsafe 0           ; char index sbuf --
;         _sbuf_data
;         _plus
;         _cstore
; %endmacro

; ### sbuf-set-char
code sbuf_set_char, 'sbuf-set-char'     ; handle index char --
        _ rrot                          ; char sbuf index
        _twodup
        _ sbuf_check_index
        _if .1                          ; -- char sbuf index
        _swap                           ; -- char index sbuf
        _ sbuf_data                     ; -- char index data-address
        _plus
        _cstore
        _else .1
        _3drop
        _true
        _abortq "index out of range"
        _then .1
        next
endcode

; ### sbuf-resize
code sbuf_resize, 'sbuf-resize'         ; sbuf new-capacity --
        _over                           ; -- sbuf new-capacity sbuf
        _sbuf_data                      ; -- sbuf new-capacity data-address
        _over                           ; -- sbuf new-capacity data-address new-capacity
        _oneplus                        ; terminal null byte
        _ resize                        ; -- sbuf new-capacity new-data-address ior
        _ throw                         ; -- sbuf new-capacity new-data-address
        _tor
        _over                           ; -- sbuf new-capacity sbuf     r: -- new-data-address
        _swap
        _sbuf_set_capacity              ; -- sbuf                       r: -- new-data-address
        _rfrom                          ; -- sbuf new-data-addr
        _sbuf_set_data
        next
endcode

; ### sbuf-ensure-capacity
code sbuf_ensure_capacity, 'sbuf-ensure-capacity'   ; u sbuf --
        _twodup                         ; -- u sbuf u sbuf
        _sbuf_capacity                  ; -- u sbuf u capacity
        _ugt
        _if .1                          ; -- u sbuf
        _dup                            ; -- u sbuf sbuf
        _sbuf_capacity                  ; -- u sbuf capacity
        _twostar                        ; -- u sbuf capacity*2
        _oneplus                        ; -- u sbuf capacity*2+1
        _ rot                           ; -- sbuf capacity*2 u
        _ max                           ; -- sbuf new-capacity
        _ sbuf_resize
        _else .1
        _2drop
        _then .1
        next
endcode

; ### sbuf-shorten
code sbuf_shorten, 'sbuf-shorten'       ; u handle --
        _ check_sbuf                    ; -- u sbuf
        _twodup
        _sbuf_length
        _ult
        _if .1
        _swap
        _sbuf_set_length
        _else .1
        _2drop
        _then .1
        next
endcode

; ### check-char
code check_char, 'check-char'           ; char -- char
; REVIEW
; This function does not consider 0 to be a char.
        _dup
        _lit 1
        _lit 256
        _ within
        _if .1
        _return
        _then .1

        _drop
        _true
        _abortq "not a char"
        next
endcode

; ### sbuf-append-char
code sbuf_append_char, 'sbuf-append-char' ; sbuf char --

; locals:
%define this   local0
%define char   local1
%define len    local2

        _locals_enter
        _ check_char
        popd    char
        _ check_sbuf
        popd    this                    ; --

        ; this sbuf-length local len
        pushd   this
        _sbuf_length
        popd    len

        ; len 1+ this sbuf-ensure-capacity
        pushd   len
        _oneplus
        pushd   this
        _ sbuf_ensure_capacity

        ; char this sbuf-data len + c!
        pushd   char
        pushd   this
        _sbuf_data
        pushd   len
        _plus
        _cstore

        ; this len 1+ sbuf-set-length
        pushd   this
        pushd   len
        _oneplus
        _sbuf_set_length

        ; 0 this sbuf-data len 1+ + c!
        _zero
        pushd   this
        _sbuf_data
        pushd   len
        _oneplus
        _plus
        _cstore

        _locals_leave
        next

%undef this
%undef char
%undef len

endcode

; ### sbuf-append-chars
code sbuf_append_chars, 'sbuf-append-chars' ; sbuf addr len --

; locals:
%define this   local0
%define len    local1
%define addr   local2

        _locals_enter
        popd    len
        popd    addr
        _ check_sbuf
        popd    this

        pushd   this
        _sbuf_length
        pushd   len
        _plus
        pushd   this
        _ sbuf_ensure_capacity
        pushd   addr
        pushd   this
        _sbuf_data
        pushd   this
        _sbuf_length
        _plus
        pushd   len
        _ cmove
        pushd   this
        _dup
        _sbuf_length
        pushd   len
        _plus
        _sbuf_set_length
        _zero
        pushd   this
        _sbuf_data
        pushd   this
        _sbuf_length
        _plus
        _cstore

        _locals_leave
        next

%undef this
%undef len
%undef addr

endcode

; ### sbuf-append-string
code sbuf_append_string, 'sbuf-append-string' ; sbuf string --
        _ string_from
        _ sbuf_append_chars
        next
endcode

; ### sbuf-insert-char
code sbuf_insert_char, 'sbuf-insert-char' ; handle index char --
; locals:
%define sbuf   local0
%define index  local1
%define char   local2

        _locals_enter
        _ check_char
        popd    char
        popd    index
        _ check_sbuf
        popd    sbuf

        ; sbuf sbuf-length 1+ sbuf sbuf-ensure-capacity
        pushd   sbuf
        _sbuf_length
        _oneplus
        pushd   sbuf
        _ sbuf_ensure_capacity

        ; sbuf sbuf-data index +
        pushd   sbuf
        _sbuf_data
        pushd   index
        _plus                           ; -- source

        ; dup 1+
        _dup
        _oneplus                        ; -- source dest

        ; sbuf sbuf-length index - cmove>
        pushd   sbuf
        _sbuf_length
        pushd   index
        _minus                          ; -- source dest count
        _ cmoveup                       ; --

        ; sbuf dup sbuf-length 1+ sbuf-set-length
        pushd   sbuf
        _dup                            ; -- sbuf sbuf
        _sbuf_length                    ; -- sbuf length
        _oneplus                        ; -- sbuf length+1
        _sbuf_set_length

        ; char index sbuf sbuf-set-nth
        pushd   char
        pushd   index
        pushd   sbuf
        _sbuf_set_nth_unsafe

        _locals_leave
        next

%undef sbuf
%undef index
%undef char

endcode

; ### sbuf-delete-char
code sbuf_delete_char, 'sbuf-delete-char' ; sbuf index --
%define sbuf    local0
%define index   local1
%define len     local2

        _locals_enter

        popd    index
        _ check_sbuf
        popd    sbuf                    ; --

        pushd   sbuf
        pushd   index
        _sbuf_check_index
        _if .1
        pushd   sbuf
        _sbuf_length
        popd    len

        ; sbuf sbuf-data index + 1+
        pushd   sbuf
        _sbuf_data
        pushd   index
        _plus
        _oneplus                        ; -- src

        ; dup 1-
        _dup
        _oneminus                       ; -- src dest

        ; len index - 1- cmove
        pushd   len
        pushd   index
        _minus
        _oneminus                       ; -- src dest count
        _ cmove

        ; 0 sbuf sbuf-data len 1- + c!
        _zero
        pushd   sbuf
        _sbuf_data
        pushd   len
        _oneminus
        _plus
        _cstore

        ; sbuf len 1- sbuf-set-length
        pushd   sbuf
        pushd   len
        _oneminus
        _sbuf_set_length

        _else .1
        _true
        _abortq "index out of range"
        _then .1

        _locals_leave
        next

%undef sbuf
%undef index
%undef len
endcode
