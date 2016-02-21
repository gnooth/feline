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

%macro  _this 0
        pushd   r15
%endmacro

%macro  _slot0 0
        _fetch
%endmacro

; Slot 0 is the object header.

; ### slot 0
; returns contents of slot0
inline slot0, 'slot0'                   ; object-addr -- x
        _slot0
endinline

; ### object-header
; DEPRECATED
inline object_header, 'object-header'   ; object -- x
        _slot0
endinline

; ### object-header!
; DEPRECATED
code set_object_header, 'object-header!' ; x object --
        _ store
        next
endcode

; The first word (16 bits) of the object header is the object type.

; Use the first word here and not just the first byte so that the header is
; less likely to be mistaken for the start of a legacy counted string. The
; first byte of a counted string might take on any value at all, but normally
; the second byte won't be zero unless the first byte is also zero. This gives
; us 255 distinct object types (1-255) before we need to set any bits in the
; second byte.

%macro  _object_type 0
        _wfetch                         ; 16 bits
%endmacro

%macro  _set_object_type 0
        _wstore                         ; 16 bits
%endmacro

; ### object-type
inline object_type, 'object-type'       ; object -- type
        _object_type
endinline

; ### set-object-type
inline set_object_type, 'set-object-type' ; type object --
        _set_object_type
endinline

; The third byte of the object header contains the object flags.

%macro  _object_flags 0
        movzx   rbx, byte [rbx + 2]
%endmacro

; ### object-flags
inline object_flags, 'object-flags'     ; object -- flags
        _object_flags
endinline

%macro  _set_object_flags 0
        mov     al, [rbp]
        mov     [rbx + 2], al
        _2drop
%endmacro

; ### set-object-flags
inline set_object_flags, 'set-object-flags' ; flags object --
        _set_object_flags
endinline

%macro  _slot1 0                        ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL]
%endmacro

%macro  _set_slot1 0                    ; x object --
        mov     rax, [rbp]
        mov     [rbx + BYTES_PER_CELL], rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

; ### slot2
; returns contents of slot2
inline slot2, 'slot2'                   ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 2]
endinline

; ### slot2!
code set_slot2, 'slot2!'                ; x object --
        add     rbx, BYTES_PER_CELL * 2
        _store
        next
endcode

; ### slot3
; returns contents of slot1
inline slot3, 'slot3'                   ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 3]
endinline

; ### slot3!
code set_slot3, 'slot3!'                ; x object --
        add     rbx, BYTES_PER_CELL * 3
        _store
        next
endcode

; Vectors

; ### vector?
code vector?, 'vector?'                 ; object -- flag
        test    rbx, rbx
        jz      .1
        _object_type
        cmp     rbx, _OBJECT_TYPE_VECTOR
        jnz     .2
        mov     rbx, -1
        _return
.2:
        xor     ebx, ebx
.1:
        next
endcode

; ### check-vector
code check_vector, 'check-vector'       ; object -- vector
        _dup
        _ vector?
        test    rbx, rbx
        poprbx
        jz      .1
        _return
.1:
        _true
        _abortq "not a vector"
        next
endcode

; ### vector-length
code vector_length, 'vector-length'     ; vector -- length
        _slot1
        next
endcode

; ### vector-length!
code set_vector_length, 'vector-length!' ; length vector --
        _set_slot1
        next
endcode

; ### vector-data
code vector_data, 'vector-data'         ; vector -- data-address
        _ slot2
        next
endcode

; ### vector-data!
code set_vector_data, 'vector-data!'    ; data-address vector --
        _ set_slot2
        next
endcode

; ### vector-capacity
code vector_capacity, 'vector-capacity' ; vector -- capacity
        _ slot3
        next
endcode

; ### vector-capacity!
code set_vector_capacity, 'vector-capacity!' ; capacity vector --
        _ set_slot3
        next
endcode

; ### <vector>
code construct_vector, '<vector>'       ; capacity -- vector
        _lit 4
        _cells
        _ iallocate
        _duptor                         ; -- capacity vector            r: -- vector
        _lit 4
        _cells
        _ erase
        _lit _OBJECT_TYPE_VECTOR
        _rfetch                         ; -- capacity vector            r: -- vector
        _set_object_type                ; -- capacity                   r: -- vector
        _dup                            ; -- capacity capacity          r: -- vector
        _cells
        _ iallocate                     ; -- capacity data-address              r: -- vector
        _rfetch                         ; -- capacity data-address vector       r: -- vector
        _ set_vector_data               ; -- capacity                   r: -- vector
        _rfrom                          ; -- capacity vector
        _ tuck                          ; -- vector capacity vector
        _ set_vector_capacity           ; -- vector
        next
endcode

; ### ~vector
code destroy_vector, '~vector'          ; vector --
;         _ ?dup
;         _if .1
        _ check_vector
        mov     qword [rbx], 0          ; clear type field in object header
        _dup
        _ vector_data
        _ ifree
        _ ifree
;         _then .1
        next
endcode

; ### vector-resize
code vector_resize, 'vector-resize'     ; vector new-capacity --
        _ over                          ; -- vector new-capacity vector
        _ vector_data                   ; -- vector new-capacity data-address
        _ over                          ; -- vector new-capacity data-address new-capacity
        _cells
        _ resize                        ; -- vector new-capacity new-data-address ior
        _ throw                         ; -- vector new-capacity new-data-address
        _tor
        _ over                          ; -- vector new-capacity vector     r: -- new-data-addr
        _ set_vector_capacity           ; -- vector                         r: -- new-data-addr
        _rfrom                          ; -- vector new-data-addr
        _ swap
        _ set_vector_data
        next
endcode

; ### vector-ensure-capacity
code vector_ensure_capacity, 'vector-ensure-capacity'   ; u vector --
        _ twodup                        ; -- u vector u vector
        _ vector_capacity               ; -- u vector u capacity
        _ ugt
        _if .1                          ; -- u vector
        _dup                            ; -- u vector vector
        _ vector_capacity               ; -- u vector capacity
        _twostar                        ; -- u vector capacity*2
        _ rot                           ; -- vector capacity*2 u
        _ max                           ; -- vector new-capacity
        _ vector_resize
        _else .1
        _2drop
        _then .1
        next
endcode

; ### vector-nth
code vector_nth, 'vector-nth'           ; index vector -- elt
        _ twodup
        _ vector_length
        _ ult
        _if .1
        _ vector_data
        _ swap
        _cells
        _plus
        _fetch
        _else .1
        _true
        _abortq "vector-nth index out of range"
        _then .1
        next
endcode

; ### vector-set-nth
code vector_set_nth, 'vector-set-nth'   ; elt index vector --
        _ twodup
        _ vector_length
        _ ult
        _if .1
        _ vector_data
        _ swap
        _cells
        _plus
        _ store
        _else .1
        _true
        _abortq "vector-set-nth index out of range"
        _then .1
        next
endcode

; ### vector-insert-nth
code vector_insert_nth, 'vector-insert-nth'     ; elt n vector --
        push    r15
        mov     r15, rbx                ; -- elt n vector

        _ twodup                        ; -- elt n vector n vector
        _ vector_length                 ; -- elt n vector n length
        _ ugt                           ; -- elt n vector
        _abortq "vector-insert-nth n > length"

        _dup                            ; -- elt n vector vector
        _ vector_length                 ; -- elt n vector length
        _oneplus                        ; -- elt n vector length+1
        _ over                          ; -- elt n vector length+1 vector
        _ vector_ensure_capacity        ; -- elt n vector

        _ vector_data                   ; -- elt n data-address
        _ over                          ; -- elt n data-address n
        _duptor                         ; -- elt n data-address n       r: -- n
        _cells
        _plus                           ; -- elt n addr
        _dup
        _cellplus                       ; -- elt n addr addr+8
        pushd   r15
        _ vector_length
        _rfrom
        _ minus
        _cells                          ; -- elt n addr addr+8 #bytes
        _ cmoveup                       ; -- elt n

        pushd   r15
        _ vector_length
        _oneplus
        pushd   r15
        _ set_vector_length             ; -- elt n

        pushd   r15                     ; -- elt n vector
        _ vector_set_nth                ; ---

        pop     r15
        next
endcode

; ### vector-remove-nth
code vector_remove_nth, 'vector-remove-nth'     ; n vector --
        push    r15
        mov     r15, rbx

        _ twodup
        _ vector_length                 ; -- n vector n length
        _zero                           ; -- n vector n length 0
        _ swap                          ; -- n vector n 0 length
        _ within                        ; -- n vector flag
        _ zeq
        _abortq "vector-remove-nth n > length - 1"      ; -- n vector

        _ vector_data                   ; -- n addr
        _ swap                          ; -- addr n
        _duptor                         ; -- addr n                      r: -- n
        _oneplus
        _cells
        _plus                           ; -- addr2
        _dup                            ; -- addr2 addr2
        _cellminus                      ; -- addr2 addr2-8
        _this
        _ vector_length
        _oneminus                       ; -- addr2 addr2-8 len-1         r: -- n
        _rfrom                          ; -- addr2 addr2-8 len-1 n
        _ minus                         ; -- addr2 addr2-8 len-1-n
        _cells                          ; -- addr2 addr2-8 #bytes
        _ cmove

        _zero
        _this
        _ vector_data
        _this
        _ vector_length
        _oneminus
        _cells
        _plus
        _ store

        _this
        _ vector_length
        _oneminus
        _this
        _ set_vector_length

        pop     r15
        next
endcode

; ### vector-push
code vector_push, 'vector-push'         ; elt vector --
        push    r15                     ; save callee-saved register
        mov     r15, rbx                ; vector in r15
        _ vector_length                 ; -- elt length
        _dup                            ; -- elt length length
        _oneplus                        ; -- elt length length+1
        _dup                            ; -- elt length length+1 length+1
        _this                           ; -- elt length length+1 length+1 this
        _ vector_ensure_capacity        ; -- elt length length+1
        _this                           ; -- elt length length+1 this
        _ set_vector_length             ; -- elt length
        _this                           ; -- elt length this
        _ vector_set_nth
        pop     r15                     ; restore callee-saved register
        next
endcode

; ### vector-pop
code vector_pop, 'vector-pop'           ; vector -- elt
        push    r15
        mov     r15, rbx

        _ vector_length
        _oneminus
        _dup
        _zlt
        _abortq "vector-pop vector is empty"

        _this
        _ vector_nth                    ; -- elt

        _this
        _ vector_length
        _oneminus
        _this
        _ set_vector_length

        pop     r15
        next
endcode

; ### vector-each
code vector_each, 'vector-each'         ; xt vector --
        push    r15
        mov     r15, rbx
        _ vector_length
        _zero
        _?do .1
        _i
        _this
        _ vector_nth                    ; -- xt elt
        _ over                          ; -- xt elt xt
        _ execute
        _loop .1                        ; -- xt
        _drop
        pop     r15
        next
endcode

%unmacro _this 0

; Strings

; ### transient?
code transient?, 'transient?'           ; string -- flag
        _ object_flags
        and     ebx, STRING_TRANSIENT
        _zne
        next
endcode

; ### allocated?
code allocated?, 'allocated?'           ; string -- flag
        _ object_flags
        and     ebx, STRING_ALLOCATED
        _zne
        next
endcode

; ### simple-string?
code simple_string?, 'simple-string?'   ; object -- flag
        test    rbx, rbx
        jz      .1
        _object_type
        cmp     rbx, _OBJECT_TYPE_SIMPLE_STRING
        jnz     .2
        mov     rbx, -1
        _return
.2:
        xor     ebx, ebx
.1:
        next
endcode

; ### growable-string?
code growable_string?, 'growable-string?' ; object -- flag
        test    rbx, rbx
        jz      .1
        _object_type
        cmp     rbx, _OBJECT_TYPE_STRING
        jnz     .2
        mov     rbx, -1
        _return
.2:
        xor     ebx, ebx
.1:
        next
endcode

; ### string?
code string?, 'string?'                 ; object -- flag
        _dup
        _ simple_string?
        _if .1
        _drop
        _true
        _return
        _then .1
        _ growable_string?
        next
endcode

; ### check-string
code check_string, 'check-string'       ; object -- string
        _dup
        _ simple_string?
        _if .1
        _return
        _then .1

        _dup
        _ growable_string?
        _if .2
        _return
        _then .2

        _drop
        _true
        _abortq "not a string"
        next
endcode

; ### check-growable-string
code check_growable_string, 'check-growable-string'     ; object -- string
        _dup
        _ growable_string?
        test    rbx, rbx
        poprbx
        jz      .1
        _return
.1:
        _true
        _abortq "not a growable string"
        next
endcode

; ### string-length
code string_length, 'string-length'     ; string -- length
        _slot1
        next
endcode

; ### set-string-length
code set_string_length, 'set-string-length' ; length string --
        _set_slot1
        next
endcode

; ### simple-string-data
code simple_string_data, 'simple-string-data' ; simple-string -- data-address
        _lit 2
        _cells
        _plus
        next
endcode

; ### string-data
code string_data, 'string-data'         ; string -- data-address
        _ check_string                  ; -- string
        _dup                            ; -- string string
        _ simple_string?                ; -- string flag
        _if .1                          ; -- string
        _ simple_string_data
        _else .1
        _ slot2
        _then .1
        next
endcode

; ### set-string-data
code set_string_data, 'set-string-data' ; data-address string --
        _ set_slot2
        next
endcode

; ### string-capacity
code string_capacity, 'string-capacity' ; string -- capacity
        _ slot3
        next
endcode

; ### set-string-capacity
code set_string_capacity, 'set-string-capacity' ; capacity string --
        _ set_slot3
        next
endcode

; ### make-growable-string
code make_growable_string, 'make-growable-string' ; capacity -- string

; locals:
%define capacity        local0
%define string          local1

        _locals_enter

        popd    capacity

        _lit 32                         ; -- 32
        _dup
        _ iallocate                     ; -- 32 string
        popd    string                  ; -- 32
        pushd   string
        _swap
        _ erase                         ; --
        _ OBJECT_TYPE_STRING
        pushd   string
        _set_object_type               ; --

        _lit STRING_ALLOCATED
        pushd   string
        _set_object_flags              ; --

        pushd   capacity
        _oneplus                        ; terminal null byte
        _ iallocate
        pushd   string
        _ set_string_data

        pushd   capacity
        pushd   string
        _ set_string_capacity           ; --

        pushd   string

        _locals_leave
        next

%undef capacity
%undef string

endcode

; ### <string>
code new_string, '<string>'             ; capacity -- string
        _ make_growable_string          ; -- string
        _ dup
        _ string_data                   ; -- string data-address
        _over
        _ string_capacity               ; -- string data-address capacity
        _oneplus
        _ erase                         ; -- string
        next
endcode

; ### >string
code copy_to_string, '>string'          ; c-addr u -- string

; locals:
%define u      local0
%define c_addr local1
%define string local2

        _locals_enter
        popd    u
        popd    c_addr

        pushd   u
        _ make_growable_string
        popd    string

        pushd   c_addr
        pushd   string
        _ string_data
        pushd   u                       ; -- c-addr data-address u
        _ cmove                         ; --

        _zero
        pushd   string
        _ string_data
        pushd   u
        _plus
        _ cstore

        pushd   u
        pushd   string
        _ set_string_length

        pushd   string

        _locals_leave

        next

%undef u
%undef c_addr
%undef string

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
        _ tsb_alloc                     ; -- size string
        popd    string                  ; -- size
        pushd   string                  ; -- size string
        _swap                           ; -- string size
        _ erase                         ; --
        _ OBJECT_TYPE_SIMPLE_STRING
        pushd   string
        _set_object_type               ; --

        _lit STRING_TRANSIENT
        pushd   string
        _ set_object_flags              ; --

        pushd   capacity
        pushd   string
        _ set_string_length             ; --

        pushd   string                  ; -- string
        _locals_leave
        next

%undef capacity
%undef string

endcode

; ### make-simple-string
code make_simple_string, 'make-simple-string'   ; c-addr u transient? -- string

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
        _ tsb_alloc
        _else .1
        _ iallocate
        _then .1                        ; -- size string
        popd    string                  ; -- size
        pushd   string                  ; -- size string
        _swap                           ; -- string size
        _ erase                         ; --
        _ OBJECT_TYPE_SIMPLE_STRING
        pushd   string
        _set_object_type                ; --

        pushd   transient?
        _if .2
        _lit STRING_TRANSIENT
        _else .2
        _lit STRING_ALLOCATED
        _then .2
        pushd   string
        _set_object_flags               ; --

        pushd   u
        pushd   string
        _ set_string_length             ; --

        pushd   c_addr
        pushd   string
        _ simple_string_data
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

; ### >simple-string
code copy_to_simple_string, '>simple-string' ; c-addr u -- string
        _false                          ; not transient
        _ make_simple_string
        next
endcode

; ### simple-string>
code simple_string_from, 'simple-string>' ; simple-string -- c-addr u
        _duptor
        _ simple_string_data
        _rfrom
        _ string_length
        next
endcode

; ### >static_string
code copy_to_static_string, '>static-string' ; c-addr u -- string
        _ align_data
        _ here                          ; this will be the address of the string
        _tor

        ; object header
        _lit _OBJECT_TYPE_SIMPLE_STRING
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
; A transient string is a simple string with storage in the transient string buffer.
        _true                           ; transient
        _ make_simple_string
        next
endcode

; ### as-c-string
code as_c_string, 'as-c-string'         ; c-addr u -- zaddr
; Returns a pointer to a null-terminated string in the transient string buffer.
        _ copy_to_transient_string
        _ simple_string_data
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
                                        ; -- $addr
        _count
        _ copy_to_transient_string
        next
endcode

; ### string>
code string_from, 'string>'             ; string -- c-addr u
        _duptor
        _ string_data                   ; -- string data-address
        _rfrom
        _ string_length
        next
endcode

; ### ~string
code delete_string, '~string'           ; string --
        _ check_string

        _dup
        _zeq_if .1
        _drop
        _return
        _then .1

        _dup
        _ allocated?
        _if .2
        _dup
        _ growable_string?
        _if .3
        _dup
        _ string_data
        _ ifree
        _then .3
        _ ifree
        _else .2
        _drop
        _then .2
        next
endcode

; ### string-resize
code string_resize, 'string-resize'     ; string new-capacity --
        _ over                          ; -- string new-capacity string
        _ string_data                   ; -- string new-capacity data-address
        _ over                          ; -- string new-capacity data-address new-capacity
        _oneplus                        ; terminal null byte
        _ resize                        ; -- string new-capacity new-data-address ior
        _ throw                         ; -- string new-capacity new-data-address
        _tor
        _ over                          ; -- string new-capacity string     r: -- new-data-addr
        _ set_string_capacity           ; -- string                         r: -- new-data-addr
        _rfrom                          ; -- string new-data-addr
        _ swap
        _ set_string_data
        next
endcode

; ### string-ensure-capacity
code string_ensure_capacity, 'string-ensure-capacity'   ; u string --
        _ check_growable_string         ; -- u string
        _ twodup                        ; -- u string u string
        _ string_capacity               ; -- u string u capacity
        _ ugt
        _if .1                          ; -- u string
        _dup                            ; -- u string string
        _ string_capacity               ; -- u string capacity
        _twostar                        ; -- u string capacity*2
        _oneplus                        ; -- u string capacity*2+1
        _ rot                           ; -- string capacity*2 u
        _ max                           ; -- string new-capacity
        _ string_resize
        _else .1
        _2drop
        _then .1
        next
endcode

; ### .string
code dot_string, '.string'              ; string | $addr --
; REVIEW remove support for legacy strings
        _dup_if .1
        _dup
        _ string?
        _if .2
        _ string_from
        _else .2
        _ count
        _then .2
        _ type
        _else .1
        _drop
        _then .1
        next
endcode

; ### string-nth
code string_nth, 'string-nth'           ; index string -- char
; REVIEW
; Name from Factor, but slightly different behavior.
; Return character at index, or 0 if index is out of range.
        _ check_string

        _twodup
        _ string_length
        _ ult
        _if .1
        _ string_data
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
        _swap
        _ string_nth
        next
endcode

; ### string-last-char
code string_last_char, 'string-last-char' ; string -- char
; Returns last character of string (0 if the string is empty).
        _ coerce_to_string

        _dup
        _ string_length
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

; ### string-append-chars
code string_append_chars, 'string-append-chars' ; addr len string --

; locals:
%define this   local0
%define len    local1
%define addr   local2

        _locals_enter
        popd    this
        popd    len
        popd    addr

        pushd   this
        _ string_length
        pushd   len
        _plus
        pushd   this
        _ string_ensure_capacity
        pushd   addr
        pushd   this
        _ string_data
        pushd   this
        _ string_length
        _plus
        pushd   len
        _ cmove
        pushd   this
        _ string_length
        pushd   len
        _plus
        pushd   this
        _ set_string_length
        _zero
        pushd   this
        _ string_data
        pushd   this
        _ string_length
        _plus
        _cstore

        _locals_leave
        next

%undef this
%undef len
%undef addr

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

        _ tuck                           ; -- c-addr2 u2 u1 c-addr1 u1

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
