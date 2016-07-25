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

; ### shorter?
code shorter?, 'shorter?'               ; seq1 seq2 -- ?
; Factor
        _lit length_xt
        _ bi_at
        _ fixnum_lt
        next
endcode

; ### min-length
code min_length, 'min-length'           ; seq1 seq2 -- n
        _lit length_xt
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
code mismatch, 'mismatch'               ; seq1 seq2 -- i|f
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
code map, 'map'                         ; seq quot -- newseq
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
        _this
        _ nth_unsafe                    ; -- newseq elt

        call    r12                     ; -- newseq newelt

        _i
        _tag_fixnum                     ; -- newseq newelt i
        _ feline_pick                   ; -- newseq newelt i newseq
        _ set_nth                       ; -- newseq

        _loop .1

        pop     r12
        pop     this_register

        next
endcode

; ### filter
code filter, 'filter'                   ; seq quot -- subseq
;         _swap                           ; -- quot seq
        _over
        push    this_register
        popd    this_register           ; -- quot
        push    r12
        popd    r12                     ; --
        mov     r12, [r12]              ; call address in r12

        _this
        _ length
        _untag_fixnum
        _dup
        _ new_vector_untagged           ; -- untagged-length vector
        _swap
        _zero
        _?do .1

        _i
        _tag_fixnum
        _this
        _ nth_unsafe                    ; -- vector elt
        _dup
        call    r12                     ; -- vector elt t|f

        _tagged_if .2
        _over                           ; -- vector elt vector
        _ vector_push                   ; -- vector
        _else .2
        _drop                           ; -- vector
        _then .2

        _loop .1

        pop     r12
        pop     this_register           ; -- seq vector

        ; FIXME use new-sequence (support all sequence types)
        _swap
        _ array?
        _if .3
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
code sequence_equal, 'sequence='        ; seq1 seq2 -- t|f
        _twodup
        _lit length_xt
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
        next
endcode

; ### find
code feline_find, 'find'                ; seq xt -- i elt | f f
        push    r12
        mov     r12, [rbx]              ; address to call in r12
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
