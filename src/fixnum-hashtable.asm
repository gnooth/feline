; Copyright (C) 2020 Peter Graves <gnooth@gmail.com>

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

; 5 cells (object header, capacity, count, data address, old data address)
%define FIXNUM_HASHTABLE_SIZE                            5 * BYTES_PER_CELL

%define FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET             8
%define FIXNUM_HASHTABLE_RAW_OCCUPANCY_OFFSET           16
%define FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET        24
%define FIXNUM_HASHTABLE_OLD_RAW_DATA_ADDRESS_OFFSET    32

; ### check_fixnum_hashtable
code check_fixnum_hashtable, 'check_fixnum_hashtable' ; handle -> ^hashtable
        cmp     bl, HANDLE_TAG
        jne     .error2
        mov     rdx, rbx                ; copy argument in case there is an error
        _handle_to_object_unsafe
%ifdef DEBUG
        test    rbx, rbx
        jz      error_empty_handle
%endif
        cmp     word [rbx], TYPECODE_FIXNUM_HASHTABLE
        jne     .error1
        next
.error1:
        mov     rbx, rdx                ; restore original argument
.error2:
        jmp     error_not_fixnum_hashtable
endcode

subroutine make_bucket_array    ; raw-capacity -> raw-address
; call with raw capacity (number of entries) in rbx
; returns raw allocated address in rbx

        ; convert entries to cells (2 cells per entry)
        shl     rbx, 1

        ; plus one more cell for a sentinel
        lea     arg0_register, [rbx + 1]

        ; convert cells to bytes
        shl     arg0_register, 3

        _ feline_malloc                 ; returns raw allocated address in rax

        mov     arg0_register, rax      ; raw address
        mov     arg1_register, S_empty_marker
        mov     arg2_register, rbx      ; raw capacity in cells
        push    rax
        _ fill_cells
        pop     rax

        ; store sentinel
        mov     qword [rax + rbx * BYTES_PER_CELL], 0

        ; return raw address in rbx
        mov     rbx, rax
        ret
endsub

; ### make-fixnum-hashtable
code make_fixnum_hashtable, 'make-fixnum-hashtable' ; capacity -> hashtable
        _ next_power_of_2
        _untag_fixnum                   ; -> raw-capacity (in rbx)

        ; allocate memory for the hashtable object
        mov     arg0_register, FIXNUM_HASHTABLE_SIZE
        _ feline_malloc                 ; returns raw address in rax
        mov     qword [rax], TYPECODE_FIXNUM_HASHTABLE

        mov     qword [rax + FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET], rbx
        mov     qword [rax + FIXNUM_HASHTABLE_RAW_OCCUPANCY_OFFSET], 0
        push    rax
        _ make_bucket_array             ; returns raw address in rbx
        pop     rax
        mov     qword [rax + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET], rbx
        mov     qword [rax + FIXNUM_HASHTABLE_OLD_RAW_DATA_ADDRESS_OFFSET], 0

        ; return handle
        mov     rbx, rax
        _ new_handle                    ; -> hashtable
        next
endcode

; ### gethash
code gethash, 'gethash'                 ; key hashtable -> void

        _ check_fixnum_hashtable        ; -> key ^hashtable
        push    this_register
        mov     this_register, rbx
        _drop                           ; ^hashtable in this_register, key in rbx

        _verify_fixnum

        mov     rdx, [this_register + FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET] ; capacity in rdx
        mov     rax, rbx                ; key in rax
        lea     r10, [rdx - 1]          ; mask in r10
        and     rax, r10                ; apply mask to key (key is a tagged fixnum)

        ; index of first entry to check is now in rax

        ; get data address in r11
        mov     r11, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]

        mov     rcx, rdx        ; rcx counts down

        jmp     .1

.2:
        add     rax, 1
        and     rax, r10

.1:
        mov     r9, rax
        shl     r9, 1           ; 2 cells per entry
        mov     r8, [r11 + r9 * BYTES_PER_CELL]

        cmp     r8, rbx
        je      .found
        sub     rcx, 1          ; decrement counter
        jnz     .2
        ; not found
        mov     rbx, NIL
        pop     this_register
        next

.found:
        ; rbx: key
        ; rdx: capacity
        ; r11: data address
        ; rax: index

        add     r9, 1
        mov     rbx, [r11 + r9 * BYTES_PER_CELL]

        pop     this_register
        next
endcode

subroutine puthash_internal             ; value key -> void
; call with ^hashtable in this_register
        mov     rdx, [this_register + FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET] ; capacity in rdx
        mov     rax, rbx                ; key in rax
        lea     r10, [rdx - 1]  ; mask in r10
        and     rax, r10        ; apply mask to key (fixnum)

        ; index of first entry to check is now in rax

        ; get data address in r11
        mov     r11, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]

        mov     rcx, rdx        ; rcx counts down

        jmp     .1

.2:
        add     rax, 1
        and     rax, r10

.1:
        mov     r9, rax
        shl     r9, 1           ; 2 cells per entry
        mov     r8, [r11 + r9 * BYTES_PER_CELL]

        cmp     r8, S_empty_marker
        jz      .found_empty_slot
        sub     rcx, 1          ; decrement counter
        jnz     .2

        ; no empty slot found
        _2drop
        ret

.found_empty_slot:

        ; rbx: key
        ; [rbp]: value
        ; rdx: capacity
        ; r11: data address
        ; rax: index

        mov     [r11 + r9 * BYTES_PER_CELL], rbx        ; store key
        mov     r8, [rbp]                               ; r8: value
        add     r9, 1
        mov     [r11 + r9 * BYTES_PER_CELL], r8         ; store value

        _2drop
        ret
endsub

; ### puthash
code puthash, 'puthash'                 ; value key hashtable ->
        _ check_fixnum_hashtable        ; -> value key ^hashtable
        push    this_register
        mov     this_register, rbx      ; ^hashtable in this_register
        _drop                           ; -> value key
        _verify_fixnum
        _ puthash_internal
        pop     this_register
        next
endcode

; hashtable-data
code hashtable_data, 'hashtable-data'                   ; hashtable -> addr len
        _ check_fixnum_hashtable
        mov     rax, [rbx + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]
        mov     rcx, [rbx + FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET]
        shl     rcx, 4                  ; convert entries to bytes
        add     rcx, BYTES_PER_CELL     ; +1 for sentinel
        mov     rbx, rax
        _tag_fixnum
        _dup
        mov     rbx, rcx
        _tag_fixnum
        next
endcode

; dump-fixnum-hashtable
code dump_fixnum_hashtable, 'dump-fixnum-hashtable'     ; hashtable -> void
        _ ?enough_1
        _ check_fixnum_hashtable
        push    this_register
        mov     this_register, rbx
        _drop

        push    r12
        mov     r12, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]

.1:
        mov     rax, [r12]
        test    rax, rax
        jz      .2
        _dup
        mov     rbx, rax
        _ object_to_string
        _ write_string
        _ space
        _dup
        mov     rbx, [r12 + BYTES_PER_CELL]
        _ object_to_string
        _ print
        lea     r12, [r12 + BYTES_PER_CELL * 2]
        jmp      .1

.2:
        pop     r12
        pop     this_register
        next
endcode

; grow-fixnum-hashtable
code grow_fixnum_hashtable, 'grow-fixnum-hashtable'     ; hashtable -> void
        _ ?enough_1
        _ check_fixnum_hashtable
        push    this_register
        mov     this_register, rbx      ; ^hashtable in this_register

        mov     rax, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]
        mov     [this_register + FIXNUM_HASHTABLE_OLD_RAW_DATA_ADDRESS_OFFSET], rax

        mov     rbx, [this_register + FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET]
        shl     rbx, 2
        mov     [this_register + FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET], rbx
        _ make_bucket_array             ; returns raw address in rbx
        mov     [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET], rbx
        _drop

        push    r12
        mov     r12, [this_register + FIXNUM_HASHTABLE_OLD_RAW_DATA_ADDRESS_OFFSET]

.1:
        mov     rax, [r12]
        test    rax, rax
        jz      .2
        mov     rdx, [r12 + BYTES_PER_CELL]     ; key in rax, value in rdx

        _dup
        mov     rbx, rdx
        _dup
        mov     rbx, rax
        _ puthash_internal

        lea     r12, [r12 + BYTES_PER_CELL * 2]
        jmp      .1

.2:
        ; free old bucket data
        mov     arg0_register, [this_register + FIXNUM_HASHTABLE_OLD_RAW_DATA_ADDRESS_OFFSET]
        xcall   free

        pop     r12
        pop     this_register
        next
endcode