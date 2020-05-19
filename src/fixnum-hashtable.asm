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

; 7 cells (object header, capacity, occupancy, deletions, data address,
; old data address, mask)
%define FIXNUM_HASHTABLE_SIZE                            7 * BYTES_PER_CELL

%define FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET             8
%define FIXNUM_HASHTABLE_RAW_OCCUPANCY_OFFSET           16
%define FIXNUM_HASHTABLE_RAW_DELETIONS_OFFSET           24
%define FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET        32
%define FIXNUM_HASHTABLE_OLD_RAW_DATA_ADDRESS_OFFSET    40
%define FIXNUM_HASHTABLE_RAW_MASK_OFFSET                48

; ### fixnum-hashtable?
code fixnum_hashtable?, 'fixnum-hashtable?'     ; x -> ?
        cmp     bl, HANDLE_TAG
        jne     .no
        _handle_to_object_unsafe
%ifdef DEBUG
        test    rbx, rbx
        jz      error_empty_handle
%endif
        cmp     word [rbx], TYPECODE_FIXNUM_HASHTABLE
        jne     .no
        mov     ebx, TRUE
        next
.no:
        mov     ebx, NIL
        next
endcode

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
        mov     arg1_register, symbol(empty_marker)
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

        mov     qword [rax + FIXNUM_HASHTABLE_RAW_MASK_OFFSET], rbx
        sub     qword [rax + FIXNUM_HASHTABLE_RAW_MASK_OFFSET], 1

        mov     qword [rax + FIXNUM_HASHTABLE_RAW_OCCUPANCY_OFFSET], 0
        mov     qword [rax + FIXNUM_HASHTABLE_RAW_DELETIONS_OFFSET], 0
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

; ### destroy_fixnum_hashtable
code destroy_fixnum_hashtable, 'destroy_fixnum_hashtable'       ; ^hashtable -> void

        mov     arg0_register, [rbx + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]
        xcall   free

        ; zero out object header
        mov     qword [rbx], 0

        _feline_free
        next
endcode

; ### fixnum-hashtable-capacity
code fixnum_hashtable_capacity, 'fixnum-hashtable-capacity'     ; hashtable -> fixnum
        _ check_fixnum_hashtable
        mov     rbx, [rbx + FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET]
        _tag_fixnum
        next
endcode

; ### fixnum-hashtable-occupancy
code fixnum_hashtable_occupancy, 'fixnum-hashtable-occupancy'   ; hashtable -> fixnum
        _ check_fixnum_hashtable
        mov     rbx, [rbx + FIXNUM_HASHTABLE_RAW_OCCUPANCY_OFFSET]
        _tag_fixnum
        next
endcode

; ### fixnum-hashtable-deletions
code fixnum_hashtable_deletions, 'fixnum-hashtable-deletions'   ; hashtable -> fixnum
        _ check_fixnum_hashtable
        mov     rbx, [rbx + FIXNUM_HASHTABLE_RAW_DELETIONS_OFFSET]
        _tag_fixnum
        next
endcode

; ### hash-fixnum
code hash_fixnum, 'hash-fixnum'         ; x -> hashcode
; sbcl src/code/compiler/sxhash.lisp

;  (let ((c (logand 1193941380939624010 sb-xc:most-positive-fixnum)))
;    ;; shift by -1 to get sign bit into hash
;    `(logand (logxor (ash x 4) (ash x -1) ,c) sb-xc:most-positive-fixnum)))

        _verify_fixnum
        sar     rbx, FIXNUM_TAG_BITS    ; rbx: x (untagged)

        mov     rcx, rbx
        shl     rcx, 4                  ; rcx: (ash x 4)

        ; get sign bit into hash
        shr     rbx, 1                  ; rbx: (ash x -1)

        mov     rdx, 1193941380939624010
        mov     rax, MOST_POSITIVE_FIXNUM
        and     rdx, rax                ; rdx: c

        xor     rbx, rcx                ; (logxor (ash x 4) (ash x -1))
        xor     rbx, rdx                ; (logxor (ash x 4) (ash x -1) c)
        and     rbx, rax                ; (logand (logxor ...) m-p-f)

        _tag_fixnum
        next
endcode

; ### murmur64
code murmur64, 'murmur64'               ; k -> hashcode
; smhasher/src/MurmurHash3.cpp

; FORCE_INLINE uint64_t fmix64 ( uint64_t k )
; {
;   k ^= k >> 33;
;   k *= BIG_CONSTANT(0xff51afd7ed558ccd);
;   k ^= k >> 33;
;   k *= BIG_CONSTANT(0xc4ceb9fe1a85ec53);
;   k ^= k >> 33;
;
;   return k;
; }

        _verify_fixnum
        sar     rbx, FIXNUM_TAG_BITS    ; rbx: k (untagged)

        mov     rax, rbx
        shr     rax, 33                 ; rax: k >> 33
        xor     rax, rbx                ; rax: k ^= k >> 33

        mov     rdx, 0xff51afd7ed558ccd
        mul     rdx                     ; rax: k *= 0xff51afd7ed558ccd

        mov     rbx, rax                ; rbx: k *= 0xff51afd7ed558ccd
        shr     rax, 33                 ; rax: k >> 33
        xor     rax, rbx                ; rax: k ^= k >> 33

        mov     rdx, 0xc4ceb9fe1a85ec53
        mul     rdx                     ; rax: k *= 0xc4ceb9fe1a85ec53

        mov     rbx, rax                ; rbx: k *= 0xc4ceb9fe1a85ec53
        shr     rax, 33                 ; rax: k >> 33
        xor     rbx, rax                ; rbx: k ^= k >> 33

        mov     rax, MOST_POSITIVE_FIXNUM
        and     rbx, rax

        _tag_fixnum
        next
endcode

%macro  _hashcode_rax 0
%if 1
        mov     rax, rbx
%else
        push    rbx
        _ murmur64
        mov     rax, rbx
        pop     rbx
%endif
%endmacro

; ### gethash
code gethash, 'gethash'                 ; key hashtable -> void

        _ check_fixnum_hashtable        ; -> key ^hashtable
        push    this_register
        mov     this_register, rbx
        _drop                           ; ^hashtable in this_register, key in rbx

        _verify_fixnum

        ; get data address in r12
        push    r12
        mov     r12, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]

        ; get hashcode in rax
        ; for a fixnum hashtable, the hashcode is the key itself
;         mov     rax, rbx
        _hashcode_rax

        ; apply mask to get index of first entry to check
        and     rax, [this_register + FIXNUM_HASHTABLE_RAW_MASK_OFFSET]

        ; calculate the address of the first key
        shl     rax, 4          ; convert entry index to byte index
        add     r12, rax        ; address of first key in r12

.loop1:
        mov     rax, [r12]

        cmp     rbx, rax
        je      .found

        cmp     rax, symbol(empty_marker)
        je      .not_found

        test    rax, rax                ; check for sentinel
        jz      .wrap                   ; wrap around

        add     r12, BYTES_PER_CELL * 2 ; point to next key
        jmp     .loop1

.wrap:
        mov     r12, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]

.loop2:
        mov     rax, [r12]

        cmp     rbx, rax
        je      .found

        cmp     rax, symbol(empty_marker)
        je      .not_found

        add     r12, BYTES_PER_CELL * 2
        jmp     .loop2

.not_found:
        mov     rbx, NIL
        pop     r12
        pop     this_register
        next

.found:
        mov     rbx, [r12 + BYTES_PER_CELL]
        pop     r12
        pop     this_register
        next
endcode

; ### remhash
code remhash, 'remhash'                 ; key hashtable -> void

        _ check_fixnum_hashtable        ; -> key ^hashtable
        push    this_register
        mov     this_register, rbx
        _drop                           ; ^hashtable in this_register, key in rbx

        _verify_fixnum

        ; get data address in r12
        push    r12
        mov     r12, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]

        ; get hashcode in rax
        ; for a fixnum hashtable, the hashcode is the key itself
;         mov     rax, rbx
        _hashcode_rax

        ; apply mask to get index of first entry to check
        and     rax, [this_register + FIXNUM_HASHTABLE_RAW_MASK_OFFSET]

        ; calculate the address of the first key
        shl     rax, 4          ; convert entry index to byte index
        add     r12, rax        ; address of first key in r12

.loop1:
        mov     rax, [r12]

        cmp     rbx, rax
        je      .found

        cmp     rax, symbol(empty_marker)
        je      .not_found

        test    rax, rax                ; check for sentinel
        jz      .wrap                   ; wrap around

        add     r12, BYTES_PER_CELL * 2 ; point to next key
        jmp     .loop1

.wrap:
        mov     r12, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]

.loop2:
        mov     rax, [r12]

        cmp     rbx, rax
        je      .found

        cmp     rax, symbol(empty_marker)
        je      .not_found

        add     r12, BYTES_PER_CELL * 2
        jmp     .loop2

.found:
        mov     qword [r12], S_deleted_marker
        mov     qword [r12 + BYTES_PER_CELL], S_deleted_marker
        add     qword [this_register + FIXNUM_HASHTABLE_RAW_DELETIONS_OFFSET], 1
        ; fall through...

.not_found:
        _drop
        pop     r12
        pop     this_register
        next
endcode

subroutine puthash_internal             ; value key -> void
; call with ^hashtable in this_register

        ; get data address in r12
        push    r12
        mov     r12, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]

        ; get hashcode in rax
        ; for a fixnum hashtable, the hashcode is the key itself
;         mov     rax, rbx
        _hashcode_rax

        ; apply mask to get index of first entry to check
        and     rax, [this_register + FIXNUM_HASHTABLE_RAW_MASK_OFFSET]

        ; calculate the address of the first key
        shl     rax, 4          ; convert entry index to byte index
        add     r12, rax        ; address of first key in r12

.loop1:
        mov     rax, [r12]

        cmp     rbx, rax
        je      .found

        cmp     rax, symbol(empty_marker)
        je      .not_found

        test    rax, rax                ; check for sentinel
        jz      .wrap                   ; wrap around

        add     r12, BYTES_PER_CELL * 2 ; point to next key
        jmp     .loop1

.wrap:
        mov     r12, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]

.loop2:
        mov     rax, [r12]

        cmp     rbx, rax
        je      .found

        cmp     rax, symbol(empty_marker)
        je      .not_found

        add     r12, BYTES_PER_CELL * 2
        jmp     .loop2

.not_found:
        ; store key
        mov     [r12], rbx
        ; update occupancy
        add     qword [this_register + FIXNUM_HASHTABLE_RAW_OCCUPANCY_OFFSET], 1
        ; fall through...

.found:
        ; get value in rax
        mov     rax, [rbp]
        ; store value
        mov     [r12 + BYTES_PER_CELL], rax

        _2drop
        pop     r12
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

        mov     rax, [this_register + FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET]
        sar     rax, 1                  ; 50% occupancy
        cmp     [this_register + FIXNUM_HASHTABLE_RAW_OCCUPANCY_OFFSET], rax
        jl      .1
        _ grow_fixnum_hashtable_internal

.1:
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

subroutine grow_fixnum_hashtable_internal
; call with ^hashtable in this_register

        mov     rax, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]
        mov     [this_register + FIXNUM_HASHTABLE_OLD_RAW_DATA_ADDRESS_OFFSET], rax

        mov     rax, [this_register + FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET]
        shl     rax, 1                  ; double existing capacity
        mov     [this_register + FIXNUM_HASHTABLE_RAW_CAPACITY_OFFSET], rax

        mov     qword [this_register + FIXNUM_HASHTABLE_RAW_MASK_OFFSET], rax
        sub     qword [this_register + FIXNUM_HASHTABLE_RAW_MASK_OFFSET], 1

        _dup
        mov     rbx, rax

        _ make_bucket_array             ; returns raw address in rbx

        mov     [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET], rbx
        _drop

        mov     qword [this_register + FIXNUM_HASHTABLE_RAW_OCCUPANCY_OFFSET], 0
        mov     qword [this_register + FIXNUM_HASHTABLE_RAW_DELETIONS_OFFSET], 0

        push    r12
        mov     r12, [this_register + FIXNUM_HASHTABLE_OLD_RAW_DATA_ADDRESS_OFFSET]

.1:
        mov     rax, [r12]
        test    rax, rax
        jz      .2

        mov     rdx, [r12 + BYTES_PER_CELL]     ; key in rax, value in rdx

        test    al, FIXNUM_TAG
        jz      .3

        mov     [rbp - BYTES_PER_CELL * 2], rbx
        lea     rbp, [rbp - BYTES_PER_CELL * 2]
        mov     [rbp], rdx
        mov     rbx, rax
        _ puthash_internal

.3:
        lea     r12, [r12 + BYTES_PER_CELL * 2]
        jmp      .1

.2:
        ; free old bucket data
        mov     arg0_register, [this_register + FIXNUM_HASHTABLE_OLD_RAW_DATA_ADDRESS_OFFSET]
        xcall   free

        mov     qword [this_register + FIXNUM_HASHTABLE_OLD_RAW_DATA_ADDRESS_OFFSET], 0

        pop     r12

        ret
endsub

; grow-fixnum-hashtable
code grow_fixnum_hashtable, 'grow-fixnum-hashtable'     ; hashtable -> void
        _ ?enough_1
        _ check_fixnum_hashtable
        push    this_register
        mov     this_register, rbx      ; ^hashtable in this_register
        _drop

        _ grow_fixnum_hashtable_internal

        pop     this_register
        next
endcode

; ### fixnum-hashtable->string
code fixnum_hashtable_to_string, 'fixnum-hashtable->string' ; hashtable -> string
        _ check_fixnum_hashtable

        push    this_register
        mov     this_register, rbx
        _drop

        _quote "H{"
        _ string_to_sbuf                ; -> sbuf

        push    r12
        mov     r12, [this_register + FIXNUM_HASHTABLE_RAW_DATA_ADDRESS_OFFSET]

.1:
        mov     rax, [r12]
        test    rax, rax
        jz      .2
        _quote " { "
        _over
        _ sbuf_append_string
        _dup
        mov     rbx, [r12]
        _ object_to_string
        _over
        _ sbuf_append_string
        _lit tagged_char(32)
        _over
        _ sbuf_push
        _dup
        mov     rbx, [r12 + BYTES_PER_CELL]
        _ object_to_string
        _over
        _ sbuf_append_string
        _quote " }"
        _over
        _ sbuf_append_string
        lea     r12, [r12 + BYTES_PER_CELL * 2]
        jmp      .1

.2:
        pop     r12
        pop     this_register

        _quote " }"
        _over
        _ sbuf_append_string
        _ sbuf_to_string

        next
endcode
