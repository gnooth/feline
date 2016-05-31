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
        _swap                           ; -- quot seq
        push    this_register
        popd    this_register           ; -- quot
        push    r12
        popd    r12                     ; --
        mov     r12, [r12]              ; call address in r12

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
