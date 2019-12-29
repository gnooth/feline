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

; http://www.intel.com/content/www/us/en/embedded/training/ia-32-ia-64-benchmark-code-execution-paper.html

; ### rdtsc
inline read_time_stamp_counter, 'rdtsc' ; -- u
        ; serialize
        xor     eax, eax
        cpuid

        _rdtsc
endinline

; ### ticks
code ticks, 'ticks'                     ; -- u
        xcall   os_ticks
        pushd   rax
        next
endcode

; ### raw_nano_count
code raw_nano_count, 'raw_nano_count', SYMBOL_INTERNAL  ; -- raw-uint64
        xcall   os_nano_count
        _dup
        mov     rbx, rax
        next
endcode

; ### nano-count
code nano_count, 'nano-count'           ; -- ns
        xcall   os_nano_count
        _dup
        mov     rbx, rax
        _ normalize
        next
endcode

; ### elapsed
code elapsed, 'elapsed'                 ; callable -- ns cycles

        ; protect quotation from gc
        push    rbx

        _ callable_raw_code_address

        push    r12
        mov     r12, rbx
        poprbx

        _ raw_nano_count
        _tor
        _rdtsc
        _tor

        call    r12

        _rdtsc
        _ raw_nano_count

        _swap
        _rfrom
        _minus
        _tag_fixnum
        _swap
        _rfrom
        _minus
        _tag_fixnum
        _swap                           ; -- ns cycles

        pop     r12

        ; drop quotation
        pop     rax

        next
endcode

; ### time
code feline_time, 'time'                ; callable -> void

        _ elapsed                       ; -> ns cycles

        _swap                           ; -> cycles ns

        _ ?nl

        _ fixnum_to_float
        _lit tagged_fixnum(1000000)
        _ fixnum_to_float
        _ float_float_divide
        _ float_to_string
        _ write_string
        _quote " ms ("
        _ write_string                  ; -> cycles

        _ fixnum_to_string
        _ write_string
        _quote " cycles)"
        _ write_string
        _ nl

        next
endcode
