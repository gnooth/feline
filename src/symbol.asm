; Copyright (C) 2016-2018 Peter Graves <gnooth@gmail.com>

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

; 12 slots: object header, name, vocab name, hashcode, def, props,
; value, raw code address, raw code size, flags, file, line number

%macro  _symbol_name 0                  ; symbol -- name
        _slot1
%endmacro

%macro  _this_symbol_name 0             ; -- name
        _this_slot1
%endmacro

%macro  _this_symbol_set_name 0         ; name --
        _this_set_slot1
%endmacro

%macro  _symbol_vocab_name 0            ; symbol -- vocab-name
        _slot2
%endmacro

%macro  _this_symbol_vocab_name 0       ; -- vocab-name
        _this_slot2
%endmacro

%macro  _this_symbol_set_vocab_name 0   ; vocab-name --
        _this_set_slot2
%endmacro

%macro  _symbol_hashcode 0              ; symbol -- hashcode
        _slot3
%endmacro

%macro  _symbol_set_hashcode 0          ; hashcode symbol --
        _set_slot3
%endmacro

%macro  _this_symbol_hashcode 0         ; -- hashcode
        _this_slot3
%endmacro

%macro  _this_symbol_set_hashcode 0     ; hashcode --
        _this_set_slot3
%endmacro

%macro  _symbol_def 0                   ; symbol -- definition
        _slot4
%endmacro

%macro  _symbol_set_def 0               ; definition symbol --
        _set_slot4
%endmacro

%macro  _this_symbol_def 0              ; -- definition
        _this_slot4
%endmacro

%macro  _this_symbol_set_def 0          ; definition --
        _this_set_slot4
%endmacro

%macro  _symbol_props 0
        _slot5
%endmacro

%macro  _symbol_set_props 0             ; props symbol --
        _set_slot5
%endmacro

%macro  _this_symbol_props 0            ; -- props
        _this_slot5
%endmacro

%macro  _this_symbol_set_props 0        ; props --
        _this_set_slot5
%endmacro

%define SYMBOL_VALUE_OFFSET     BYTES_PER_CELL * 6

%macro  _symbol_value 0                 ; symbol -- value
        _slot 6
%endmacro

%macro  _symbol_set_value 0             ; value symbol --
        _set_slot 6
%endmacro

%macro  _this_symbol_set_value 0        ; value --
        _this_set_slot 6
%endmacro

%define SYMBOL_RAW_CODE_ADDRESS_OFFSET  BYTES_PER_CELL * 7

%macro  _symbol_raw_code_address 0      ; symbol -- raw-code-address
        _slot 7
%endmacro

%macro  _symbol_set_raw_code_address 0  ; raw-code-address symbol --
        _set_slot 7
%endmacro

%macro  _this_symbol_set_raw_code_address 0     ; raw-code-address --
        _this_set_slot 7
%endmacro

%macro  _symbol_raw_code_size 0         ; symbol -- raw-code-size
        _slot 8
%endmacro

%macro  _symbol_set_raw_code_size 0     ; raw-code-size symbol --
        _set_slot 8
%endmacro

%macro  _this_symbol_set_raw_code_size 0        ; raw-code-size --
        _this_set_slot 8
%endmacro

%define symbol_flags_slot       qword [rbx + BYTES_PER_CELL * 9]

%define this_symbol_flags_slot  qword [this_register + BYTES_PER_CELL * 9]

%macro  _symbol_flags 0                 ; symbol -- flags
        _slot 9
%endmacro

%macro  _symbol_set_flags 0             ; flags symbol --
        _set_slot 9
%endmacro

%macro  _this_symbol_set_flags 0        ; flags --
        _this_set_slot 9
%endmacro

%macro  _symbol_flags_bit 1             ; symbol -- ?
        _ check_symbol
        mov     eax, t_value
        test    symbol_flags_slot, %1
        mov     ebx, f_value
        cmovnz  ebx, eax
%endmacro

%macro  _symbol_set_flags_bit 1         ; symbol --
        _ check_symbol
        or      symbol_flags_slot, %1
        _drop
%endmacro

%macro  _this_symbol_set_flags_bit 1    ; --
        or      this_symbol_flags_slot, %1
%endmacro

%macro  _symbol_clear_flags_bit 1       ; symbol --
        _ check_symbol
        and     symbol_flags_slot, ~%1
        _drop
%endmacro

%macro  _symbol_file 0                  ; symbol -- file
        _slot 10
%endmacro

%macro  _symbol_set_file 0              ; file symbol --
        _set_slot 10
%endmacro

%macro  _this_symbol_set_file 0         ; file --
        _this_set_slot 10
%endmacro

; The line number is 1-based and stored as a tagged fixnum.
%macro  _symbol_line_number 0           ; symbol -- line-number
        _slot 11
%endmacro

%macro  _this_symbol_set_line_number 0  ; line-number --
        _this_set_slot 11
%endmacro

; ### symbol?
code symbol?, 'symbol?'                 ; x -- ?
        _ object_raw_typecode
        _eq? TYPECODE_SYMBOL
        next
endcode

; ### verify-symbol
code verify_symbol, 'verify-symbol'     ; symbol -- symbol
        _dup
        _ symbol?
        _tagged_if_not .1
        _ error_not_symbol
        _then .1
        next
endcode

; ### verify_static_symbol
code verify_static_symbol, 'verify_static_symbol', SYMBOL_INTERNAL
; symbol -- symbol
        cmp     rbx, static_data_area
        jb      .1
        cmp     rbx, static_data_area_limit
        jae     .1
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_SYMBOL
        jne     .1
        next
.1:
        _ error_not_symbol
        next
endcode

; ### check_symbol
code check_symbol, 'check_symbol', SYMBOL_INTERNAL      ; x -- symbol

        cmp     bl, HANDLE_TAG
        jne     verify_static_symbol

        ; save argument in rdx
        mov     rdx, rbx

        _handle_to_object_unsafe

        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_SYMBOL
        jne     .error
        _return

.error:
        ; restore original argument for error message
        mov     rbx, rdx
        jmp     error_not_symbol

        next
endcode

; ### <symbol>
code new_symbol, '<symbol>'             ; name vocab -- symbol
; 12 slots: object header, name, vocab name, hashcode, def, props,
; value, code address, code size, flags, file, line number

        _lit 12
        _ raw_allocate_cells            ; -- name vocab object-address

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- name vocab

        _this_object_set_raw_typecode TYPECODE_SYMBOL

        _tuck
        _ vocab_name
        _this_symbol_set_vocab_name     ; -- vocab name

        _this_symbol_set_name           ; -- vocab

        _this_symbol_name
        _ string_hashcode
        _this_symbol_vocab_name
        _ string_hashcode
        _ hash_combine
        _this_symbol_set_hashcode

        _f
        _this_symbol_set_def

        _f
        _this_symbol_set_props

        _f
        _this_symbol_set_value

        _zero
        _this_symbol_set_raw_code_address

        _zero
        _this_symbol_set_raw_code_size

        _zero
        _this_symbol_set_flags

        _f
        _this_symbol_set_file

        _f
        _this_symbol_set_line_number

        _ default_visibility
        _ get
        _eq? S_private
        _tagged_if .1
        _this_symbol_set_flags_bit SYMBOL_PRIVATE
        _then .1

        pushrbx
        mov     rbx, this_register      ; -- vocab symbol
        pop     this_register

        _ new_handle                    ; -- vocab handle

        _swap
        _dupd                           ; -- handle handle vocab
        _ vocab_add_symbol              ; -- handle

        next
endcode

; ### symbol-equal?
code symbol_equal?, 'symbol-equal?'     ; x y -- ?
        _dup
        _ symbol?
        _tagged_if .1
        _eq?
        _return
        _then .1

        _drop
        mov     ebx, f_value

        next
endcode

; ### symbol-name
code symbol_name, 'symbol-name'         ; symbol -- name
        _ check_symbol
        _symbol_name
        next
endcode

; ### symbol-qualified-name
code symbol_qualified_name, 'symbol-qualified-name'     ; symbol -- qualified-name
        _ check_symbol
        _dup
        _symbol_vocab_name
        _ string_to_sbuf
        _lit tagged_char(':')
        _over
        _ sbuf_push
        _swap
        _symbol_name
        _over
        _ sbuf_append_string
        _ sbuf_to_string
        next
endcode

; ### symbol-hashcode
code symbol_hashcode, 'symbol-hashcode' ; symbol -- hashcode
        _ check_symbol
        _symbol_hashcode
        next
endcode

; ### symbol-set-hashcode
code symbol_set_hashcode, 'symbol-set-hashcode' ; hashcode symbol --
        _ check_symbol
        _symbol_set_hashcode
        next
endcode

; ### symbol-vocab-name
code symbol_vocab_name, 'symbol-vocab-name' ; symbol -- vocab-name
        _ check_symbol
        _symbol_vocab_name
        next
endcode

; ### symbol-def
code symbol_def, 'symbol-def'           ; symbol -- definition
        _ check_symbol
        _symbol_def
        next
endcode

; ### symbol-set-def
code symbol_set_def, 'symbol-set-def'   ; definition symbol --
        _ check_symbol
        _symbol_set_def
        next
endcode

; ### symbol-props
code symbol_props, 'symbol-props'       ; symbol -- props
        _ check_symbol
        _symbol_props
        next
endcode

; ### symbol-prop
code symbol_prop, 'symbol-prop'         ; key symbol -- value
        _ check_symbol
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- key

        _this_symbol_props
        _dup
        _tagged_if .1
        _ hashtable_at
        _else .1
        _nip
        _then .1

        pop     this_register
        next
endcode

; ### symbol-set-prop
code symbol_set_prop, 'symbol-set-prop' ; value key symbol --
        _ check_symbol
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- value key

        _this_symbol_props
        _tagged_if_not .1
        _lit 2
        _ new_hashtable_untagged
        _this_symbol_set_props
        _then .1

        _this_symbol_props
        _ hashtable_set_at

        pop     this_register
        next
endcode

; ### symbol-primitive?
code symbol_primitive?, 'symbol-primitive?'     ; symbol -- ?
        _symbol_flags_bit SYMBOL_PRIMITIVE
        next
endcode

; ### symbol-set-primitive
code symbol_set_primitive, 'symbol-set-primitive', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; symbol --
        _symbol_set_flags_bit SYMBOL_PRIMITIVE
        next
endcode

; ### symbol-immediate?
code symbol_immediate?, 'symbol-immediate?'     ; symbol -- ?
        _symbol_flags_bit SYMBOL_IMMEDIATE
        next
endcode

; ### symbol-set-immediate
code symbol_set_immediate, 'symbol-set-immediate', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; symbol --
        _symbol_set_flags_bit SYMBOL_IMMEDIATE
        next
endcode

; ### symbol-always-inline?
code symbol_always_inline?, 'symbol-always-inline?'     ; symbol -- ?
        _symbol_flags_bit SYMBOL_ALWAYS_INLINE
        next
endcode

; ### symbol-inline?
code symbol_inline?, 'symbol-inline?'           ; symbol -- ?
        _symbol_flags_bit SYMBOL_INLINE
        next
endcode

; ### symbol-global?
code symbol_global?, 'symbol-global?'           ; symbol -- ?
        _symbol_flags_bit SYMBOL_GLOBAL
        next
endcode

; ### symbol-set-global-bit
code symbol_set_global_bit, 'symbol-set-global-bit', SYMBOL_PRIVATE
; symbol --
        _symbol_set_flags_bit SYMBOL_GLOBAL
        next
endcode

; ### symbol-thread-local?
code symbol_thread_local?, 'symbol-thread-local?'       ; symbol -- ?
        _symbol_flags_bit SYMBOL_THREAD_LOCAL
        next
endcode

; ### symbol-set-thread-local-bit
code symbol_set_thread_local_bit, 'symbol-set-thread-local-bit', SYMBOL_PRIVATE ; symbol --
        _symbol_set_flags_bit SYMBOL_THREAD_LOCAL
        next
endcode

; ### error-not-thread-local
code error_not_thread_local, 'error-not-thread-local'   ; x --
        _error "not a thread-local"
        next
endcode

; ### verify-thread-local
code verify_thread_local, 'verify-thread-local' ; thread-local -- thread-local
        _dup
        _ check_symbol
        _symbol_flags
        and     rbx, SYMBOL_THREAD_LOCAL
        poprbx
        jz      error_not_thread_local
        next
endcode

; ### symbol-set-special-bit
code symbol_set_special_bit, 'symbol-set-special-bit', SYMBOL_PRIVATE
; symbol --
        _symbol_set_flags_bit SYMBOL_SPECIAL
        next
endcode

; ### symbol-constant?
code symbol_constant?, 'symbol-constant?'       ; symbol -- ?
        _symbol_flags_bit SYMBOL_CONSTANT
        next
endcode

; ### symbol-special?
code symbol_special?, 'symbol-special?'         ; symbol -- ?
        _symbol_flags_bit SYMBOL_SPECIAL
        next
endcode

; ### symbol-private?
code symbol_private?, 'symbol-private?'         ; symbol -- ?
        _symbol_flags_bit SYMBOL_PRIVATE
        next
endcode

; ### symbol-set-private
code symbol_set_private, 'symbol-set-private', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; symbol --
        _symbol_set_flags_bit SYMBOL_PRIVATE
        next
endcode

; ### symbol-public?
code symbol_public?, 'symbol-public?'           ; symbol -- ?
        _symbol_flags_bit SYMBOL_PRIVATE
        _not
        next
endcode

; ### symbol-set-public
code symbol_set_public, 'symbol-set-public', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; symbol --
        _symbol_clear_flags_bit SYMBOL_PRIVATE
        next
endcode

; ### symbol-internal?
code symbol_internal?, 'symbol-internal?'       ; symbol -- ?
        _symbol_flags_bit SYMBOL_INTERNAL
        next
endcode

; ### generic?
code generic?, 'generic?'                       ; symbol -- ?
        _symbol_flags_bit SYMBOL_GENERIC
        next
endcode

; ### symbol-set-generic
code symbol_set_generic, 'symbol-set-generic', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; symbol --
        _symbol_set_flags_bit SYMBOL_GENERIC
        next
endcode

; ### deferred?
code deferred?, 'deferred?'             ; symbol -> ?
        _symbol_flags_bit SYMBOL_DEFERRED
        next
endcode

; ### symbol-set-deferred-bit
code symbol_set_deferred_bit, 'symbol-set-deferred-bit', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; symbol -> void
        _symbol_set_flags_bit SYMBOL_DEFERRED
        next
endcode

; ### symbol-value
code symbol_value, 'symbol-value'               ; symbol -- value
        _ check_symbol
        _symbol_value
        next
endcode

; ### symbol-set-value
code symbol_set_value, 'symbol-set-value'       ; value symbol --
        _ check_symbol
        _symbol_set_value
        next
endcode

; ### error-not-global
code error_not_global, 'error-not-global'       ; x --
        _error "not a global"
        next
endcode

; ### verify-global
code verify_global, 'verify-global'     ; global -- global
        _dup
        _ check_symbol
        _symbol_flags
        and     rbx, SYMBOL_GLOBAL
        poprbx
        jz      error_not_global
        next
endcode

; ### check_global
code check_global, 'check_global', SYMBOL_INTERNAL      ; x -- unboxed-symbol
        _ check_symbol
        _dup
        _symbol_flags
        and     rbx, SYMBOL_GLOBAL
        poprbx
        jz      error_not_global
        next
endcode

; ### global-inc
code global_inc, 'global-inc'   ; symbol --
        _ check_global
        _dup
        _symbol_value
        _check_fixnum
        _oneplus
        _tag_fixnum
        _swap
        _symbol_set_value
        next
endcode

; ### global-dec
code global_dec, 'global-dec'   ; symbol --
        _ check_global
        _dup
        _symbol_value
        _check_fixnum
        _oneminus
        _tag_fixnum
        _swap
        _symbol_set_value
        next
endcode

; ### symbol_raw_code_address
code symbol_raw_code_address, 'symbol_raw_code_address', SYMBOL_INTERNAL
; symbol -- raw-code-address/0
        _ check_symbol
        _symbol_raw_code_address
        next
endcode

; ### symbol-code-address
code symbol_code_address, 'symbol-code-address' ; symbol -- code-address/f
        _ check_symbol
        _symbol_raw_code_address
        test    rbx, rbx
        jz      .1
        _tag_fixnum
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### symbol-set-code-address
code symbol_set_code_address, 'symbol-set-code-address' ; tagged-code-address symbol --
        _ check_symbol
        _verify_fixnum [rbp]
        _untag_fixnum qword [rbp]
        _symbol_set_raw_code_address
        next
endcode

; ### symbol-raw-code-size
code symbol_raw_code_size, 'symbol-raw-code-size'       ; symbol -- raw-code-size/0
        _ check_symbol
        _symbol_raw_code_size
        next
endcode

; ### symbol-code-size
code symbol_code_size, 'symbol-code-size'       ; symbol -- code-size/f
        _ check_symbol
        _symbol_raw_code_size
        _?dup_if .1
        _tag_fixnum
        _else .1
        _f
        _then .1
        next
endcode

; ### symbol-set-code-size
code symbol_set_code_size, 'symbol-set-code-size'       ; tagged-code-size symbol --
        _ check_symbol
        _verify_fixnum [rbp]
        _untag_fixnum qword [rbp]
        _symbol_set_raw_code_size
        next
endcode

; ### symbol-flags
code symbol_flags, 'symbol-flags'       ; symbol -- flags
        _ check_symbol
        _symbol_flags                   ; -- raw-uint64
        _ new_uint64
        next
endcode

; ### symbol-location
code symbol_location, 'symbol-location' ; -- file line-number
        _ check_symbol
        _dup
        _symbol_file
        _swap
        _symbol_line_number
        next
endcode

; ### symbol-set-location
code symbol_set_location, 'symbol-set-location' ; file line-number symbol --
        _ check_symbol
        _pick
        _tagged_if .1
        push    this_register
        mov     this_register, rbx
        poprbx
        _verify_index
        _this_symbol_set_line_number
        _ verify_string
        _this_symbol_set_file
        pop     this_register
        _else .1
        _3drop
        _then .1
        next
endcode

; ### call-symbol
code call_symbol, 'call-symbol'         ; symbol --
        _dup
        _ check_symbol
        mov rax, [rbx + SYMBOL_RAW_CODE_ADDRESS_OFFSET]

        ; check for null code address
        test    rax, rax
        jz      .error

        _2drop
        jmp     rax

.error:
        _drop

        _quote "ERROR: the symbol `%S` needs code."
        _ format
        _ error

        next
endcode
