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

asm_global handle_space_, 0
asm_global handle_space_free_, 0
asm_global handle_space_limit_, 0

%define HANDLE_SPACE_SIZE 1024*1024*8   ; 8 mb (1048576 handles)

asm_global unused, 1024*1024

; ### unused-handles
code unused_handles, 'unused-handles'   ; -- n
        pushrbx
        mov     rbx, [unused]
        _tag_fixnum
        next
endcode

asm_global recycled_handles_vector_, 0

%macro _recycled_handles_vector 0       ; -- raw-vector
        pushrbx
        mov     rbx, [recycled_handles_vector_]
%endmacro

; ### initialize_handle_space
code initialize_handle_space, 'initialize_handle_space', SYMBOL_INTERNAL
; --

        pushrbx
        mov     rbx, [handle_space_]

        test    rbx, rbx
        jz      .1

        ; handle space was reserved in main.c
        mov     [handle_space_free_], rbx
        _lit HANDLE_SPACE_SIZE
        shl     rbx, 1          ; soft limit is HANDLE_SPACE_SIZE * 2

        _dup
        shr     rbx, 3          ; convert bytes to handles
        mov     [unused], rbx
        poprbx

        _plus
        mov     [handle_space_limit_], rbx
        poprbx

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
        poprbx

.2:
        _lit 256
        _ new_vector_untagged                           ; -- handle

        _dup
        _handle_to_object_unsafe                        ; -- handle raw-vector

        ; store address of raw vector in recycled_handles_vector_ asm global
        mov     [recycled_handles_vector_], rbx         ; -- handle raw_vector
        poprbx                                          ; -- handle

        ; and release its handle
%ifdef TAGGED_HANDLES
        _untag_handle
%endif
        _ release_handle_unsafe                         ; --

        next
endcode

; ### empty-handles
code empty_handles, 'empty-handles'     ; -- tagged-fixnum
        _recycled_handles_vector
        _?dup_if .1
        _vector_raw_length
        _else .1
        _zero
        _then .1
        add     rbx, qword [unused]
        _tag_fixnum
        next
endcode

; ### maybe-gc
code maybe_gc, 'maybe-gc'       ; --
        _ empty_handles
        _tagged_fixnum 10
        _ fixnum_lt
        _tagged_if .1
        _ gc
        _then .1
        next
endcode

; ### gc-status
code gc_status, 'gc-status'     ; --
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
code get_empty_handle, 'get_empty_handle', SYMBOL_INTERNAL      ; -- handle/0
        _recycled_handles_vector
        test    rbx, rbx
        jz      .1
        _ vector_?pop_unchecked
        cmp     rbx, f_value
        je      .1
        _rep_return

.1:
        ; -- f
        cmp     qword [unused], 0
        jz .2
        mov     rbx, [handle_space_free_]       ; address of handle to be returned
        cmp     rbx, [handle_space_limit_]
        jae     .2
        add     qword [handle_space_free_], BYTES_PER_CELL
        sub     qword [unused], 1
        _return

.2:
        ; -- f
        xor     ebx, ebx
        next
endcode

asm_global total_allocations_, 0

; ### total-allocations
code total_allocations, 'total-allocations'     ; -- n
        pushrbx
        mov     rbx, [total_allocations_]
        _tag_fixnum
        next
endcode

asm_global recent_allocations_, 0

; ### recent-allocations
; number of allocations since last gc
code recent_allocations, 'recent-allocations'   ; -- n
        pushrbx
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
        pushrbx
        mov     rbx, [handles_lock_]
%endmacro

; ### initialize_handles_lock
code initialize_handles_lock, 'initialize_handles_lock', SYMBOL_INTERNAL
; --
        _ make_mutex
        mov     [handles_lock_], rbx
        poprbx
        _lit handles_lock_
        _ gc_add_root
        next
endcode

; ### lock_handles
code lock_handles, 'lock_handles', SYMBOL_INTERNAL      ; --
        _handles_lock

        test    rbx, rbx
        jnz      .1
        _drop
        _return

.1:
        _ mutex_lock
        _tagged_if_not .2
        _error "mutex_lock failed"
        _then .2
        next
endcode

; ### trylock_handles
code trylock_handles, 'trylock_handles', SYMBOL_INTERNAL        ; -- ?
        _handles_lock

        test    rbx, rbx
        jnz      .1
        mov     ebx, t_value
        _return

.1:
        _ mutex_trylock
        next
endcode

; ### unlock_handles
code unlock_handles, 'unlock_handles', SYMBOL_INTERNAL   ; --
        _handles_lock

        test    rbx, rbx
        jnz     .1
        _drop
        _return

.1:
        _ mutex_unlock
        _tagged_if_not .2
        _error "mutex_unlock failed"
        _then .2
        next
endcode

; ### new_handle
code new_handle, 'new_handle', SYMBOL_INTERNAL  ; object -- handle

        _ safepoint

        _ trylock_handles
        cmp     rbx, f_value
        poprbx
        je      new_handle

        _ get_empty_handle              ; -- object handle/0
        test    rbx, rbx
        jz     .1

        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     [rbx], rax

%ifdef TAGGED_HANDLES
        _tag_handle
%endif

        _increment_allocation_count
        _ unlock_handles
        _return

.1:                                     ; -- object 0
        _drop

        _ gc_collect

        _ get_empty_handle
        test    rbx, rbx
        jz     .2

        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     [rbx], rax

%ifdef TAGGED_HANDLES
        _tag_handle
%endif

        _increment_allocation_count
        _ unlock_handles
        _return
.2:

        _ unlock_handles
        _error "out of handles"
        next
endcode

; ### handle?
code handle?, 'handle?'                 ; x -- ?
%ifdef TAGGED_HANDLES
        cmp     bl, HANDLE_TAG
        jne     .1
%else
        ; handles are 8-byte aligned
        test    bl, 7
        jnz     .1

        ; must point into handle space
        cmp     rbx, [handle_space_]
        jb .1
        cmp     rbx, [handle_space_free_]
        jae .1
%endif
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### verified-handle?
code verified_handle?, 'verified-handle?'       ; x -- ?
        cmp     bl, HANDLE_TAG
        jne     .no
        shr     rbx, HANDLE_TAG_BITS
        ; must point into handle space
        cmp     rbx, [handle_space_]
        jb .no
        cmp     rbx, [handle_space_free_]
        jae .no
        mov     ebx, t_value
        _return
.no:
        mov     ebx, f_value
        next
endcode

; ### deref
code deref, 'deref', SYMBOL_INTERNAL    ; x -- object-address/0
%ifdef TAGGED_HANDLES
        cmp     bl, HANDLE_TAG
        jne     .1
%else
        ; handles are 8-byte aligned
        test    bl, 7
        jnz     .1

        ; must point into handle space
        cmp     rbx, [handle_space_]
        jb .1
        cmp     rbx, [handle_space_free_]
        jae .1
%endif
        ; valid handle
        _handle_to_object_unsafe        ; -- object-address/0
        _return

.1:
        ; -- x
        ; drop 0
        xor     ebx, ebx
        next
endcode

; ### release_handle_unsafe
code release_handle_unsafe, 'release_handle_unsafe', SYMBOL_INTERNAL    ; handle --
        ; zero out the stored address
        xor     eax, eax
        mov     qword [rbx], rax

        ; add handle to recycled handles vector
        _recycled_handles_vector
        _ vector_push_unchecked         ; --

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

        pushrbx
        mov     rbx, [handle_space_]
        _begin .1
        _dup
        pushrbx
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
        pushrbx
        mov     rbx, [handle_space_free_]
        pushrbx
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

; ### .handles
code dot_handles, '.handles'
        _ ?nl
        pushrbx
        mov     rbx, [handle_space_free_]
        pushrbx
        mov     rbx, [handle_space_]
        _minus

;         _ cell
;         _ slash
        shr     rbx, 3

        _tag_fixnum
        _ decimal_dot
        _write "handles"

        pushrbx
        mov     rbx, [handle_space_]
        _begin .1
        _dup
        pushrbx
        mov     rbx, [handle_space_free_]
        _ult
        _while .1
        _ ?nl
        _dup
        _ untagged_dot
        _dup
        _fetch
        _dup
        _ untagged_dot
        _if .2
        _dup
        _ dot_object
        _then .2
        _cellplus
        _repeat .1
        _drop
        next
endcode

; ### each-handle
code each_handle, 'each-handle'         ; callable --
        _ callable_raw_code_address
        push    r12
        mov     r12, rbx                ; code address in r12
        _drop                           ; --
        pushrbx
        mov     rbx, [handle_space_]
        _begin .1
        _dup
        pushrbx
        mov     rbx, [handle_space_free_]
        _ult
        _while .1                       ; -- addr
        _dup
        call    r12
        _cellplus
        _repeat .1
        _drop
        pop     r12
        next
endcode
