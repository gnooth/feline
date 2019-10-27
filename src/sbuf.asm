; Copyright (C) 2015-2019 Peter Graves <gnooth@gmail.com>

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

; Mutable (and growable) strings

; 4 cells: object header, length, data address, capacity

%define SBUF_RAW_LENGTH_OFFSET          8

%define SBUF_RAW_DATA_ADDRESS_OFFSET    16

%macro  _sbuf_raw_length 0              ; sbuf -> length
        _slot1
%endmacro

%macro  _sbuf_set_raw_length 0          ; length sbuf -> void
        _set_slot1
%endmacro

%define this_sbuf_raw_length this_slot1

%macro  _this_sbuf_raw_length 0         ; void -> length
        _this_slot1
%endmacro

%macro  _this_sbuf_set_raw_length 0     ; length -> void
        _this_set_slot1
%endmacro

%macro  _sbuf_data 0                    ; sbuf -- data-address
        _slot2
%endmacro

%macro  _sbuf_set_data 0                ; data-address sbuf --
        _set_slot2
%endmacro

%define this_sbuf_raw_data_address this_slot2

%macro  _this_sbuf_data 0               ; -- data-address
        _this_slot2
%endmacro

%macro  _this_sbuf_set_data 0           ; data-address --
        _this_set_slot2
%endmacro

%macro  _sbuf_raw_capacity 0            ; sbuf -- raw-capacity
        _slot3
%endmacro

%macro  _sbuf_set_raw_capacity 0        ; raw-capacity sbuf --
        _set_slot3
%endmacro

%define this_sbuf_raw_capacity this_slot3

%macro  _this_sbuf_set_raw_capacity 0   ; raw-capacity --
        _this_set_slot3
%endmacro

%macro  _sbuf_check_index 0             ; sbuf index -- -1/0
        _swap
        _sbuf_raw_length                ; -- index length
        _ult                            ; -- flag
%endmacro

%macro  _this_sbuf_check_index 0        ; index -- -1/0
        _this_sbuf_raw_length
        _ult
%endmacro

%macro  _sbuf_nth_unsafe 0              ; sbuf index -- untagged-char
        _sbuf_data
        _plus
        _cfetch
%endmacro

%macro  _this_sbuf_nth_unsafe 0         ; index -> untagged-char
        mov     rdx, qword [this_register + SBUF_RAW_DATA_ADDRESS_OFFSET]
        movzx   rbx, byte [rdx + rbx]
%endmacro

%macro  _this_sbuf_set_nth_unsafe 0     ; untagged-char index -> void
        mov     rdx, qword [this_register + SBUF_RAW_DATA_ADDRESS_OFFSET]
        mov     al, [rbp]
        mov     [rdx + rbx], al
        _2drop
%endmacro

; ### sbuf?
code sbuf?, 'sbuf?'                     ; object -> ?
        cmp     bl, HANDLE_TAG
        jne     .no
        _handle_to_object_unsafe
        test    rbx, rbx
        jz      .no
        cmp     word [rbx], TYPECODE_SBUF
        jne     .no
        mov     ebx, t_value
        next
.no:
        mov     ebx, nil_value
        next
endcode

; ### check_sbuf
code check_sbuf, 'check_sbuf'           ; handle -> ^sbuf
        cmp     bl, HANDLE_TAG
        jne     .error2
        mov     rdx, rbx                ; copy argument in case there is an error
        _handle_to_object_unsafe
%ifdef DEBUG
        test    rbx, rbx
        jz      error_empty_handle
%endif
        cmp     word [rbx], TYPECODE_SBUF
        jne     .error1
        next
.error1:
        mov     rbx, rdx                ; restore original argument
.error2:
        jmp     error_not_sbuf
endcode

; ### sbuf-length
code sbuf_length, 'sbuf-length'         ; handle -- length
        _ check_sbuf
        _sbuf_raw_length
        _tag_fixnum
        next
endcode

; ### sbuf-capacity
code sbuf_capacity, 'sbuf-capacity'     ; sbuf -- capacity
        _ check_sbuf
        _sbuf_raw_capacity
        _tag_fixnum
        next
endcode

; ### make_sbuf_internal
code make_sbuf_internal, 'make_sbuf_internal', SYMBOL_INTERNAL
; untagged-capacity -- sbuf
        _lit 4
        _ raw_allocate_cells            ; -- capacity addr

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- capacity

        _this_object_set_raw_typecode TYPECODE_SBUF
        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _dup
        _oneplus                        ; terminal null byte
        _ raw_allocate
        _this_sbuf_set_data             ; -- capacity

        _this_sbuf_set_raw_capacity

        pushrbx
        mov     rbx, this_register      ; -- sbuf

        pop     this_register
        next
endcode

; ### <sbuf>
code new_sbuf, '<sbuf>'                 ; tagged-capacity -- sbuf
        _check_index
new_sbuf_untagged:
        _ make_sbuf_internal            ; -- sbuf
        _dup
        _sbuf_data                      ; -- sbuf data-address
        _over
        _sbuf_raw_capacity              ; -- sbuf data-address capacity
        _oneplus
        _ raw_erase_bytes               ; -- sbuf
        _ new_handle
        next
endcode

; ### copy_to_sbuf
code copy_to_sbuf, 'copy_to_sbuf', SYMBOL_INTERNAL
; from-addr length -- handle
        _dup
        _ make_sbuf_internal

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- from-addr length

        _dup
        _this_sbuf_set_raw_length

        _this_sbuf_data                 ; -- from-addr length to-address
        _swap
        _ cmove                         ; --

        _zero
        _this_sbuf_data
        _this_sbuf_raw_length
        _plus
        _cstore

        pushrbx
        mov     rbx, this_register

        _ new_handle

        pop     this_register
        next
endcode

; ### string>sbuf
code string_to_sbuf, 'string>sbuf'      ; handle-or-string -- handle
        _ string_from
        _ copy_to_sbuf
        next
endcode

; ### sbuf_from
code sbuf_from, 'sbuf_from', SYMBOL_INTERNAL    ; handle -- c-addr u
        _ check_sbuf
        _duptor
        _sbuf_data
        _rfrom
        _sbuf_raw_length
        next
endcode

; ### this_sbuf_to_string
code this_sbuf_to_string, 'this_sbuf_to_string', SYMBOL_INTERNAL        ; -- string
        _this_sbuf_data
        _this_sbuf_raw_length
        _ copy_to_string
        next
endcode

; ### sbuf>string
code sbuf_to_string, 'sbuf>string'      ; handle -- string
        _ sbuf_from
        _ copy_to_string
        next
endcode

; ### destroy_sbuf
code destroy_sbuf, 'destroy_sbuf', SYMBOL_INTERNAL
; sbuf --

        _dup
        _sbuf_data
        _ raw_free

        ; zero out object header
        xor     eax, eax
        mov     [rbx], rax

        _ raw_free
        next
endcode

; ### sbuf-nth-unsafe
code sbuf_nth_unsafe, 'sbuf-nth-unsafe' ; tagged-index handle -- tagged-char
; no bounds check
        _check_index qword [rbp]
        _ check_sbuf
        _sbuf_nth_unsafe
        _tag_char
        next
endcode

; ### sbuf-nth
code sbuf_nth, 'sbuf-nth'               ; index sbuf -- char
; Return character at index.

        _ check_sbuf
        _check_index qword [rbp]

        _twodup
        _sbuf_raw_length
        _ult
        _if .1
        _sbuf_nth_unsafe
        _tag_char
        _else .1
        _2drop
        _error "index out of bounds"
        _then .1

        next
endcode

; ### sbuf-?last
code sbuf_?last, 'sbuf-?last'           ; sbuf -- char/f
        _dup
        _ sbuf_length
        _untag_fixnum
        _oneminus
        _dup
        _zge
        _if .1                          ; -- sbuf untagged-fixnum
        _tag_fixnum
        _swap
        _ sbuf_nth_unsafe
        _else .1
        _2drop
        _f
        _then .1
        next
endcode

; ### sbuf-check-index
code sbuf_check_index, 'sbuf-check-index'       ; handle index -- flag
        _swap
        _ check_sbuf                    ; -- index sbuf
        _swap
        _sbuf_check_index
        next
endcode

; ### sbuf_resize
code sbuf_resize, 'sbuf_resize', SYMBOL_INTERNAL
; raw-sbuf untagged-new-capacity --

        _swap

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- new-capacity

        _this_sbuf_data                 ; -- new-capacity data-address

        _over                           ; -- new-capacity data-address new-capacity
        _oneplus                        ; terminal null byte
        _ raw_realloc                   ; -- new-capacity new-data-address

        _this_sbuf_set_data
        _this_sbuf_set_raw_capacity

        pop     this_register
        next
endcode

; ### sbuf_ensure_capacity
code sbuf_ensure_capacity, 'sbuf_ensure_capacity', SYMBOL_INTERNAL
; untagged-fixnum raw-sbuf -> void
        _twodup                         ; -> n sbuf n sbuf
        _sbuf_raw_capacity              ; -> n sbuf n capacity
        cmp     [rbp], rbx
        jg      .1
        _4drop
        _return
.1:
        _2drop
        _dup                            ; -> n sbuf sbuf
        _sbuf_raw_capacity              ; -> n sbuf capacity
        _twostar                        ; -> n sbuf capacity*2
        _oneplus                        ; -> n sbuf capacity*2+1
        _ rot                           ; -> sbuf capacity*2 n
        _max                            ; -> sbuf new-capacity
        _ sbuf_resize
        next
endcode

; ### sbuf-validate
code sbuf_validate, 'sbuf-validate'     ; sbuf --

        _ check_sbuf

        push    this_register
        mov     this_register, rbx      ; -- sbuf
        _sbuf_data                      ; -- data-address
        add     rbx, qword [this_register + SBUF_RAW_LENGTH_OFFSET] ; add length to data address
        mov     al, [rbx]               ; char in al should be 0
        poprbx
        test    al, al
        jz      .1
        _error "sbuf not null-terminated"
.1:
        pop     this_register
        next
endcode

; ### sbuf-shorten
code sbuf_shorten, 'sbuf-shorten'       ; n sbuf -> void
; shortens sbuf to be n bytes long

        _ check_sbuf                    ; -> n raw-sbuf

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -> n

        _check_index                    ; -> raw-index

        _this_sbuf_raw_length           ; -> raw-index raw-length
        cmp     rbx, [rbp]
        jle     .nothing_to_do

        _drop
        _this_sbuf_set_raw_length

        ; store terminal null byte
        mov     rax, qword [this_register + SBUF_RAW_DATA_ADDRESS_OFFSET]
        add     rax, qword [this_register + SBUF_RAW_LENGTH_OFFSET]
        mov     byte [rax], 0

        pop     this_register
        next

.nothing_to_do:
        _2drop
        pop     this_register
        next
endcode

; ### this_sbuf_push_raw_unsafe
code this_sbuf_push_raw_unsafe, 'this_sbuf_push_raw_unsafe', SYMBOL_INTERNAL
; untagged-char --
        _this_sbuf_raw_length
        _this_sbuf_set_nth_unsafe
        add     this_sbuf_raw_length, 1
        next
endcode

; ### sbuf-push-unsafe
code sbuf_push_unsafe, 'sbuf-push-unsafe', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; tagged-char sbuf -> void
        _ check_sbuf

        push    this_register
        mov     this_register, rbx
        poprbx

        _check_char
        _ this_sbuf_push_raw_unsafe

        pop     this_register
        next
endcode

; ### sbuf-push
code sbuf_push, 'sbuf-push'             ; tagged-char sbuf -> void
        _ check_sbuf

        _verify_char [rbp]
        _untag_char qword [rbp]

        push    this_register           ; save callee-saved register
        mov     this_register, rbx      ; ^sbuf in this_register

        _sbuf_raw_length                ; -- char length
        cmp     rbx, this_sbuf_raw_capacity
        jnl     .1

        _this_sbuf_set_nth_unsafe

        add     this_sbuf_raw_length, 1

        pop     this_register
        _return

.1:
        _dup                            ; -- char length length
        _oneplus                        ; -- char length length+1
        _dup                            ; -- char length length+1 length+1
        _this                           ; -- char length length+1 length+1 this
        _ sbuf_ensure_capacity          ; -- char length length+1
        _this_sbuf_set_raw_length       ; -- char length
        _this_sbuf_set_nth_unsafe       ; --

        pop     this_register
        next
endcode

; ### sbuf_append_chars
code sbuf_append_chars, 'sbuf_append_chars', SYMBOL_INTERNAL
; sbuf raw-address raw-length --

        _ rot
        _ check_sbuf

        push    this_register
        mov     this_register, rbx

        _sbuf_raw_length                        ; -- address length old-length
        add     rbx, qword [rbp]                ; -- address length new-length

        _this
        _ sbuf_ensure_capacity                  ; -- address length

        push    rbx                             ; -- address length      r: -- length

        _this_sbuf_data
        add     rbx, this_sbuf_raw_length       ; -- address length dest r: -- length

        _swap
        _ cmove                                 ; --    r: -- from-length

        pop     rax
        add     this_sbuf_raw_length, rax

        mov     rax, this_sbuf_raw_data_address
        add     rax, this_sbuf_raw_length
        mov     byte [rax], 0

        pop     this_register
        next
endcode

; ### sbuf-append-string
code sbuf_append_string, 'sbuf-append-string'   ; string sbuf --
; Modify sbuf by adding the characters of string to the end.
        _swap
        _ string_from
        _ sbuf_append_chars
        next
endcode

; ### sbuf-insert-nth!
code sbuf_insert_nth, 'sbuf-insert-nth!'        ; char index sbuf --

        _ check_sbuf

        push    this_register
        popd    this_register           ; -- char index

        _check_char qword [rbp]
        _check_index

        _dup
        _this_sbuf_check_index          ; -- char index -1/0
        _zeq_if .1
        _error "index out of range"
        _then .1                        ; -- char index

        _this_sbuf_raw_length
        _oneplus
        _this
        _ sbuf_ensure_capacity          ; -- char index

        mov     rax, qword [this_register + SBUF_RAW_LENGTH_OFFSET] ; length in rax
        sub     rax, rbx                ; subtract index to get count in rax

        _this_sbuf_data                 ; -- char index data-address
        add     rbx, qword [rbp]        ; -- char index source
        _dup
        _oneplus                        ; -- char index source dest

        pushrbx
        mov     rbx, rax                ; -- char index source dest count

        _ cmoveup                       ; -- char index

        inc     qword [this_register + SBUF_RAW_LENGTH_OFFSET] ; length = length + 1

        _this_sbuf_set_nth_unsafe       ; --

        pop     this_register

        next
endcode

; ### sbuf-remove-nth!
code sbuf_remove_nth_destructive, 'sbuf-remove-nth!' ; tagged-index handle -- handle
        _tuck                           ; -- handle tagged-index handle

        _ check_sbuf                    ; -- handle tagged-index sbuf

        push    this_register
        popd    this_register           ; -- handle tagged-index

        _untag_fixnum                   ; -- handle untagged-index

        _dup
        _this_sbuf_check_index          ; -- handle index -1/0
        _zeq_if .1
        _error "index out of range"
        _then .1                        ; -- handle index

        _this_sbuf_data                 ; -- handle index data-address
        _over                           ; -- handle index data-address index
        _plus
        _oneplus                        ; -- handle index src
        _dup
        _oneminus                       ; -- handle index src dest

        _ rot                           ; -- handle src dest index
        _this_sbuf_raw_length           ; -- handle src dest index length
        _swapminus
        _oneminus
        _ cmove                         ; -- handle

        _this_sbuf_raw_length
        _oneminus
        _this_sbuf_set_raw_length

        pop     this_register
        next
endcode

; ### this_sbuf_reverse
code this_sbuf_reverse, 'this_sbuf_reverse', SYMBOL_INTERNAL

        _this_sbuf_raw_length

        ; divide by 2
        shr     rbx, 1

        _register_do_times .1

        _raw_loop_index
        _this_sbuf_nth_unsafe           ; -- char1

        _this_sbuf_raw_length
        sub     rbx, 1
        sub     rbx, index_register
        _this_sbuf_nth_unsafe           ; -- char1 char2

        _raw_loop_index
        _this_sbuf_set_nth_unsafe

        _this_sbuf_raw_length
        sub     rbx, 1
        sub     rbx, index_register
        _this_sbuf_set_nth_unsafe

        _loop .1

        next
endcode

; ### sbuf-reverse!
code sbuf_reverse_in_place, 'sbuf-reverse!'     ; sbuf -- sbuf

        _duptor

        _ check_sbuf

        push    this_register
        mov     this_register, rbx
        poprbx

        _ this_sbuf_reverse

        pop     this_register

        _rfrom

        next
endcode

; ### write-sbuf
code write_sbuf, 'write-sbuf'           ; sbuf --
        _ sbuf_from                     ; -- addr len
        call    unsafe_raw_write_chars
        next
endcode

; ### sbuf-substring
code sbuf_substring, 'sbuf-substring'   ; from to sbuf -> substring

        _ check_sbuf

        push    this_register
        popd    this_register           ; -> from to

        _check_index qword [rbp]
        _check_index                    ; -> from to (untagged)

        _dup
        _this_sbuf_raw_length           ; -> from to to raw-length
        cmp     [rbp], rbx
        _2drop
        jle     .1
        _error "end index out of range"
.1:                                     ; -> from to
        cmp     [rbp], rbx
        jle     .2
        _error "start index > end index"
.2:                                     ; -> from to
        sub     rbx, qword [rbp]        ; length in rbx = to - from
        mov     rax, [this_register + SBUF_RAW_DATA_ADDRESS_OFFSET]
        add     qword [rbp], rax        ; address of start of substring
        _ copy_to_string

        pop     this_register
        next
endcode
