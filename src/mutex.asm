; Copyright (C) 2018 Peter Graves <gnooth@gmail.com>

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

; 2 cells: object header, raw value

%define mutex_raw_value_slot    qword [rbx + BYTES_PER_CELL]

%macro  _mutex_raw_value 0              ; mutex -- raw-value
        _slot1
%endmacro

%macro  _mutex_set_raw_value 0          ; raw-value mutex --
        _set_slot1
%endmacro

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
code check_mutex, 'check_mutex', SYMBOL_INTERNAL        ; handle -- mutex
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_MUTEX
        jne     .error
        _nip
        next
.error:
        _drop
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
        _lit    BYTES_PER_CELL * 2
        _ raw_allocate
        mov     qword [rbx], TYPECODE_MUTEX
%ifdef WIN64
        mov     arg0_register, 0
        mov     arg1_register, 0
        mov     arg2_register, 0
        xcall   CreateMutexA
        mov     mutex_raw_value_slot, rax
%else
        extern  os_mutex_init
        xcall   os_mutex_init
        mov     mutex_raw_value_slot, rax
%endif
        _ new_handle
        next
endcode

; ### mutex-lock
code mutex_lock, 'mutex-lock'           ; mutex -- ?
        _ check_mutex
        mov     arg0_register, mutex_raw_value_slot
        extern  os_mutex_lock
        xcall   os_mutex_lock
        mov     rbx, rax
        next
endcode

; ### mutex-trylock
code mutex_trylock, 'mutex-trylock'     ; mutex -- ?
        _ check_mutex
        mov     arg0_register, mutex_raw_value_slot
        extern  os_mutex_trylock
        xcall   os_mutex_trylock
        mov     rbx, rax
        next
endcode


; ### mutex-unlock
code mutex_unlock, 'mutex-unlock'       ; mutex -- ?
        _ check_mutex
        mov     arg0_register, mutex_raw_value_slot
        extern  os_mutex_unlock
        xcall   os_mutex_unlock
        mov     rbx, rax
        next
endcode

; ### mutex>string
code mutex_to_string, 'mutex>string'    ; mutex -- string
        _ verify_mutex

        _ object_address                ; -- tagged-fixnum
        _ fixnum_to_hex
        _quote "#<mutex 0x%s>"
        _ format

        next
endcode
