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

; ### string?
code string?, 'string?'                 ; object -- flag
        test    rbx, rbx
        jz      .1
        _object_type
        cmp     rbx, OBJECT_TYPE_STRING
        jnz     .2
        mov     rbx, -1
        _return
.2:
        xor     ebx, ebx
.1:
        next
endcode

; ### check-string
code check_string, 'check-string'       ; object -- string
        _dup
        _ string?
        _if .1
        _return
        _then .1
        _drop
        _true
        _abortq "not a string"
        next
endcode

%macro _string_length 0                 ; string -- length
        _slot1
%endmacro

%macro _this_string_length 0            ; -- length
        _this_slot1
%endmacro

; ### string-length
code string_length, 'string-length'     ; string -- length
        _ check_string
        _string_length
        next
endcode

; ### string-set-length
code string_set_length, 'string-set-length' ; string length --
        _set_slot1
        next
endcode

; Strings store their character data inline starting at this + 16 bytes.
%macro _string_data 0
        lea     rbx, [rbx + BYTES_PER_CELL * 2]
%endmacro

%macro _this_string_data 0
        pushrbx
        lea     rbx, [this + BYTES_PER_CELL * 2]
%endmacro

; ### string-data
code string_data, 'string-data'         ; string -- data-address
        _ check_string                  ; -- string
        _string_data
        next
endcode

; ### <transient-string>
code new_transient_string, '<transient-string>' ; capacity -- string

; locals:
%define capacity        local0
%define string          local1

        _locals_enter                   ; -- capacity
        popd    capacity                ; --

        _lit 16
        pushd capacity
        _oneplus                        ; terminal null byte
        _plus                           ; -- size
        _dup
        _ transient_alloc               ; -- size string
        popd    string                  ; -- size
        pushd   string                  ; -- size string
        _swap                           ; -- string size
        _ erase                         ; --
        pushd   string
        _lit OBJECT_TYPE_STRING
        _object_set_type                ; --

        pushd   string
        _lit TRANSIENT
        _object_set_flags               ; --

        pushd   string
        pushd   capacity
        _ string_set_length             ; --

        pushd   string                  ; -- string
        _locals_leave
        next

%undef capacity
%undef string

endcode

; ### make-string
code make_string, 'make-string'         ; c-addr u transient? -- string

; locals:
%define transient?      local0
%define u               local1
%define c_addr          local2
%define string          local3

        _locals_enter                   ; -- c-addr u transient?
        popd    transient?
        popd    u
        popd    c_addr                  ; --

        _lit 16
        pushd   u
        _oneplus                        ; terminal null byte
        _plus                           ; -- size
        _dup
        pushd   transient?
        _if .1
        _ transient_alloc
        _else .1
        _ allocate_object
        _dup
        _ add_allocated_object
        _then .1                        ; -- size string
        popd    string                  ; -- size
        pushd   string                  ; -- size string
        _swap                           ; -- string size
        _ erase                         ; --
        pushd   string
        _lit OBJECT_TYPE_STRING
        _object_set_type                ; --

        pushd   transient?
        _if .3
        pushd   string
        _lit TRANSIENT
        _else .3
        pushd   string
        _lit ALLOCATED
        _then .3
        _object_set_flags               ; --

        pushd   string
        pushd   u
        _ string_set_length             ; --

        pushd   c_addr
        pushd   string
        _string_data
        pushd   u
        _ cmove                         ; --

        pushd   string                  ; -- string
        _locals_leave
        next

%undef transient?
%undef u
%undef c_addr
%undef string

endcode

; ### >string
code copy_to_string, '>string'          ; c-addr u -- string
        _false                          ; not transient
        _ make_string
        next
endcode

; ### string>
code string_from, 'string>'             ; string -- c-addr u
        _ check_string
        _duptor
        _string_data
        _rfrom
        _string_length
        next
endcode

; ### >static-string
code copy_to_static_string, '>static-string' ; c-addr u -- string
        _ align_data
        _ here                          ; this will be the address of the string
        _tor

        ; object header
        _lit OBJECT_TYPE_STRING
        _ comma
        ; length
        _dup
        _ comma                         ; -- c-addr u

        _ here                          ; -- c-addr u here
        _over                           ; -- c-addr u here u
        _oneplus                        ; -- c-addr u here u+1
        _ allot
        _ zplace                        ; --

        _rfrom                          ; -- string
        next
endcode

; ### >transient-string
code copy_to_transient_string, '>transient-string' ; c-addr u -- string
        _true                           ; transient
        _ make_string
        next
endcode

; ### ~string
code destroy_string, '~string'          ; string --
        _ check_string

        _dup
        _zeq_if .1
        _drop
        _return
        _then .1

        _dup
        _ transient?
        _if .2
        ; Zero out the object header so it won't look like a valid object
        ; after it has been destroyed.
        xor     eax, eax
        mov     [rbx], rax
        _drop
        _return
        _then .2

        _dup
        _ allocated?
        _if .3
        ; Zero out the object header so it won't look like a valid object
        ; after it has been destroyed.
        xor     eax, eax
        mov     [rbx], rax

        _ in_gc?
        _zeq_if .4
        ; Not in gc. Update the allocated-objects vector. (If we are in gc,
        ; we don't need to update the allocated-objects vector because we
        ; replace it with the live-objects vector at the end of gc.)
        _dup
        _ remove_allocated_object
        _then .4
        _ ifree

        _else .3
        _drop
        _then .3
        next
endcode

; ### as-c-string
code as_c_string, 'as-c-string'         ; c-addr u -- zaddr
; Returns a pointer to a null-terminated string in the transient string buffer.
        _ copy_to_transient_string
        _string_data
        next
endcode

; ### coerce-to-string
; REVIEW transitional
code coerce_to_string, 'coerce-to-string' ; c-addr u | string | $addr -- string
        _dup
        _lit 256
        _ ult
        _if .1                          ; -- c-addr u
        _ copy_to_transient_string
        _return
        _then .1

        _dup
        _ string?
        _if .2                          ; -- string
        _return
        _then .2

        _dup
        _ sbuf?
        _if .3                          ; -- sbuf
        _ sbuf_to_transient_string      ; -- string
        _return
        _then .3
                                        ; -- $addr
        _count
        _ copy_to_transient_string
        next
endcode

; ### string-char
code string_char, 'string-char'         ; string index -- char
; Return character at index, or 0 if index is out of range.
        _ swap
        _ check_string                  ; -- index string

        _twodup
        _string_length
        _ ult
        _if .1
        _string_data
        _swap
        _plus
        _cfetch
        _else .1
        _2drop
        _zero
        _then .1
        next
endcode

; ### string-first-char
code string_first_char, 'string-first-char' ; string -- char
; Returns first character of string (0 if the string is empty).
        _ coerce_to_string
        _zero
        _ string_char
        next
endcode

; ### string-last-char
code string_last_char, 'string-last-char' ; string -- char
; Returns last character of string (0 if the string is empty).
        _ coerce_to_string

        _dup
        _string_length
        _dup
        _zeq_if .1
        _2drop
        _zero
        _else .1
        _ swap
        _ string_data
        _plus
        _oneminus
        _cfetch
        _then .1
        next
endcode

; ### string-index-of
code string_index_of, 'string-index-of' ; string char -- index | -1
        _swap
        _ check_string
        push    r15
        popd    r15                     ; -- char

        _this_string_length
        _zero
        _?do .1
        _this
        _i
        _ string_char
        _over
        _equal
        _if .2
        _drop
        _i
        _unloop
        jmp     .exit
        _then .2
        _loop .1
        _drop
        _lit -1
.exit:
        pop     r15
        next
endcode

; ### string-substring
code string_substring, 'string-substring' ; string start-index end-index --
        _ rot
        _ check_string
        push    r15
        popd    r15                     ; -- start-index end-index

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
        _ copy_to_transient_string

        pop     r15
        next
endcode

; ### .string
code dot_string, '.string'              ; string | sbuf | $addr --
; REVIEW remove support for legacy strings
        _dup_if .1

        _dup
        _ sbuf?
        _if .2
        _duptor
        ; FIXME inline
        _ sbuf_data
        _rfrom
        ; FIXME inline
        _ sbuf_length
        _ type
        _return
        _then .2

        _dup
        _ string?
        _if .3
        _ string_from
        _else .3
        _ count
        _then .3
        _ type
        _else .1
        _drop
        _then .1
        next
endcode

; ### concat
code concat, 'concat'                   ; string1 string2 -- string3
        _locals_enter

        _ check_string
        _ string_from                   ; -- s1 c-addr2 u2
        _ rot                           ; -- c-addr2 u2 s1
        _ string_from                   ; -- c-addr2 u2 c-addr1 u1
        _lit 2
        _ pick                          ; -- c-addr2 u2 c-addr1 u1 u2
        _overplus                       ; -- c-addr2 u2 c-addr1 u1 u2+u1
        _ new_transient_string          ; -- c-addr2 u2 c-addr1 u1 string3
        _to_local0                      ; -- c-addr2 u2 c-addr1 u1

        _ tuck                          ; -- c-addr2 u2 u1 c-addr1 u1

        _local0
        _ string_data                   ; -- c-addr2 u2 u1 c-addr1 u1 data-address
        _swap                           ; -- c-addr2 u2 u1 c-addr1 data-address u1
        _ cmove                         ; -- c-addr2 u2 u1
        _local0
        _ string_data                   ; -- c-addr2 u2 u1 data-address
        _plus
        _swap
        _ cmove

        _local0                         ; -- string

        _locals_leave
        next
endcode

; ### string=
code stringequal, 'string='             ; string1 string2 -- flag
        _ string_from
        _ rot
        _ string_from
        _ strequal
        next
endcode
