; Copyright (C) 2012-2019 Peter Graves <gnooth@gmail.com>

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

; maximum number of local variables in a definition
%define MAX_LOCALS      8

; ### max-locals
code max_locals, 'max-locals'           ; -> n
        pushrbx
        mov     ebx, tagged_fixnum(MAX_LOCALS)
        next
endcode

%define LOCALS_USE_RETURN_STACK

%ifdef LOCALS_USE_RETURN_STACK

%macro  _locals_enter 0
        push    r14
        sub     rsp, BYTES_PER_CELL * MAX_LOCALS
        mov     r14, rsp
%endmacro

%macro  _locals_leave 0
        add     rsp, BYTES_PER_CELL * MAX_LOCALS
        pop     r14
%endmacro

%else

%macro  _locals_enter 0
        push    r14
        lea     r14, [r14 - BYTES_PER_CELL * MAX_LOCALS];
%endmacro

%macro  _locals_leave 0
        pop     r14
%endmacro

%endif

%ifndef LOCALS_USE_RETURN_STACK

asm_global lp0_, 0

%macro _lp0 0
        _dup
        mov     rbx, [lp0_]
%endmacro

; ### lp0
code lp0, 'lp0'                         ; -- tagged-address
        _lp0
        _tag_fixnum
        next
endcode

%macro  _lpstore 0
        mov     r14, rbx
        _drop
%endmacro

%macro  _lpfetch 0
        _dup
        mov     rbx, r14
%endmacro

; ### lp@
code lpfetch, 'lp@'                     ; -- tagged-address
        _lpfetch
        _tag_fixnum
        next
endcode

%endif

; ### local@
code local_get, 'local@'                ; index -> value
        _check_index
        mov     rbx, [r14 + rbx * BYTES_PER_CELL]
        next
endcode

; ### local_0_get
inline local_0_get, 'local_0_get', SYMBOL_INTERNAL      ; -> value
        pushrbx
        mov     rbx, [r14]
endinline

; ### local_1_get
inline local_1_get, 'local_1_get', SYMBOL_INTERNAL      ; -> value
        pushrbx
        mov     rbx, [r14 + BYTES_PER_CELL]
endinline

; ### local_2_get
inline local_2_get, 'local_2_get', SYMBOL_INTERNAL      ; -> value
        pushrbx
        mov     rbx, [r14 + BYTES_PER_CELL * 2]
endinline

; ### local_3_get
inline local_3_get, 'local_3_get', SYMBOL_INTERNAL      ; -> value
        pushrbx
        mov     rbx, [r14 + BYTES_PER_CELL * 3]
endinline

; ### local_4_get
inline local_4_get, 'local_4_get', SYMBOL_INTERNAL      ; -> value
        pushrbx
        mov     rbx, [r14 + BYTES_PER_CELL * 4]
endinline

; ### local_5_get
inline local_5_get, 'local_5_get', SYMBOL_INTERNAL      ; -> value
        pushrbx
        mov     rbx, [r14 + BYTES_PER_CELL * 5]
endinline

; ### local_6_get
inline local_6_get, 'local_6_get', SYMBOL_INTERNAL      ; -> value
        pushrbx
        mov     rbx, [r14 + BYTES_PER_CELL * 6]
endinline

; ### local_7_get
inline local_7_get, 'local_7_get', SYMBOL_INTERNAL      ; -> value
        pushrbx
        mov     rbx, [r14 + BYTES_PER_CELL * 7]
endinline

asm_global local_getters_, f_value

; ### local-getters
code local_getters, 'local-getters'     ; -> vector
        pushrbx
        mov     rbx, [local_getters_]
        next
endcode

; ### initialize_local_getters
code initialize_local_getters, 'initialize_local_getters', SYMBOL_INTERNAL
        _lit 16
        _ new_vector_untagged
        mov     [local_getters_], rbx
        poprbx

        _lit local_getters_
        _ gc_add_root

        pushrbx
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

; ### local!
code local_set, 'local!'                ; value index --
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
        poprbx
endinline

; ### local_1_set
inline local_1_set, 'local_1_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL], rbx
        poprbx
endinline

; ### local_2_set
inline local_2_set, 'local_2_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 2], rbx
        poprbx
endinline

; ### local_3_set
inline local_3_set, 'local_3_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 3], rbx
        poprbx
endinline

; ### local_4_set
inline local_4_set, 'local_4_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 4], rbx
        poprbx
endinline

; ### local_5_set
inline local_5_set, 'local_5_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 5], rbx
        poprbx
endinline

; ### local_6_set
inline local_6_set, 'local_6_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 6], rbx
        poprbx
endinline

; ### local_7_set
inline local_7_set, 'local_7_set', SYMBOL_INTERNAL      ; value -> void
        _debug_?enough_1
        mov     [r14 + BYTES_PER_CELL * 7], rbx
        poprbx
endinline

asm_global local_setters_, f_value

; ### local-setters
code local_setters, 'local-setters'     ; -> vector
        pushrbx
        mov     rbx, [local_setters_]
        next
endcode

; ### initialize_local_setters
code initialize_local_setters, 'initialize_local_setters', SYMBOL_INTERNAL
        _lit 16
        _ new_vector_untagged
        mov     [local_setters_], rbx
        poprbx

        _lit local_setters_
        _ gc_add_root

        pushrbx
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

%ifndef LOCALS_USE_RETURN_STACK

; ### allocate_locals_stack
code allocate_locals_stack, 'allocate_locals_stack', SYMBOL_INTERNAL    ; -- raw-lp0
        _lit 4096
        _dup
        _ raw_allocate
        _plus
        next
endcode

; ### free_locals_stack
code free_locals_stack, 'free_locals_stack', SYMBOL_INTERNAL
; called by BYE to make sure we're freeing all allocated memory
        _lp0
        _?dup
        _if .1
        _lit 4096
        _minus
        _ raw_free
        _then .1
        next
endcode

%endif

asm_global using_locals?_, f_value

; ### using-locals?
code using_locals?, 'using-locals?'     ; -> ?
        pushrbx
        mov     rbx, [using_locals?_]
        next
endcode

asm_global locals_, f_value

; ### locals
code locals, 'locals'                   ; -- hashtable/f
        pushrbx
        mov     rbx, [locals_]
        next
endcode

asm_global locals_count_, 0

; ### locals-count
code locals_count, 'locals-count'       ; -- n
        pushrbx
        mov     rbx, [locals_count_]
        _tag_fixnum
        next
endcode

asm_global local_names_, f_value

; ### local-names
code local_names, 'local-names'
        pushrbx
        mov     rbx, [local_names_]
        next
endcode

; ### cold_initialize_locals
code cold_initialize_locals, 'cold_initialize_locals', SYMBOL_INTERNAL

%ifndef LOCALS_USE_RETURN_STACK
        _ allocate_locals_stack
        mov     [lp0_], rbx
        _lpstore
%endif

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

; ### initialize-locals
code initialize_locals, 'initialize-locals'

        _lit MAX_LOCALS
        _ new_hashtable_untagged
        mov     [locals_], rbx
        poprbx

        mov     qword [locals_count_], 0

        _lit MAX_LOCALS * 2
        _ new_hashtable_untagged
        mov     [local_names_], rbx
        poprbx

        mov     qword [using_locals?_], t_value

        _lit S_locals_enter
        _lit tagged_zero
        _ current_definition
        _ vector_insert_nth

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
        _error "duplicate local name"
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
        _error "duplicate local name"
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
code forget_locals, 'forget-locals'     ; --
        mov     qword [locals_], f_value
        mov     qword [locals_count_], 0
        mov     qword [local_names_], f_value
        mov     qword [using_locals?_], f_value
        next
endcode
