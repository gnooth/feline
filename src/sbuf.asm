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
        test    rbx, rbx
        jz      .1
        _object_type
        cmp     rbx, OBJECT_TYPE_SBUF
        jnz     .2
        mov     rbx, -1
        _return
.2:
        xor     ebx, ebx
.1:
        next
endcode

; ### check-sbuf
code check_sbuf, 'check-sbuf'           ; object -- sbuf
        _dup
        _ sbuf?
        _if .1
        _return
        _then .1

        _drop
        _true
        _abortq "not an sbuf"
        next
endcode

; ### sbuf-length
code sbuf_length, 'sbuf-length'         ; sbuf -- length
        _ check_sbuf
        _slot1
        next
endcode

; ### sbuf-set-length
code sbuf_set_length, 'sbuf-set-length' ; length sbuf --
        _ check_sbuf
        _set_slot1
        next
endcode

; ### sbuf-data
code sbuf_data, 'sbuf-data'             ; sbuf -- data-address
        _ check_sbuf
        _slot2
        next
endcode

; ### sbuf-set-data
code sbuf_set_data, 'sbuf-set-data'     ; sbuf -- data-address
        _ check_sbuf
        _set_slot2
        next
endcode

; ### sbuf-capacity
code sbuf_capacity, 'sbuf-capacity'     ; sbuf -- capacity
        _ check_sbuf
        _slot3
        next
endcode

; ### sbuf-set-capacity
code sbuf_set_capacity, 'sbuf-set-capacity' ; capacity sbuf --
        _ check_sbuf
        _set_slot3
        next
endcode

; ### make-sbuf
code make_sbuf, 'make-sbuf'             ; capacity -- sbuf

; locals:
%define capacity        local0
%define sbuf            local1

        _locals_enter

        popd    capacity

        _lit 32                         ; -- 32
        _dup
        _ iallocate                     ; -- 32 sbuf
        popd    sbuf                    ; -- 32
        pushd   sbuf
        _swap
        _ erase                         ; --
        _lit OBJECT_TYPE_SBUF
        pushd   sbuf
        _set_object_type                ; --

        _lit ALLOCATED
        pushd   sbuf
        _set_object_flags               ; --

        pushd   capacity
        _oneplus                        ; terminal null byte
        _ iallocate
        pushd   sbuf
        _ sbuf_set_data

        pushd   capacity
        pushd   sbuf
        _ sbuf_set_capacity             ; --

        pushd   sbuf

        _locals_leave
        next

%undef capacity
%undef sbuf

endcode

; ### <sbuf>
code new_sbuf, '<sbuf>'                 ; capacity -- sbuf
        _ make_sbuf                     ; -- sbuf
        _ dup
        _ sbuf_data                     ; -- sbuf data-address
        _over
        _ sbuf_capacity                 ; -- sbuf data-address capacity
        _oneplus
        _ erase                         ; -- sbuf
        next
endcode

; ### >sbuf
code copy_to_sbuf, '>sbuf'              ; c-addr u -- sbuf

; locals:
%define u      local0
%define c_addr local1
%define sbuf   local2

        _locals_enter
        popd    u
        popd    c_addr

        pushd   u
        _ make_sbuf
        popd    sbuf

        pushd   c_addr
        pushd   sbuf
        _ sbuf_data
        pushd   u                       ; -- c-addr data-address u
        _ cmove                         ; --

        _zero
        pushd   sbuf
        _ sbuf_data
        pushd   u
        _plus
        _ cstore

        pushd   u
        pushd   sbuf
        _ sbuf_set_length

        pushd   sbuf

        _locals_leave

        next

%undef u
%undef c_addr
%undef sbuf

endcode

; ### sbuf>string
code sbuf_to_string, 'sbuf>string'      ; sbuf -- string
        _ check_sbuf
        _duptor
        _ sbuf_data
        _rfrom
        _ sbuf_length
        _ copy_to_string
        next
endcode

; ### sbuf>transient-string
code sbuf_to_transient_string, 'sbuf>transient-string' ; sbuf -- string
        _ check_sbuf
        _duptor
        _ sbuf_data
        _rfrom
        _ sbuf_length
        _ copy_to_transient_string
        next
endcode

; ### ~sbuf
code delete_sbuf, '~sbuf'               ; sbuf --
        _ check_sbuf

        _dup
        _zeq_if .1
        _drop
        _return
        _then .1

        _dup
        _ allocated?
        _if .2
        _dup
        _ sbuf?
        _if .3
        _dup
        _ sbuf_data
        _ ifree
        _then .3                        ; -- string
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

; ### sbuf-char
code sbuf_char, 'sbuf-char'             ; sbuf index -- char
; REVIEW Return character at index, or 0 if index is out of range.
        _swap
        _ check_sbuf                    ; -- index sbuf

        _twodup
        _ sbuf_length
        _ ult
        _if .1
        _ sbuf_data
        _swap
        _plus
        _cfetch
        _else .1
        _2drop
        _zero
        _then .1
        next
endcode

; ### sbuf-resize
code sbuf_resize, 'sbuf-resize'         ; sbuf new-capacity --
        _ over                          ; -- sbuf new-capacity sbuf
        _ sbuf_data                     ; -- sbuf new-capacity data-address
        _ over                          ; -- sbuf new-capacity data-address new-capacity
        _oneplus                        ; terminal null byte
        _ resize                        ; -- sbuf new-capacity new-data-address ior
        _ throw                         ; -- sbuf new-capacity new-data-address
        _tor
        _ over                          ; -- sbuf new-capacity sbuf     r: -- new-data-addr
        _ sbuf_set_capacity             ; -- sbuf                         r: -- new-data-addr
        _rfrom                          ; -- sbuf new-data-addr
        _ swap
        _ sbuf_set_data
        next
endcode

; ### sbuf-ensure-capacity
code sbuf_ensure_capacity, 'sbuf-ensure-capacity'   ; u sbuf --
        _ check_sbuf                    ; -- u sbuf
        _ twodup                        ; -- u sbuf u sbuf
        _ sbuf_capacity                 ; -- u sbuf u capacity
        _ ugt
        _if .1                          ; -- u sbuf
        _dup                            ; -- u sbuf sbuf
        _ sbuf_capacity                 ; -- u sbuf capacity
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
        _ sbuf_length
        pushd   len
        _plus
        pushd   this
        _ sbuf_ensure_capacity
        pushd   addr
        pushd   this
        _ sbuf_data
        pushd   this
        _ sbuf_length
        _plus
        pushd   len
        _ cmove
        pushd   this
        _ sbuf_length
        pushd   len
        _plus
        pushd   this
        _ sbuf_set_length
        _zero
        pushd   this
        _ sbuf_data
        pushd   this
        _ sbuf_length
        _plus
        _cstore

        _locals_leave
        next

%undef this
%undef len
%undef addr

endcode

; ### check-char
code check_char, 'check-char'           ; char -- char
        _dup
        _lit 256
        _ ult
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
        _ sbuf_length
        popd    len

        ; len 1+ this sbuf-ensure-capacity
        pushd   len
        _oneplus
        pushd   this
        _ sbuf_ensure_capacity

        ; char this sbuf-data len + c!
        pushd   char
        pushd   this
        _ sbuf_data
        pushd   len
        _plus
        _cstore

        ; len 1+ this sbuf-set-length
        pushd   len
        _oneplus
        pushd   this
        _ sbuf_set_length

        ; 0 this sbuf-data len 1+ + c!
        _zero
        pushd   this
        _ sbuf_data
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

; ### sbuf-append-string
code sbuf_append_string, 'sbuf-append-string' ; sbuf string --
        _ check_string
        _swap
        _ check_sbuf
        _swap                           ; -- sbuf string
        _ string_from
        _ sbuf_append_chars
        next
endcode
