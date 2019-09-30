; Copyright (C) 2018-2019 Peter Graves <gnooth@gmail.com>

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

; 3 cells: object header, raw value, owner

%define mutex_slot_raw_value    1
%define mutex_slot_owner        2

%define mutex_raw_value_slot    qword [rbx + BYTES_PER_CELL * mutex_slot_raw_value]
%define mutex_owner_slot        qword [rbx + BYTES_PER_CELL * mutex_slot_owner]

; ### mutex?
code mutex?, 'mutex?'                   ; handle -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_MUTEX
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### check_mutex
code check_mutex, 'check_mutex', SYMBOL_INTERNAL ; x -> ^mutex
        cmp     bl, HANDLE_TAG
        jne     error_not_mutex
        mov     rdx, rbx                ; save x for error reporting
        _handle_to_object_unsafe        ; -> ^object
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_MUTEX
        jne     .error
        next
.error:
        mov     rbx, rdx
        _ error_not_mutex
        next
endcode

; ### verify-mutex
code verify_mutex, 'verify-mutex'       ; handle -- handle
; returns argument unchanged
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_MUTEX
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_mutex
        next
endcode

; ### make-mutex
code make_mutex, 'make-mutex'
        _lit    BYTES_PER_CELL * 3
        _ raw_allocate
        mov     qword [rbx], TYPECODE_MUTEX
        xcall   os_mutex_init
        mov     mutex_raw_value_slot, rax
        mov     mutex_owner_slot, f_value
        _ new_handle
        next
endcode

; ### destroy_mutex
code destroy_mutex, 'destroy_mutex', SYMBOL_INTERNAL
        _dup
        mov     rbx, mutex_raw_value_slot
        _ raw_free

        ; zero out object header
        xor     eax, eax
        mov     [rbx], rax

        _ raw_free
        next
endcode

; ### mutex-owner
code mutex_owner, 'mutex-owner'         ; mutex -- thread/f
        _ check_mutex
        _slot mutex_slot_owner
        next
endcode

; ### mutex-lock
code mutex_lock, 'mutex-lock'           ; mutex -- ?
        _ check_mutex
        mov     arg0_register, mutex_raw_value_slot
        xcall   os_mutex_lock
        cmp     rax, f_value
        je      .1
        xcall   os_current_thread
        mov     mutex_owner_slot, rax
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### mutex-trylock
code mutex_trylock, 'mutex-trylock'     ; mutex -- ?
        _ check_mutex
        mov     arg0_register, mutex_raw_value_slot
        xcall   os_mutex_trylock
        cmp     rax, f_value
        je      .1
        xcall   os_current_thread
        mov     mutex_owner_slot, rax
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### mutex-unlock
code mutex_unlock, 'mutex-unlock'       ; mutex -- ?
        _ check_mutex
        mov     arg0_register, mutex_raw_value_slot
        xcall   os_mutex_unlock
        cmp     rax, f_value
        je      .1
        mov     mutex_owner_slot, f_value
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### mutex->string
code mutex_to_string, 'mutex->string'   ; mutex -> string
        _ verify_mutex
        _ object_address                ; -> tagged-fixnum
        _ fixnum_to_hex
        _quote "<mutex 0x%s>"
        _ format
        next
endcode
