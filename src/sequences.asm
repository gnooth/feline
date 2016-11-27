; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

; ### in-bounds?
code in_bounds?, 'in-bounds?'           ; n seq -- ?
; Factor bounds-check?
        _over
        _ index?
        _tagged_if_not .1
        _drop
        mov     ebx, f_value
        _return
        _then .1

        ; -- n seq
        _ length
        _ fixnum_lt
        next
endcode

; ### check-bounds
code check_bounds, 'check-bounds'       ; n seq -- n seq
; Factor bounds-check
        _twodup
        _ in_bounds?
        _tagged_if_not .1
        _error "index out of bounds for sequence"
        _then .1
        next
endcode

; ### shorter?
code shorter?, 'shorter?'               ; seq1 seq2 -- ?
; Factor
        _lit S_length
        _ bi_at
        _ fixnum_lt
        next
endcode

; ### longer?
code longer?, 'longer?'                 ; seq1 seq2 -- ?
; Factor
        _lit S_length
        _ bi_at
        _ fixnum_gt
        next
endcode

; ### min-length
code min_length, 'min-length'           ; seq1 seq2 -- n
        _lit S_length
        _ bi_at
        _ min
        next
endcode

; ### 2nth-unsafe
code two_nth_unsafe, '2nth-unsafe'      ; n seq1 seq2 -- elt1 elt2
        _tor                            ; -- n seq1     r: -- seq2
        _dupd                           ; -- n n seq1   r: -- seq2
        _ nth_unsafe                    ; -- n elt1     r: -- seq2
        _swap                           ; -- elt1 n     r: -- seq2
        _rfrom                          ; -- elt1 n seq2
        _ nth                           ; -- elt2 elt2
        next
endcode

; ### mismatch
code mismatch, 'mismatch'               ; seq1 seq2 -- index/f
        _twodup
        _ min_length
        _untag_fixnum
        _zero
        _?do .1
        _i
        _tag_fixnum
        _ feline_2over
        _ two_nth_unsafe
        _notequal
        _if .2
        _2drop
        _i
        _tag_fixnum
        _unloop
        _return
        _then .2
        _loop .1
        _2drop
        _f
        next
endcode

; ### head?
code head?, 'head?'                     ; seq begin -- ?
        _twodup
        _ shorter?
        _quotation .1
        _2drop
        _f
        _end_quotation .1
        _quotation .2
        _ mismatch
        _ not
        _end_quotation .2
        _ feline_if
        next
endcode

; ### map
code map, 'map' ; seq callable -- new-seq

        ; protect callable from gc
        push    rbx

        _ callable_code_address

        _swap                           ; -- code-address seq

        push    this_register
        popd    this_register           ; -- code-address
        push    r12
        popd    r12                     ; code address in r12
        _this
        _ length                        ; -- len
        _this                           ; -- len seq
        _ new_sequence                  ; -- new-seq

        _this
        _ length
        _untag_fixnum
        _zero
        _?do .1

        _i
        _tag_fixnum
        _this
        _ nth_unsafe                    ; -- new-seq element

        call    r12                     ; -- new-seq new-element

        _i
        _tag_fixnum                     ; -- new-seq new-element i
        _pick                           ; -- new-seq new-element i new-seq
        _ set_nth                       ; -- new-seq

        _loop .1

        pop     r12
        pop     this_register

        ; drop callable
        pop     rax

        next
endcode

; ### map-index
code map_index, 'map-index'             ; seq quot -- newseq
        _ callable_code_address
        _swap                           ; -- code-address seq
        push    this_register
        popd    this_register           ; -- code-address
        push    r12
        popd    r12                     ; code address in r12
        _this
        _ length                        ; -- len
        _this                           ; -- len seq
        _ new_sequence                  ; -- newseq

        _this
        _ length
        _untag_fixnum
        _zero
        _?do .1

        _i
        _tag_fixnum
        _dup
        _this
        _ nth_unsafe                    ; -- newseq tagged-index elt

        _swap                           ; -- newseq elt tagged-index

        call    r12                     ; -- newseq newelt

        _i
        _tag_fixnum                     ; -- newseq newelt i
        _pick                           ; -- newseq newelt i newseq
        _ set_nth                       ; -- newseq

        _loop .1

        pop     r12
        pop     this_register

        next
endcode

; ### filter
code filter, 'filter'                   ; seq quot -- subseq
        _ callable_code_address         ; -- seq code-address
        _over                           ; -- seq code-address seq
        push    this_register
        popd    this_register           ; -- seq code-address
        push    r12
        popd    r12                     ; -- seq

        ; address to call is in r12

        _this
        _ length
        _untag_fixnum
        _dup
        _ new_vector_untagged           ; -- seq untagged-length vector
        _swap
        _zero
        _?do .1

        _i
        _tag_fixnum
        _this
        _ nth_unsafe                    ; -- seq vector elt
        _dup
        call    r12                     ; -- seq vector elt ?

        _tagged_if .2
        _over                           ; -- seq vector elt vector
        _ vector_push                   ; -- seq vector
        _else .2
        _drop                           ; -- seq vector
        _then .2

        _loop .1

        pop     r12
        pop     this_register           ; -- seq vector

        ; FIXME use new-sequence (support all sequence types)
        _swap
        _ array?
        _tagged_if .3
        _ vector_to_array
        _then .3

        next
endcode

; ### 2nth
code two_nth, '2nth'                    ; n seq1 seq2 -- elt1 elt2
; Numeric argument is tagged.
        _tor                            ; -- n seq1             r: -- seq2
        _dupd                           ; -- n n seq1
        _ nth                           ; -- n elt1
        _swap                           ; -- elt1 n
        _rfrom                          ; -- elt1 n seq2
        _ nth
        next
endcode

; ### sequence=
code sequence_equal, 'sequence='        ; seq1 seq2 -- ?
        _twodup
        _lit S_length
        _ bi_at                         ; -- seq1 seq2 len1 len2
        _equal
        _zeq_if .1
        _2drop
        _f
        _return
        _then .1                        ; -- seq1 seq2
        ; lengths match
        _dup
        _ length                        ; -- seq1 seq2 len
        _untag_fixnum
        _zero
        _?do .2
        _twodup                         ; -- seq1 seq2 seq1 seq2
        _i
        _tag_fixnum
        _ rrot
        _ two_nth                       ; -- seq1 seq2 elt1 elt2
        _ feline_equal
        _tagged_if_not .3
        _2drop
        _unloop
        _f
        _return
        _then .3
        _loop .2
        ; no mismatch
        _2drop
        _t
        next
endcode

; ### each
code each, 'each'                       ; seq quotation-or-xt --

        ; protect quotation from gc
        push    rbx

        _ callable_code_address         ; -- seq code-address

        push    r12
        mov     r12, rbx                ; code address in r12
        poprbx                          ; -- seq
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register
        _ length
        _untag_fixnum
        _zero
        _?do .1
        _i
        _tag_fixnum
        _this                           ; -- tagged-index handle
        _ nth_unsafe                    ; -- element
        call    r12
        _loop .1
        pop     this_register
        pop     r12

        ; drop quotation
        pop     rax

        next
endcode

; ### each-index
code each_index, 'each-index'           ; seq quotation-or-xt --

        ; protect quotation from gc
        push    rbx

        _ callable_code_address         ; -- seq code-address

        push    r12
        mov     r12, rbx                ; code address in r12
        poprbx                          ; -- seq
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register
        _ length
        _untag_fixnum
        _zero
        _?do .1
        _i
        _tag_fixnum
        _dup
        _this                           ; -- index index handle
        _ nth_unsafe                    ; -- index element
        _swap                           ; -- element index
        call    r12
        _loop .1
        pop     this_register
        pop     r12

        ; drop quotation
        pop     rax

        next
endcode

; ### find
code feline_find, 'find'                ; seq quot -- index/f elt/f
        _ callable_code_address         ; -- seq code-address
        push    r12
        mov     r12, rbx                ; address to call in r12
        poprbx                          ; -- seq
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register
        _ length
        _untag_fixnum
        _zero
        _?do .1
        _i
        _tag_fixnum
        _this                           ; -- tagged-index handle
        _ nth_unsafe                    ; -- element
        call    r12                     ; -- ?
        _tagged_if .2
        ; we're done
        _i
        _tag_fixnum
        _dup
        _this
        _ nth_unsafe
        _unloop
        jmp     .exit
        _then .2
        _loop .1
        ; not found
        _f
        _dup
.exit:
        pop     this_register
        pop     r12
        next
endcode

; ### find-from
code find_from, 'find-from'             ; n seq quot -- index/f elt/f
        _ feline_2over
        _ in_bounds?
        _tagged_if_not .1
        _3drop
        _f
        _f
        _return
        _then .1

        _ callable_code_address         ; -- n seq code-address
        push    r12
        mov     r12, rbx                ; address to call in r12
        poprbx                          ; -- n seq
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register

        _ length                        ; -- n length
        _untag_fixnum
        _swap
        _untag_fixnum                   ; -- untagged-length untagged-n
        _?do .2
        _i
        _tag_fixnum
        _this                           ; -- tagged-index handle
        _ nth_unsafe                    ; -- element
        call    r12                     ; -- ?
        _tagged_if .3
        ; we're done
        _i
        _tag_fixnum
        _dup
        _this
        _ nth_unsafe
        _unloop
        jmp     .exit
        _then .3
        _loop .2
        ; not found
        _f
        _dup
.exit:
        pop     this_register
        pop     r12
        next
endcode

; ### find-last-from
code find_last_from, 'find-last-from'   ; n seq quot -- index/f elt/f
        _ feline_2over
        _ in_bounds?
        _tagged_if_not .1
        _3drop
        _f
        _f
        _return
        _then .1

        _ callable_code_address         ; -- n seq code-address
        push    r12
        mov     r12, rbx                ; address to call in r12
        poprbx                          ; -- n seq

        push    this_register
        popd    this_register           ; handle to seq in this_register

        ; -- n
        _untag_fixnum

        push    r13
        mov     r13, rbx
        inc     rbx

        _zero
        _?do .2
        pushd   r13

        _i
        _minus
        _tag_fixnum
        _this                           ; -- tagged-index handle

        _ nth_unsafe                    ; -- element
        call    r12                     ; -- ?
        _tagged_if .3

        ; we're done
        pushd   r13
        _i
        _minus
        _tag_fixnum
        _dup
        _this
        _ nth_unsafe
        _unloop
        jmp     .exit

        _then .3
        _loop .2

        ; not found
        _f
        _dup
.exit:
        pop     r13
        pop     this_register
        pop     r12
        next
endcode

; ### map-find
code map_find, 'map-find'               ; seq quot -- result elt
        _ callable_code_address         ; -- seq code-address
        push    r12
        mov     r12, rbx                ; address to call in r12
        poprbx                          ; -- seq
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register
        _ length
        _untag_fixnum
        _zero
        _?do .1
        _i
        _tag_fixnum
        _this                           ; -- tagged-index handle
        _ nth_unsafe                    ; -- element
        call    r12                     ; -- result/f
        _dup
        _tagged_if .2
        ; we're done
        _i
        _tag_fixnum
        _this
        _ nth_unsafe                    ; -- result elt
        _unloop
        jmp     .exit
        _else .2
        _drop
        _then .2
        _loop .1
        ; not found
        _f
        _dup
.exit:
        pop     this_register
        pop     r12
        next
endcode

; ### first
code first, 'first'                     ; seq -- first
        _lit tagged_zero
        _swap
        _ nth
        next
endcode

; ### second
code second, 'second'                   ; seq -- second
        _tagged_fixnum(1)
        _swap
        _ nth
        next
endcode

; ### third
code third, 'third'                     ; seq -- third
        _tagged_fixnum(2)
        _swap
        _ nth
        next
endcode

; ### index
code index, 'index'                     ; obj seq -- n/f
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register
        _ length
        _untag_fixnum
        _zero
        _?do .1
        _i
        _tag_fixnum
        _this
        _ nth_unsafe
        _over
        _ feline_equal
        _tagged_if .2
        _drop
        _i
        _tag_fixnum
        _unloop
        jmp     .exit
        _then .2
        _loop .1
        _drop
        _f
.exit:
        pop     this_register
        next
endcode

; ### member?
code member?, 'member?'                 ; obj seq -- ?
        _ index
        mov     eax, t_value
        cmp     rbx, f_value
        cmovne  ebx, eax
        next
endcode
