; Copyright (C) 2016-2017 Peter Graves <gnooth@gmail.com>

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

%macro  _handle_to_object_unsafe 0
        _fetch
%endmacro

; ### handle-space
feline_global handle_space, 'handle-space', 0

; ### handle-space-free
feline_global handle_space_free, 'handle-space-free', 0

; ### handle-space-limit
feline_global handle_space_limit, 'handle-space-limit', 0

%define HANDLE_SPACE_SIZE 1024*1024*8   ; 8 mb (1048576 handles)

asm_global unused, 1024*1024

; ### unused-handles
code   unused_handles, 'unused-handles' ; -- n
        pushrbx
        mov     rbx, [unused]
        _tag_fixnum
        next
endcode

; ### initialize-handle-space
code initialize_handle_space, 'initialize-handle-space' ; --
        _from_global handle_space

        test    rbx, rbx
        jz      .1

        ; handle space was reserved in main.c
        _dup
        _to_global handle_space_free
        _lit HANDLE_SPACE_SIZE
        shl     rbx, 1          ; soft limit is HANDLE_SPACE_SIZE * 2

        _dup
        shr     rbx, 3          ; convert bytes to handles
        mov     [unused], rbx
        poprbx

        _plus
        _to_global handle_space_limit

        jmp     .2

.1:
        _drop

        ; no handle space was reserved
        _lit HANDLE_SPACE_SIZE
        _dup
        _ iallocate
        _dup
        _to_global handle_space
        _dup
        _to_global handle_space_free
        _plus
        _to_global handle_space_limit

.2:
        _lit 256
        _ new_vector_untagged
        _to free_handles

        next
endcode

; ### free-handles
value free_handles, 'free-handles', 0

; ### empty-handles
code empty_handles, 'empty-handles'     ; -- tagged-fixnum
        _ free_handles
        _?dup_if .1
        _handle_to_object_unsafe
        _vector_length
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
        _ free_handles
        _ vector_length
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

; ### get-empty-handle
code get_empty_handle, 'get-empty-handle'       ; -- handle/0
        _ free_handles
        _?dup_if .1
        _handle_to_object_unsafe        ; -- vector
        _dup
        _vector_length
        _zgt
        _if .2
        _ vector_pop_unchecked          ; -- handle
        _return
        _then .2
        _drop                   ; --
        _then .1

        cmp     qword [unused], 0
        jz .3
        _from_global handle_space_free
        _from_global handle_space_limit
        _ult
        _if .4
        _from_global handle_space_free  ; address of handle to be returned
        _dup
        _cellplus
        _to_global handle_space_free
        sub     qword [unused], 1
        _return
        _then .4

.3:
        pushrbx
        xor     ebx, ebx
        next
endcode

; ### total-allocations
feline_global total_allocations, 'total-allocations', tagged_zero

; ### recent-allocations
; number of allocations since last gc
feline_global recent_allocations, 'recent-allocations', tagged_zero

%macro _increment_allocation_count 0
        add qword [S_total_allocations_symbol_value], 1 << TAG_BITS
        add qword [S_recent_allocations_symbol_value], 1 << TAG_BITS
%endmacro

; ### new-handle
code new_handle, 'new-handle'   ; object -- handle
        _ get_empty_handle      ; -- object handle/0
        test    rbx, rbx
        jz     .1
        _tuck
        _store
        _increment_allocation_count
        _return
.1:                             ; -- object 0
        _drop

        _ gc

        _ get_empty_handle
        test    rbx, rbx
        jz     .2
        _tuck
        _store
        _increment_allocation_count
        _return
.2:
        _error "out of handles"
        next
endcode

; ### get_handle_for_object
subroutine get_handle_for_object        ; object -- handle
; called from C with object in arg0_register
; return handle in rax

        push    rbx
        push    rbp

        ; REVIEW
        ; 16 cells for data stack (arbitrary)
        mov     rbp, rsp
        sub     rsp, 256

        mov     rbx, arg0_register
        _ new_handle
        mov     rax, rbx

        add     rsp, 256

        pop     rbp
        pop     rbx

        ret
endsub

; ### handle?
code handle?, 'handle?'                 ; x -- ?
        ; tag bits must be 0
        test    bl, TAG_MASK
        jnz     .1

        ; must point into handle space
        cmp     rbx, [S_handle_space_symbol_value]
        jb .1
        cmp     rbx, [S_handle_space_free_symbol_value]
        jae .1

        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### deref
code deref, 'deref'     ; x -- object-address/0
        ; tag bits must be 0
        test    bl, TAG_MASK
        jnz     .1

        ; must point into handle space
        cmp     rbx, [S_handle_space_symbol_value]
        jb .1
        cmp     rbx, [S_handle_space_free_symbol_value]
        jae .1

        ; valid handle
        mov     rbx, [rbx]      ; -- object-address/0
        _return

.1:
        ; -- x
        ; drop 0
        xor     ebx, ebx
        next
endcode

; ### find-handle
code find_handle, 'find-handle'         ; object -- handle/0
        _from_global handle_space       ; -- object addr
        _begin .2
        _dup
        _from_global handle_space_free
        _ult
        _while .2                       ; -- object addr
        _twodup                         ; -- object addr object handle
        _fetch                          ; -- object addr object object2
        _equal
        _if .3
        ; found it!
        _nip
        _return
        _then .3                        ; -- object addr

        _cellplus
        _repeat .2
        _drop                           ; -- object
        ; not found
        _ ?nl
        _write "can't find handle for object at "
        _ untagged_dot
        ; return false
        _zero
        next
endcode

; ### release-handle-unsafe
code release_handle_unsafe, 'release-handle-unsafe' ; handle --
        ; zero out the stored address
        xor     eax, eax
        mov     qword [rbx], rax

        ; add handle to free-handles vector
        _ free_handles
        _handle_to_object_unsafe        ; -- handle vector
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

        _from_global handle_space
        _begin .1
        _dup
        _from_global handle_space_free
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
        _from_global handle_space_free
        _from_global handle_space
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
        _from_global handle_space_free
        _from_global handle_space
        _minus

;         _ cell
;         _ slash
        shr     rbx, 3

        _tag_fixnum
        _ decimal_dot
        _write "handles"

        _from_global handle_space
        _begin .1
        _dup
        _from_global handle_space_free
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
        _ callable_code_address
        push    r12
        mov     r12, rbx                ; code address in r12
        _drop                           ; --
        _from_global handle_space       ; -- addr
        _begin .1
        _dup
        _from_global handle_space_free
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
