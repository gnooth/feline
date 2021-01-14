; Copyright (C) 2016-2021 Peter Graves <gnooth@gmail.com>

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

asm_global compiler_lock_, 0

%macro  _compiler_lock 0
        _dup
        mov     rbx, [compiler_lock_]
%endmacro

; ### initialize_compiler_lock
code initialize_compiler_lock, 'initialize_compiler_lock', SYMBOL_INTERNAL ; void -> void
        _ make_mutex
        _ verify_mutex
        mov     [compiler_lock_], rbx
        _drop
        _lit compiler_lock_
        _ gc_add_root
        next
endcode

; ### trylock_compiler
code trylock_compiler, 'trylock_compiler', SYMBOL_INTERNAL ; -> ?
        _compiler_lock

        test    rbx, rbx
        jnz      .1
        mov     ebx, TRUE
        next

.1:
        _ mutex_trylock
        next
endcode

; ### lock-compiler
code lock_compiler, 'lock-compiler'     ; void -> void
        _ trylock_compiler
        cmp     rbx, NIL
        _drop
        je      lock_compiler
        next
endcode

; ### unlock-compiler
code unlock_compiler, 'unlock-compiler' ; void -> void

        cmp     qword [compiler_lock_], 0
        jz      .exit

        _compiler_lock
        _ mutex_unlock
        _tagged_if_not .2
        _error "mutex_unlock failed"
        _then .2

.exit:
        _rep_return
endcode

; tuple: compiler-context
;     pc
;     origin
;     pending ;

; ### make-compiler-context
code make_compiler_context, 'make-compiler-context' ; void -> context
; REVIEW maybe add quotation slot
        _nil                            ; pc
        _nil                            ; origin
        _lit tagged_fixnum(10)
        _ make_vector                   ; pending
        _ three_array
        next
endcode

feline_global current_context, 'current-context'

; ### current-context!
code set_current_context, 'current-context!' ; x -> void
        xchg    [S_current_context_symbol_value], rbx
        _drop
        next
endcode

feline_global context_stack, 'context-stack'

; ### new-context
code new_context, 'new-context'         ; void -> void
        _ current_context
        _ context_stack
        _ vector_push
        _ make_compiler_context
        _ set_current_context
        next
endcode

; ### restore-context
code restore_context, 'restore-context' ; void -> void
        _ context_stack
        _ vector_pop
        _ set_current_context
        next
endcode

; ### pc
code pc, 'pc'                           ; void -> fixnum
        _lit tagged_zero
        _ current_context
        _ array_nth_unsafe
        next
endcode

; ### pc!
code set_pc, 'pc!'                      ; fixnum -> void
        _lit tagged_zero
        _ current_context
        _ array_set_nth_unsafe
        next
endcode

; ### pc+!
code pc_plus_store, 'pc+!'              ; fixnum -> void
        _check_fixnum                   ; -> untagged-fixnum
        _ current_context               ; -> untagged-fixnum array
        _handle_to_object_unsafe        ; -> untagged-fixnum ^array

        ; pc is first element of array
        mov     rax, [rbx + ARRAY_DATA_OFFSET]
        shl     qword [rbp], FIXNUM_TAG_BITS
        add     rax, qword [rbp]
        mov     [rbx + ARRAY_DATA_OFFSET], rax

        _2drop
        next
endcode

%macro _pc 0
        _ pc
        _check_fixnum
%endmacro

; ### origin
code origin, 'origin'                   ; void -> fixnum
        _lit tagged_fixnum(1)
        _ current_context
        _ array_nth
        next
endcode

; ### origin!
code set_origin, 'origin!'              ; fixnum -> void
        _lit tagged_fixnum(1)
        _ current_context
        _ array_set_nth
        next
endcode

; ### pending
code pending, 'pending'                 ; void -> fixnum
        _lit tagged_fixnum(2)
        _ current_context
        _ array_nth
        next
endcode

; ### pending-last
code pending_last, 'pending-last'       ; void -> node
        _ pending
        _ vector_last
        next
endcode

; ### pending-last-value
code pending_last_value, 'pending-last-value' ; void -> x
        _ pending
        _ vector_last
        _ node_literal_value
        next
endcode

; ### pending-remove-last
code pending_remove_last, 'pending-remove-last' ; void -> void
        _ pending
        _ vector_pop_star
        next
endcode

asm_global last_allocation_, NIL

; ### last-allocation
code last_allocation, "last-allocation" ; void -> fixnum
        _dup
        mov     rbx, [last_allocation_]
        next
endcode

; ### initialize-code-block
code initialize_code_block, 'initialize-code-block' ; size -> address
        _check_fixnum
        _ raw_allocate_executable       ; -> raw-address
        _tag_fixnum

        mov     rax, rbx
        xchg    [last_allocation_], rax

        next
endcode

; tuple: node
;     literal-value
;     op                                  // symbol
;     type                                // result type
; ;

; ### make-literal-node
code make_literal_node, 'make-literal-node' ; literal -> node
        _nil                            ; operator
        _nil                            ; result type
        _ three_array
        next
endcode

; ### make-literal-node/2
code make_literal_node_2, 'make-literal-node/2' ; literal type -> node
        _nil                            ; operator
        _swap                           ; -> literal nil type
        _ three_array
        next
endcode

; ### make-operator-node
code make_operator_node, 'make-operator-node' ; operator -> node
        _nil                            ; literal value
        _swap
        _nil                            ; result type
        _ three_array
        next
endcode

; ### node-literal-value
code node_literal_value, 'node-literal-value' ; node -> literal-value
        _lit tagged_zero
        _swap
        _ array_nth
        next
endcode

; ### node-operator
code node_operator, 'node-operator'     ; node -> symbol
        _lit tagged_fixnum(1)
        _swap
        _ array_nth
        next
endcode

; ### node-result-type
code node_result_type, 'node-result-type' ; node -> result-type
        _lit tagged_fixnum(2)
        _swap
        _ array_nth
        next
endcode

; ### precompile-object
code precompile_object, 'precompile-object' ; object -> node
        _dup
        _ symbol?
        _tagged_if .1
        _ make_operator_node
        _else .1
        _ make_literal_node
        _then .1
        next
endcode

; ### add-code-size
code add_code_size, 'add-code-size'     ; accum node -> accum
; FIXME arbitrary for now
        _ node_operator
        _dup
        _tick cond
        _eq?
        _swap
        _tick match_star
        _eq?
        _ feline_or
        _tagged_if .1
        _lit 512
        _else .1
        _lit 25
        _then .1
        _plus
        next
endcode

; ### emit-byte
code emit_byte, 'emit-byte'             ; byte -> void
        _verify_fixnum
        _ pc
        _ cstore
        _lit tagged_fixnum(1)
        _ pc_plus_store
        next
endcode

; ### emit-bytes
code emit_bytes, 'emit-bytes'           ; bytes -> void
        _tick emit_byte
        _ each
        next
endcode

%macro _emit_byte 1
        _dup
        mov     rbx, tagged_fixnum(%1)
        _ emit_byte
%endmacro

; ### emit-int32
code emit_int32, 'emit-int32'           ; int32 -> void
        _ verify_int32
        _ pc
        _ lstore
        _lit tagged_fixnum(4)
        _ pc_plus_store
        next
endcode

; ### emit_raw_dword
code emit_raw_dword, 'emit_raw_dword'   ; dword -> void
        _tag_fixnum
        _ emit_int32
        next
endcode

; ### emit-qword
code emit_qword, 'emit-qword'           ; raw-qword -> void
        _ pc
        _ store
        _lit tagged_fixnum(8)
        _ pc_plus_store
        next
endcode

; ### emit_raw_qword
code emit_raw_qword, 'emit_raw_qword'   ; raw-qword -> void
        _ new_uint64
        _ pc
        _ store
        _lit tagged_fixnum(8)
        _ pc_plus_store
        next
endcode

; : emit-dup
;     { 0x48 0x89 0x5d 0xf8 0x48 0x8d 0x6d 0xf8 } emit-bytes ;

; ### emit-dup
code emit_dup, 'emit-dup'               ; void -> void
        _ pc
        _untag_fixnum
        mov     rax, 0xf86d8d48f85d8948
        mov     [rbx], rax
        _drop
        _lit tagged_fixnum(8)
        _ pc_plus_store
        next
endcode

; : emit-drop
;     { 0x48 0x8b 0x5d 0x00 0x48 0x8d 0x6d 0x08 } emit-bytes ;

; ### emit-drop
code emit_drop, 'emit-drop'             ; void -> void
        _ pc
        _untag_fixnum
        mov     rax, 0x086d8d48005d8b48
        mov     [rbx], rax
        _drop
        _lit tagged_fixnum(8)
        _ pc_plus_store
        next
endcode

; ### emit-2drop
code emit_2drop, 'emit-2drop'           ; void -> void
        _ pc
        _untag_fixnum
        mov     rax, 0x106d8d48085d8b48
        mov     [rbx], rax
        _drop
        _lit tagged_fixnum(8)
        _ pc_plus_store
        next
endcode

; ### emit-nip
code emit_nip, 'emit-nip'               ; void -> void
        _ pc
        _untag_fixnum
        mov     eax, 0x086d8d48
        mov     [rbx], eax
        _drop
        _lit tagged_fixnum(4)
        _ pc_plus_store
        next
endcode

; ### compile-call-address
code compile_call_address, 'compile-call-address' ; address -> void
        ; calculate displacement
        _dup
        _ pc
        _lit tagged_fixnum(5)
        _ fast_fixnum_plus
        _ fast_fixnum_minus             ; address displacement

        ; does displacement fit in 32 bits?
        _ int32?
        cmp     rbx, NIL
        je      .1

        ; displacement fits in 32 bits
        ; -> address displacement
        _nip
        _emit_byte 0xe8
        _ emit_int32
        next

.1:
        ; displacement does not fit in 32 bits
        ; -> address nil
        _drop                           ; -> address

        ; does address fit in 32 bits?
        _dup
        _ int32?

        cmp     rbx, NIL
        _drop
        je      .2

        ; address fits in 32 bits
        _emit_byte 0xb8
        _ emit_int32                    ; mov eax, address
        _emit_byte 0xff
        _emit_byte 0xd0                 ; call rax
        next

.2:
        ; address does not fit in 32 bits
        _emit_byte 0x48
        _emit_byte 0xb8
        _ emit_qword
        _emit_byte 0xff
        _emit_byte 0xd0                 ; call rax
        next
endcode

; ### compile-call-symbol
code compile_call_symbol, 'compile-call-symbol' ; symbol -> void
        _ symbol_code_address
        _ compile_call_address
        next
endcode

; ### compile-literal
code compile_literal, 'compile-literal' ; literal -> void
        _dup
        _ wrapper?
        _tagged_if .1
        _ wrapped
        _then .1

        _ emit_dup
        _ object_to_integer
        _dup
        _ int32?
        _tagged_if .2
        _emit_byte 0xbb
        _ emit_int32
        _else .2
        _emit_byte 0x48
        _emit_byte 0xbb
        _ emit_qword
        _then .2
        next
endcode

; ### flush-pending
code flush_pending, 'flush-pending'     ; void -> void
        _ pending
        _ vector_length
        cmp     rbx, tagged_zero
        _drop
        jz      .exit
        _ pending
        _tick compile_literal_node
        _ vector_each
        _ pending
        _ vector_delete_all
.exit:
        next
endcode

feline_global forward_jumps, 'forward-jumps', NIL

; ### forward-jumps!
code set_forward_jumps, 'forward-jumps!'
        xchg    [S_forward_jumps_symbol_value], rbx
        _drop
        next
endcode

; ### add-forward-jump-address
code add_forward_jump_address, 'add-forward-jump-address' ; tagged-address -> void
        _ forward_jumps
        cmp     rbx, NIL
        je      .1
        _ vector_push
        next
.1:
        _drop
        _lit tagged_fixnum(8)
        _ make_vector
        _dup
        _ set_forward_jumps
        _ vector_push
        next
endcode

; ### inline-call-symbol
code inline_call_symbol, 'inline-call-symbol' ; symbol -> void
        _ symbol_code                   ; -> address size
        sub     rbx, (1 << FIXNUM_TAG_BITS) ; adjust size to exclude ret instruction
        _ pc                            ; -> address size pc
        _check_fixnum
        mov     arg1_register, rbx      ; arg1_register: pc (untagged)
        _drop                           ; -> address size
        mov     arg2_register, rbx      ; arg2_register: size
        mov     arg0_register, [rbp]    ; arg0_register: address
        sar     arg0_register, FIXNUM_TAG_BITS
        _ copy_bytes
        _nip                            ; -> size
        _ pc_plus_store
        next
endcode

; ### ?exit-no-locals
always_inline ?exit_no_locals, '?exit_no_locals'
        cmp     rbx, NIL
        _drop
        je      .1
        ret
.1:
endinline

; ### ?exit_locals
always_inline ?exit_locals, '?exit_locals'
        cmp     rbx, NIL
        _drop
        ; 2-byte jne
        db      0x0f
        db      0x85
?exit_locals_patch:
        ; These bytes will be patched.
        db      0
        db      0
        db      0
        db      0
endinline

; ### ?exit-locals-patch-offset
code ?exit_locals_patch_offset, '?exit-locals-patch-offset' ; void -> fixnum
        _dup
        mov     rbx, ?exit_locals_patch
        sub     rbx, ?exit_locals
        _tag_fixnum
        next
endcode

; ### compile-?exit-locals
code compile_?exit_locals, 'compile-?exit-locals' ;  node -> void

        _ flush_pending

        _pc
        add       rbx, ?exit_locals_patch - ?exit_locals
        _tag_fixnum
        _ add_forward_jump_address

        ; -> node
        _ node_operator
        _ inline_call_symbol            ; -> void

        next
endcode

; ### fix-call
code fix_call, 'fix-call'               ; call-address target-address -> void
; arguments are tagged fixnums

        ; [rbp]: address of call instruction (0xe8)
        ; rbx: address of call target

        _check_fixnum qword [rbp]       ; untag call address
        _check_fixnum                   ; untag target address
        _over                   ; -> call-address target-address call-address
        add     rbx, 5          ; rbx: untagged address of first byte of next instruction
        _minus                  ; -> call-address delta
        _swap                   ; -> delta call-address
        add     rbx, 1          ; skip over 0xe8

        _lstore

        next
endcode

; ### ?return_no_locals
always_inline ?return_no_locals, '?return_no_locals' ; ? quot ->
        cmp     qword [rbp], NIL
        je      .1
        _nip
..@?return_no_locals_patch:     ; use ..@ prefix to avoid interfering with local labels
        _ call_quotation
        ret
.1:
        _2drop
endinline

; ### compile-?return-no-locals
code compile_?return_no_locals, 'compile-?return-no-locals' ; node -> void

        _ flush_pending

        _pc
        add     rbx, ..@?return_no_locals_patch - ?return_no_locals
        _tag_fixnum                     ; -> node call-address

        _swap
        _ node_operator
        _ inline_call_symbol            ; -> call-address

        _tick call_quotation
        _ symbol_code_address           ; -> call-address target-address

        _ fix_call                      ; -> empty

        next
endcode

; ### ?return-locals
always_inline ?return_locals, '?return_locals' ; ? quot ->
        cmp     qword [rbp], NIL
        je      .1
        _nip
..@?return_locals_patch1:       ; use ..@ prefix to avoid interfering with local labels
        _ call_quotation
        db      0xe9            ; jmp
..@?return_locals_patch2:
        ; These bytes will be patched.
        db      0
        db      0
        db      0
        db      0
.1:
        _2drop
endinline

; ### compile-?return-locals
code compile_?return_locals, 'compile-?return-locals' ; node -> void

        _ flush_pending

        _pc
        add     rbx, ..@?return_locals_patch1 - ?return_locals
        _tag_fixnum                     ; address to patch for call

        _pc
        add     rbx, ..@?return_locals_patch2 - ?return_locals
        _tag_fixnum                     ; address to patch for jump to exit

        ; -> node patch1-address patch2-address
        _ add_forward_jump_address      ; -> node patch1-address

        _swap
        _ node_operator
        _ inline_call_symbol            ; -> patch1-address

        _tick call_quotation
        _ symbol_code_address           ; -> patch1-address call-target-address

        ; -> patch1-address call-target-address
        _ fix_call                      ; -> empty

        next
endcode

; ### symbol-set-compiler
code symbol_set_compiler, 'symbol-set-compiler' ; compiler symbol -> void
        _quote "compiler"
        _swap
        _ symbol_set_prop
        next
endcode

; ### initialize_compiler
code initialize_compiler, 'initialize_compiler'
        _ initialize_compiler_lock

        _tick compile_?exit_locals
        _tick ?exit_locals
        _ symbol_set_compiler

        _tick compile_?return_no_locals
        _tick ?return_no_locals
        _ symbol_set_compiler

        _tick compile_?return_locals
        _tick ?return_locals
        _ symbol_set_compiler

        _lit tagged_fixnum(16)
        _ make_vector
        _tick context_stack
        _ symbol_set_value

        next
endcode

; ### inline-or-compile-call
code inline_or_compile_call, 'inline-or-compile-call' ; symbol -> void
        _dup
%ifdef DEBUG
        _ symbol_always_inline?
%else
        _ symbol_inline?
%endif
        _tagged_if .1
        _ inline_call_symbol
        _else .1
        _ compile_call_symbol
        _then .1
        next
endcode

; ### primitive-compile-generic
code primitive_compile_generic, 'primitive_compile_generic' ; symbol -> void
        _ flush_pending
        _ compile_call_symbol
        next
endcode

deferred compile_generic, 'compile-generic', primitive_compile_generic

; ### compile-operator-node
code compile_operator_node, 'compile-operator-node' ; node -> void
        _quote "compiler"               ; -> node "compiler"
        _over                           ; -> node "compiler" node
        _ node_operator                 ; -> node "compiler" symbol
        _ symbol_prop                   ; -> node compiler/nil
        _ symbol?                       ; -> node compiler/nil
        cmp     rbx, NIL
        je      .1

        ; -> node compiler
        _ call_symbol
        next

.1:
        ; -> node nil
        _drop                           ; -> node
        _ node_operator                 ; -> symbol
        _dup
        _ generic?                      ; -> symbol ?
        cmp     rbx, NIL
        _drop                           ; -> symbol
        je      .2

        ; -> symbol
        _ compile_generic
        next

.2:
        ; -> symbol
        _ flush_pending
        _ inline_or_compile_call
        next
endcode

; ### compile-literal-node
code compile_literal_node, 'compile-literal-node' ; node -> void
        _ node_literal_value
        _ compile_literal
        next
endcode

; ### compile-node
code compile_node, 'compile-node'       ; node -> void
        _dup
        _ node_operator
        _tagged_if .1
        _ compile_operator_node
        _else .1
        ; literal node
        _ pending
        _ vector_push
        _then .1
        next
endcode

; ### compile-prolog
code compile_prolog, 'compile-prolog'

        _ locals_count                  ; -> fixnum
        test    bl, FIXNUM_TAG
        jz      error_not_fixnum
        sar     rbx, FIXNUM_TAG_BITS    ; rbx: raw locals count
        jz      drop                    ; nothing to do if locals count is 0

        ; we have locals
        _emit_byte 0x41
        _emit_byte 0x56                 ; push r14

        ; rbx: raw locals count
        shl     rbx, 3                  ; rbx: raw number of bytes

        cmp     rbx, 128
        jge     .1

        ; number of bytes < 128
        _emit_byte 0x48
        _emit_byte 0x83
        _emit_byte 0xec
        _tag_fixnum
        _ emit_byte                     ; sub rsp, number of bytes
        jmp     .2

.1:
        ; number of bytes >= 128
        _emit_byte 0x48
        _emit_byte 0x81
        _emit_byte 0xec
        _ emit_raw_dword                ; sub rsp, number of bytes

.2:
        _emit_byte 0x49
        _emit_byte 0x89
        _emit_byte 0xe6                 ; mov r14, rsp

        ; -> empty
        next
endcode

asm_global exit_address_, 0

; ### exit-address
code exit_address, 'exit-address'       ; void -> fixnum
        _dup
        mov     rbx, [exit_address_]
        _tag_fixnum
        next
endcode

; ### patch-forward-jump
code patch_forward_jump, 'patch-forward-jump' ; tagged-address -> void
        _ exit_address          ; -> tagged-address tagged-exit-address
        _check_fixnum           ; -> tagged-address untagged-exit-address
        _over                   ; -> tagged-address untagged-exit-address tagged-address
        _check_fixnum           ; -> tagged-address untagged-exit-address untagged-address
        add     rbx, 4          ; address of next instruction's first byte in rbx
        _minus                  ; -> tagged-address delta
        _tag_fixnum
        _swap
        _ lstore
        next
endcode

; ### patch-forward-jumps
code patch_forward_jumps, 'patch-forward-jumps' ; void -> void

        _ forward_jumps

        cmp     rbx, NIL
        je      drop

        _tick patch_forward_jump
        _ vector_each

        _nil
        _ set_forward_jumps

        next
endcode

; ### compile-epilog
code compile_epilog, 'compile-epilog'

        _ pc
        _untag_fixnum
        mov     rax, rbx
        _drop
        mov     [exit_address_], rax

        _ locals_count                  ; -> fixnum
        test    bl, FIXNUM_TAG
        jz      error_not_fixnum
        sar     rbx, FIXNUM_TAG_BITS    ; rbx: raw locals count
        jz      drop                    ; nothing to do if locals-count is 0

        ; we have locals
        ; rbx: raw locals count
        shl     rbx, 3                  ; rbx: raw number of bytes

        cmp     rbx, 128
        jge     .1

        ; number of bytes < 128
        _emit_byte 0x48
        _emit_byte 0x83
        _emit_byte 0xc4
        _tag_fixnum
        _ emit_byte
        jmp     .2

.1:
        ; number of bytes >= 128
        _emit_byte 0x48
        _emit_byte 0x81
        _emit_byte 0xc4
        _ emit_raw_dword                ; add rsp, number of bytes

.2:
        ; -> empty
        _emit_byte 0x41
        _emit_byte 0x5e                 ; pop r14

        next
endcode

; ### primitive-compile-quotation
code primitive_compile_quotation, 'primitive-compile-quotation' ; quotation -> void

        _ lock_compiler

        _ new_context

        _debug_?enough 1

        _ check_quotation               ; -> ^quotation

        push    this_register
        mov     this_register, rbx      ; ^quotation in this_register
        _drop                           ; -> empty

        _this_quotation_array
        _tick precompile_object
        _ map_array                     ; -> precompiled-array

        _zero
        _over
        _tick add_code_size
        _ array_each

        ; add size of return instruction
        _oneplus                        ; -> raw-size
        _tag_fixnum

        _ initialize_code_block         ; -> tagged-address
        _dup
        _ set_origin
        _ set_pc                        ; -> void

        ; prolog
        _ compile_prolog

        ; body
        _tick compile_node
        _ each

        _ flush_pending

        ; epilog
        _ compile_epilog

        _emit_byte 0xc3

        _ patch_forward_jumps

        _ origin
        _check_fixnum
        _this_quotation_set_raw_code_address

        _ pc
        _ origin
        _ fast_fixnum_minus
        _check_fixnum
        _this_quotation_set_raw_code_size

        _ origin
        _ last_allocation
        _eq?
        _tagged_if .2
        _ pc
        _untag_fixnum
        add     rbx, 0x0f
        and     bl, 0xf0
        _tag_fixnum
        _ set_code_space_free
        _then .2

        pop     this_register

        _ restore_context

        _ unlock_compiler

        next
endcode

; ### compile-quotation
code compile_quotation, 'compile-quotation' ; quotation -> quotation
        _duptor
        _ primitive_compile_quotation
        _rfrom
        next
endcode

%define USE_WORKLIST

%ifdef USE_WORKLIST

feline_global worklist, 'worklist'

; ### worklist!
code set_worklist, 'worklist!'          ; x -> void
        xchg    [S_worklist_symbol_value], rbx
        _drop
        next
endcode

; ### add-quotation
code add_quotation, 'add-quotation'     ; quotation -> void
        _ ?enough_1
        _ verify_quotation

        _ worklist
        _ verify_vector
        _ push
        next
endcode

; ### add-children
code add_children, 'add-children'       ; quotation-or-array -> void
        _ ?enough_1

        _tick maybe_add_quotation_and_children
        _ each
        next
endcode

; ### add-quotation-and-children
code add_quotation_and_children, 'add-quotation-and-children' ; quotation -> void
        _ ?enough_1
        _ verify_quotation

        _ dup
        _ add_quotation
        _ add_children
        next
endcode

; ### maybe-add-quotation-and-children
code maybe_add_quotation_and_children, 'maybe-add-quotation-and-children' ; x -> void
        _ ?enough_1

        _dup
        _ quotation?                    ; -> x x/nil
        cmp     rbx, NIL
        _drop                           ; -> x
        jnz     add_quotation_and_children

        ; not a quotation
        ; -> x
        _ array?
        cmp     rbx, NIL
        jz      drop
        _ add_children
        next
endcode

; ### build-worklist
code build_worklist, 'build-worklist'   ; word -> void
        _ ?enough_1

        _lit tagged_fixnum(32)
        _ make_vector
        _ set_worklist

        ; -> word
        _ symbol_def
        _ verify_quotation
        _ add_quotation_and_children
        next
endcode

; ### process-worklist
code process_worklist, 'process-worklist' ; void -> void
        _ worklist
        _ vector_reverse_in_place       ; -> vector
        _drop
        _ worklist
        _ vector_pop_star
        _lit tagged_zero
        _ set_locals_count
        _ worklist
        _tick primitive_compile_quotation
        _ each
        next
endcode

%endif

; ### primitive-compile-word
code primitive_compile_word, 'primitive-compile-word' ; word -> void

%ifdef USE_WORKLIST
        _dup
        _ build_worklist
        _ process_worklist
%endif

        _dup
        _ symbol_get_locals_count
        _check_fixnum
        mov     [locals_count_], rbx
        _drop

        _nil
        _ set_forward_jumps

        _dup
        _ symbol_def
        _ compile_quotation             ; -> symbol quotation

        _dup
        _ quotation_code_address
        _pick
        _ symbol_set_code_address

        _ quotation_code_size
        _swap
        _ symbol_set_code_size

        _ forget_locals

        next
endcode

deferred compile_word, 'compile-word', primitive_compile_word

; ### compile-deferred
code compile_deferred, 'compile-deferred' ; symbol -> void

        _ new_context

        _lit tagged_fixnum(16)
        _ initialize_code_block         ; -> symbol address

        _dup
        _ set_pc

        ; -> symbol address
        ; REVIEW set current context origin slot
        _over
        _ symbol_set_code_address       ; -> symbol

        ; movabs rax, qword [moffset64]
        _emit_byte 0x48
        _emit_byte 0xa1

        _dup
        _ check_symbol
        add     rbx, SYMBOL_VALUE_OFFSET
        _ emit_raw_qword

        ; jmp rax
        _emit_byte 0xff
        _emit_byte 0xe0

        _lit tagged_fixnum(12)
        _swap
        _ symbol_set_code_size

        _ restore_context

        next
endcode
