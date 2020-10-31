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

; ### local-get
code local_get, 'local-get'             ; index -> value
        _check_index
        mov     rbx, [r14 + rbx * BYTES_PER_CELL]
        next
endcode

; ### local-set
code local_set, 'local-set'             ; value index -> void
        _check_index
        _cells
        add     rbx, r14
        mov     rax, [rbp]
        mov     [rbx], rax
        _2drop
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
code locals_count, 'locals-count'       ; void -> fixnum
        _dup
        mov     rbx, [locals_count_]
        _tag_fixnum
        next
endcode

; ### set-locals-count
code set_locals_count, 'set-locals-count' ; n -> void
        _check_index
        mov     [locals_count_], rbx
        _drop
        next
endcode

%macro _increment_locals_count 0
        add     qword [locals_count_], 1
%endmacro

; ### cold_initialize_locals
code cold_initialize_locals, 'cold_initialize_locals', SYMBOL_INTERNAL
        _lit locals_
        _ gc_add_root
        next
endcode

; ### initialize-locals
code initialize_locals, 'initialize-locals'

        _lit 16
        _ new_hashtable_untagged
        mov     [locals_], rbx
        _drop

        mov     qword [locals_count_], 0

        mov     qword [using_locals?_], TRUE

        ; check for return-if-no-locals
        ; if found, replace with return-if-locals
        _ current_definition
        _quotation .1
        ; -> element index
        _swap
        _symbol ?return_no_locals
        _eq?
        _tagged_if .2
        _symbol ?return_locals
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
        _symbol ?exit_no_locals
        _eq?
        _tagged_if .4
        _symbol ?exit_locals
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

; ### find-local
code find_local, 'find-local'           ; string -> fixnum/nil
        _ locals
        _ hashtable_at
        cmp     rbx, NIL
        je      .1
        _verify_fixnum
.1:
        next
endcode

; ### add-local-name
code add_local_name, 'add-local-name'   ; string -> void

        ; is there already a local with this name?
        _dup
        _ find_local
        _tagged_if .1
        _ error_duplicate_local_name
        _then .1                        ; -> string

%if 0
        _ locals_count                  ; -> string n
        _swap                           ; -> n string
        _ locals                        ; -> n string hashtable
        _ hashtable_set_at              ; -> string
%else
        _ locals_count                  ; -> string n
        _over                           ; -> string n string
        _ locals                        ; -> string n string hashtable
        _ hashtable_set_at              ; -> string

        _ locals_count                  ; -> string n
        _swap                           ; -> n string
        _ current_quotation             ; -> n string quotation
        _ verify_quotation
        _ quotation_add_local_name      ; -> void
%endif

        next
endcode

; ### forget-locals
code forget_locals, 'forget-locals'
        mov     qword [locals_], NIL
        mov     qword [locals_count_], 0
        mov     qword [using_locals?_], NIL
        next
endcode
