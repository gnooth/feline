; Copyright (C) 2012-2020 Peter Graves <gnooth@gmail.com>

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

asm_global experimental_, NIL

; ### x?
code x?, 'x?'                           ; void -> ?
        _dup
        mov     rbx, [experimental_]
        next
endcode

; ### +x
code enable_x, '+x'
        mov     qword [experimental_], TRUE
        next
endcode

; ### -x
code disable_x, '-x'
        mov     qword [experimental_], NIL
        next
endcode

; maximum number of local variables in a definition
%define MAX_LOCALS      8

%macro  _locals_enter 0
        push    r14
        sub     rsp, BYTES_PER_CELL * MAX_LOCALS
        mov     r14, rsp
%endmacro

%macro  _locals_leave 0
        add     rsp, BYTES_PER_CELL * MAX_LOCALS
        pop     r14
%endmacro

; ### local_get
code local_get, 'local_get', SYMBOL_INTERNAL    ; index -> value
        _check_index
        mov     rbx, [r14 + rbx * BYTES_PER_CELL]
        next
endcode

; ### local_0_get
inline local_0_get, 'local_0_get', SYMBOL_INTERNAL      ; -> value
        _dup
        mov     rbx, [r14]
endinline

; ### local_1_get
inline local_1_get, 'local_1_get', SYMBOL_INTERNAL      ; -> value
        _dup
        mov     rbx, [r14 + BYTES_PER_CELL]
endinline

; ### local_2_get
inline local_2_get, 'local_2_get', SYMBOL_INTERNAL      ; -> value
        _dup
        mov     rbx, [r14 + BYTES_PER_CELL * 2]
endinline

; ### local_3_get
inline local_3_get, 'local_3_get', SYMBOL_INTERNAL      ; -> value
        _dup
        mov     rbx, [r14 + BYTES_PER_CELL * 3]
endinline

; ### local_4_get
inline local_4_get, 'local_4_get', SYMBOL_INTERNAL      ; -> value
        _dup
        mov     rbx, [r14 + BYTES_PER_CELL * 4]
endinline

; ### local_5_get
inline local_5_get, 'local_5_get', SYMBOL_INTERNAL      ; -> value
        _dup
        mov     rbx, [r14 + BYTES_PER_CELL * 5]
endinline

; ### local_6_get
inline local_6_get, 'local_6_get', SYMBOL_INTERNAL      ; -> value
        _dup
        mov     rbx, [r14 + BYTES_PER_CELL * 6]
endinline

; ### local_7_get
inline local_7_get, 'local_7_get', SYMBOL_INTERNAL      ; -> value
        _dup
        mov     rbx, [r14 + BYTES_PER_CELL * 7]
endinline

asm_global local_getters_, NIL

; ### local-getters
code local_getters, 'local-getters'     ; -> vector
        _dup
        mov     rbx, [local_getters_]
        next
endcode

; ### initialize_local_getters
code initialize_local_getters, 'initialize_local_getters', SYMBOL_INTERNAL
        _lit 16
        _ new_vector_untagged
        mov     [local_getters_], rbx
        _drop

        _lit local_getters_
        _ gc_add_root

        _dup
        mov     rbx, [local_getters_]

        _lit S_local_0_get
        _over
        _ vector_push

        _lit S_local_1_get
        _over
        _ vector_push

        _lit S_local_2_get
        _over
        _ vector_push

        _lit S_local_3_get
        _over
        _ vector_push

        _lit S_local_4_get
        _over
        _ vector_push

        _lit S_local_5_get
        _over
        _ vector_push

        _lit S_local_6_get
        _over
        _ vector_push

        _lit S_local_7_get
        _over
        _ vector_push

        _drop

        next
endcode

; ### local-getter
code local_getter, 'local-getter'       ; index -> symbol
        _ local_getters
        _ vector_nth
        next
endcode

; ### local_set
code local_set, 'local_set', SYMBOL_INTERNAL            ; value index -> void
        _check_index
        _cells
        add     rbx, r14
        mov     rax, [rbp]
        mov     [rbx], rax
        _2drop
        next
endcode

; ### local_0_set
inline local_0_set, 'local_0_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14], rbx
        _drop
endinline

; ### local_1_set
inline local_1_set, 'local_1_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL], rbx
        _drop
endinline

; ### local_2_set
inline local_2_set, 'local_2_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 2], rbx
        _drop
endinline

; ### local_3_set
inline local_3_set, 'local_3_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 3], rbx
        _drop
endinline

; ### local_4_set
inline local_4_set, 'local_4_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 4], rbx
        _drop
endinline

; ### local_5_set
inline local_5_set, 'local_5_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 5], rbx
        _drop
endinline

; ### local_6_set
inline local_6_set, 'local_6_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 6], rbx
        _drop
endinline

; ### local_7_set
inline local_7_set, 'local_7_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 7], rbx
        _drop
endinline

asm_global local_setters_, NIL

; ### local-setters
code local_setters, 'local-setters'     ; -> vector
        _dup
        mov     rbx, [local_setters_]
        next
endcode

; ### initialize_local_setters
code initialize_local_setters, 'initialize_local_setters', SYMBOL_INTERNAL
        _lit 16
        _ new_vector_untagged
        mov     [local_setters_], rbx
        _drop

        _lit local_setters_
        _ gc_add_root

        _dup
        mov     rbx, [local_setters_]

        _lit S_local_0_set
        _over
        _ vector_push

        _lit S_local_1_set
        _over
        _ vector_push

        _lit S_local_2_set
        _over
        _ vector_push

        _lit S_local_3_set
        _over
        _ vector_push

        _lit S_local_4_set
        _over
        _ vector_push

        _lit S_local_5_set
        _over
        _ vector_push

        _lit S_local_6_set
        _over
        _ vector_push

        _lit S_local_7_set
        _over
        _ vector_push

        _drop

        next
endcode

; ### local-setter
code local_setter, 'local-setter'       ; index -> symbol
        _ local_setters
        _ vector_nth
        next
endcode

asm_global using_locals?_, NIL

; ### using-locals?
code using_locals?, 'using-locals?'     ; -> ?
        _dup
        mov     rbx, [using_locals?_]
        next
endcode

asm_global locals_, NIL

; ### locals
code locals, 'locals'                   ; -> hashtable/nil
        _dup
        mov     rbx, [locals_]
        next
endcode

asm_global locals_count_, 0

; ### locals-count
code locals_count, 'locals-count'       ; -> n
        _dup
        mov     rbx, [locals_count_]
        _tag_fixnum
        next
endcode

asm_global local_names_, NIL

; ### local-names
code local_names, 'local-names'
        _dup
        mov     rbx, [local_names_]
        next
endcode

; ### cold_initialize_locals
code cold_initialize_locals, 'cold_initialize_locals', SYMBOL_INTERNAL

        _lit locals_
        _ gc_add_root

        _lit local_names_
        _ gc_add_root

        _ initialize_local_getters
        _ initialize_local_setters

        next
endcode

; ### locals-enter
always_inline locals_enter, 'locals-enter'
        _locals_enter
endinline

; ### locals-leave
always_inline locals_leave, 'locals-leave'
        _locals_leave
endinline

%macro  _n_locals_enter 0
        shl     rbx, 3                  ; convert cells to bytes
        push    r14
        sub     rsp, rbx
        mov     r14, rsp
        _drop
%endmacro

%macro  _n_locals_leave 0
        shl     rbx, 3                  ; convert cells to bytes
        add     rsp, rbx
        pop     r14
        _drop
%endmacro

; ### n_locals_enter
always_inline n_locals_enter, 'n_locals_enter' ; n -> void
;         _check_fixnum
        _untag_fixnum
        _n_locals_enter
endinline

; ### n_locals_leave
always_inline n_locals_leave, 'n_locals_leave' ; n -> void
;         _check_fixnum
        _untag_fixnum
        _n_locals_leave
endinline

; ### initialize-locals
code initialize_locals, 'initialize-locals'

        _lit MAX_LOCALS
        _ new_hashtable_untagged
        mov     [locals_], rbx
        _drop

        mov     qword [locals_count_], 0

        _lit MAX_LOCALS * 2
        _ new_hashtable_untagged
        mov     [local_names_], rbx
        _drop

        mov     qword [using_locals?_], TRUE

        cmp     qword [experimental_], NIL
        jne     .experimental

        ; old code (non-experimental)
        _lit S_locals_enter
        _lit tagged_zero
        _ current_definition
        _ vector_insert_nth

        jmp     .continue

        ; experimental code
.experimental:
        _lit S_n_locals_enter
        _lit tagged_zero
        _ current_definition
        _ vector_insert_nth

        _ current_definition
        _ ?nl
        _ dot_object

        _lit tagged_fixnum(1)
        _lit tagged_zero
        _ current_definition
        _ vector_insert_nth

        _ current_definition
        _ ?nl
        _ dot_object

.continue:

        ; old code (non-experimental)

        ; check for return-if-no-locals
        ; if found, replace with return-if-locals
        _ current_definition
        _quotation .1
        ; -> element index
        _swap
        _lit S_return_if_no_locals
        _eq?
        _tagged_if .2
        _lit S_return_if_locals
        _swap
        _ current_definition
        _ vector_set_nth
        _else .2
        _drop
        _then .2
        _end_quotation .1
        _ vector_each_index

        ; check for ?exit-no-locals
        ; if found, replace with ?exit-locals
        _ current_definition
        _quotation .3
        _swap
        _lit S_?exit_no_locals
        _eq?
        _tagged_if .4
        _lit S_?exit_locals
        _swap
        _ current_definition
        _ vector_set_nth
        _else .4
        _drop
        _then .4
        _end_quotation .3
        _ vector_each_index

        next
endcode

; ### maybe-initialize-locals
code maybe_initialize_locals, 'maybe-initialize-locals'

        _ accum
        _ get
        _ current_definition
        _ eq?
        _tagged_if_not .1
        _error "ERROR: a local variable cannot be declared in this scope."
        _then .1

        _ using_locals?
        _tagged_if_not .2
        _ initialize_locals
        _then .2
        next
endcode

; ### error-duplicate-local-name
code error_duplicate_local_name, 'error-duplicate-local-name'
        _quote "ERROR: duplicate local name %S."
        _ format
        _ error
        next
endcode

; ### add-local
code add_local, 'add-local'             ; string -> void

        cmp     qword [locals_count_], MAX_LOCALS
        jb      .1
        _error "too many locals"

.1:
        ; is there already a local with this name?
        _dup
        _ locals
        _ hashtable_at
        _tagged_if .2
        _ error_duplicate_local_name
        _then .2                        ; -> string

        _ locals_count
        _over
        _ locals
        _ hashtable_set_at              ; -> string

        _ locals_count
        _ local_getter
        _ verify_symbol
        _swap
        _ local_names
        _ hashtable_set_at              ; -> void

        add     qword [locals_count_], 1

        next
endcode

; ### add-local-setter
code add_local_setter, 'add-local-setter'       ; string -> void

        cmp     qword [locals_count_], MAX_LOCALS
        jb      .1
        _error "too many locals"

.1:
        ; is this already a local name?
        _dup
        _ local_names
        _ hashtable_at
        _tagged_if .2
        _ error_duplicate_local_name
        _then .2                        ; -> string

        _ locals_count
        _ local_setter
        _ verify_symbol
        _swap
        _ local_names
        _ hashtable_set_at              ; -> void

        next
endcode

; ### forget-locals
code forget_locals, 'forget-locals'
        mov     qword [locals_], NIL
        mov     qword [locals_count_], 0
        mov     qword [local_names_], NIL
        mov     qword [using_locals?_], NIL
        next
endcode
