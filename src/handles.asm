; Copyright (C) 2016-2020 Peter Graves <gnooth@gmail.com>

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

asm_global handle_space_, 0
asm_global handle_space_free_, 0
asm_global handle_space_limit_, 0

%define HANDLE_SPACE_SIZE 1024*1024*8   ; 8 mb (1048576 handles)

asm_global unused_, 1024*1024

; ### unused-handles
code unused_handles, 'unused-handles'   ; -> n
        _dup
        mov     rbx, [unused_]
        _tag_fixnum
        next
endcode

asm_global recycled_handles_vector_, 0

%macro _recycled_handles_vector 0       ; -> ^vector
        _dup
        mov     rbx, [recycled_handles_vector_]
%endmacro

; ### initialize_handle_space
code initialize_handle_space, 'initialize_handle_space', SYMBOL_INTERNAL

        _dup
        mov     rbx, [handle_space_]

        test    rbx, rbx
        jz      .1

        ; handle space was reserved in main.c
        mov     [handle_space_free_], rbx
        _lit HANDLE_SPACE_SIZE
        shl     rbx, 1          ; soft limit is HANDLE_SPACE_SIZE * 2

        _dup
        shr     rbx, 3          ; convert bytes to handles
        mov     [unused_], rbx
        _drop

        _plus
        mov     [handle_space_limit_], rbx
        _drop

        jmp     .2

.1:
        _drop

        ; no handle space was reserved
        _lit HANDLE_SPACE_SIZE
        _dup
        _ raw_allocate
        mov     [handle_space_], rbx
        mov     [handle_space_free_], rbx
        _plus
        mov     [handle_space_limit_], rbx
        _drop

.2:
        _lit 256
        _ new_vector_untagged                           ; -> handle

        _dup
        _handle_to_object_unsafe                        ; -> handle raw-vector

        ; store address of raw vector asm global
        mov     [recycled_handles_vector_], rbx         ; -> handle raw_vector
        _drop                                           ; -> handle

        ; and release its handle
        _untag_handle
        _ release_handle_unsafe

        next
endcode

; ### empty-handles
code empty_handles, 'empty-handles'     ; -> tagged-fixnum
        _recycled_handles_vector
        _?dup_if .1
        _vector_raw_length
        _else .1
        _zero
        _then .1
        add     rbx, qword [unused_]
        _tag_fixnum
        next
endcode

; ### maybe-gc
code maybe_gc, 'maybe-gc'       ; void -> void
        _ empty_handles
        _tagged_fixnum 10
        _ fixnum_lt
        _tagged_if .1
        _ gc
        _then .1
        next
endcode

; ### gc-status
code gc_status, 'gc-status'     ; void -> void
        _ unused_handles
        _recycled_handles_vector
        _vector_raw_length
        _tag_fixnum
        _ empty_handles
        _ ?nl
        _ decimal_dot
        _write " empty handles ("
        _swap
        _ decimal_dot
        _write " unused, "
        _ decimal_dot
        _write " recycled)"
        _ nl
        next
endcode

; ### get_empty_handle
code get_empty_handle, 'get_empty_handle', SYMBOL_INTERNAL      ; -> handle/0
        _recycled_handles_vector
        test    rbx, rbx
        jz      .1
        _ vector_?pop_internal
        cmp     rbx, NIL
        je      .1
        _rep_return

.1:
        cmp     qword [unused_], 0
        jz .2
        mov     rbx, [handle_space_free_]       ; address of handle to be returned
        cmp     rbx, [handle_space_limit_]
        jae     .2
        add     qword [handle_space_free_], BYTES_PER_CELL
        sub     qword [unused_], 1
        next

.2:
        xor     ebx, ebx
        next
endcode

asm_global total_allocations_, 0

; ### total-allocations
code total_allocations, 'total-allocations'     ; -> n
        _dup
        mov     rbx, [total_allocations_]
        _tag_fixnum
        next
endcode

asm_global recent_allocations_, 0

; ### recent-allocations
; number of allocations since last gc
code recent_allocations, 'recent-allocations'   ; -> n
        _dup
        mov     rbx, [recent_allocations_]
        _tag_fixnum
        next
endcode

%macro  _reset_recent_allocations 0
        mov     qword [recent_allocations_], 0
%endmacro

%macro  _increment_allocation_count 0
        add qword [total_allocations_], 1
        add qword [recent_allocations_], 1
%endmacro

asm_global handles_lock_, 0

%macro  _handles_lock 0
        _dup
        mov     rbx, [handles_lock_]
%endmacro

; ### initialize_handles_lock
code initialize_handles_lock, 'initialize_handles_lock', SYMBOL_INTERNAL ; void -> void
        _ make_mutex
        mov     [handles_lock_], rbx
        _drop
        _lit handles_lock_
        _ gc_add_root
        next
endcode

; ### trylock_handles
code trylock_handles, 'trylock_handles', SYMBOL_INTERNAL        ; -> ?
        _handles_lock

        test    rbx, rbx
        jnz      .1
        mov     ebx, TRUE
        next

.1:
        _ mutex_trylock
        next
endcode

; ### unlock_handles
code unlock_handles, 'unlock_handles', SYMBOL_INTERNAL

        cmp     qword [handles_lock_], 0
        jz      .exit

;         _handles_lock
;         _ mutex_owner
;         _tagged_if_not .1
;         _return
;         _then .1

        _handles_lock
        _ mutex_unlock
        _tagged_if_not .2
        _error "mutex_unlock failed"
        _then .2

.exit:
        _rep_return
endcode

; ### new_handle
code new_handle, 'new_handle', SYMBOL_INTERNAL  ; object -> handle

;         cmp     qword [thread_count_], 1
;         je      .1

.2:
        _ safepoint

        _ trylock_handles
        cmp     rbx, NIL
        _drop
        je      .2

; .1:
        _ get_empty_handle              ; -> object handle/0
        test    rbx, rbx
        jz     .3

        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     [rbx], rax

        _tag_handle

        _increment_allocation_count
        _ unlock_handles
        next

.3:                                     ; -> object 0
        _drop

        _debug_print "new_handle need to gc"

        _ gc_lock
        _ mutex_trylock
        _tagged_if .4
        _debug_print "new_handle acquired gc lock"
        _ gc_collect
        _ gc_lock
        _ mutex_unlock
        _tagged_if_not .5
        _error "gc mutex_unlock failed"
        _then .5
        _debug_print "new_handle released gc lock"
        _then .4

        _debug_print "new_handle calling get_empty_handle"

        _ get_empty_handle              ; -> object handle/0
        test    rbx, rbx
        jz     .6

        _debug_print "new_handle got handle after gc"

        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     [rbx], rax

        _tag_handle

        _increment_allocation_count
        _ unlock_handles
        next

.6:
        _ unlock_handles
        _write `\nout of handles, exiting...\n`
        xcall   os_bye
        next
endcode

; ### handle?
code handle?, 'handle?'                 ; x -> ?
        cmp     bl, HANDLE_TAG
        jne     .1
        mov     ebx, TRUE
        next
.1:
        mov     ebx, NIL
        next
endcode

; ### verified-handle?
code verified_handle?, 'verified-handle?'       ; x -> ?
        cmp     bl, HANDLE_TAG
        jne     .no
        shr     rbx, HANDLE_TAG_BITS
        ; must point into handle space
        cmp     rbx, [handle_space_]
        jb .no
        cmp     rbx, [handle_space_free_]
        jae .no
        mov     ebx, TRUE
        next
.no:
        mov     ebx, NIL
        next
endcode

; ### deref
code deref, 'deref', SYMBOL_INTERNAL    ; x -> object-address/0
        cmp     bl, HANDLE_TAG
        jne     .1
        ; valid handle
        _handle_to_object_unsafe        ; -> object-address/0
        next

.1:
        ; -> x
        ; drop 0
        xor     ebx, ebx
        next
endcode

; ### release_handle_unsafe
code release_handle_unsafe, 'release_handle_unsafe', SYMBOL_INTERNAL ; handle -> void
        ; zero out the stored address
        mov     qword [rbx], 0

        ; add handle to recycled handles vector
        _recycled_handles_vector
        _ vector_push_internal

        next
endcode

; ### #objects
value nobjects, '#objects',  0

; ### #free
value nfree, '#free', 0

; ### handles
code handles, 'handles'
        _zeroto nobjects
        _zeroto nfree

        _dup
        mov     rbx, [handle_space_]
        _begin .1
        _dup
        _dup
        mov     rbx, [handle_space_free_]
        _ult
        _while .1
        _dup
        _fetch
        _if .2
        _oneplusto nobjects
        _else .2
        _oneplusto nfree
        _then .2
        _cellplus
        _repeat .1
        _drop

        _ ?nl
        _dup
        mov     rbx, [handle_space_free_]
        _dup
        mov     rbx, [handle_space_]
        _minus

;         _ cell
;         _ slash
        shr     rbx, 3

        _tag_fixnum
        _ decimal_dot
        _write " handles "

        _ nobjects
        _tag_fixnum
        _ decimal_dot
        _write " objects "

        _ nfree
        _tag_fixnum
        _ decimal_dot
        _write " free"

        next
endcode

; ### each_handle
code each_handle, 'each_handle'         ; raw-code-address -> void
        push    r12
        mov     r12, rbx                ; code address in r12
        _drop                           ; -> empty
        _dup
        mov     rbx, [handle_space_]
        _begin .1
        _dup
        _dup
        mov     rbx, [handle_space_free_]
        _ult
        _while .1                       ; -> addr
        _dup
        call    r12
        _cellplus
        _repeat .1
        _drop
        pop     r12
        next
endcode
