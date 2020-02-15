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
%define FIXNUM_HASHTABLE_RAW_OLD_DATA_ADDRESS_OFFSET    32

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

; ### make-fixnum-hashtable
code make_fixnum_hashtable, 'make-fixnum-hashtable' ; capacity -> hashtable
        _ next_power_of_2
        _untag_fixnum                   ; -> raw-capacity (in rbx)

        ; allocate memory for the hashtable object
        mov     arg0_register, FIXNUM_HASHTABLE_SIZE
        _ feline_malloc                 ; returns raw address in rax
        mov     qword [rax], TYPECODE_FIXNUM_HASHTABLE

        push    this_register
        mov     this_register, rax      ; ^hashtable in this_register

        mov     [this_register + FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET], rbx
        mov     qword [this_register + FIXNUM_HASHTABLE_RAW_OCCUPANCY_OFFSET], 0

        mov     arg0_register, rbx      ; raw capacity in arg0_register

        ; each entry occupies two cells (key, value)
        shl     arg0_register, 4        ; convert entries to bytes

        ; plus one more cell for a sentinel
        add     arg0_register, BYTES_PER_CELL

        xcall   malloc                  ; returns raw data address im rax
        test    rax, rax
        jz      error_out_of_memory

        mov     [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET], rax

        mov     arg0_register, rax      ; address
        mov     arg1_register, S_empty_marker
        mov     arg2_register, rbx      ; raw capacity
        shl     arg2_register, 1        ; two cells per entry
        _ fill_cells

        ; sentinel
        mov     rax, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]
        ; rbx: raw capacity
        shl     rbx, 4                  ; convert entries (2 cells per entry) to bytes
        mov     qword [rax + rbx], 0    ; store raw zero as sentinel

        mov     qword [this_register + FIXNUM_HASHTABLE_RAW_OLD_DATA_ADDRESS_OFFSET], 0

        mov     rbx, this_register
        pop     this_register

        ; return handle
        _ new_handle                    ; -- handle

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

; ### puthash
code puthash, 'puthash'                 ; value key hashtable ->
        _ check_fixnum_hashtable        ; -> value key ^hashtable
        push    this_register
        mov     this_register, rbx
        _drop                   ; ^hashtable in this_register, key in rbx, value in [rbp]

        _verify_fixnum

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
        pop     this_register
        next

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
        _ check_fixnum_hashtable
        push    this_register
        mov     this_register, rbx
        _drop                           ; ^hashtable in this_register

        ; FIXME needs code!

        pop     this_register
        next
endcode
