; Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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

default abs ; use absolute addresses by default

%include "feline_home.asm"
%include "version.asm"
%include "equates.asm"
%include "macros.asm"
%include "inlines.asm"

IN_FORTH

section .data
static_data_area:

%include "align.asm"
%include "ansi.asm"
%include "arith.asm"
%include "branch.asm"
%include "bye.asm"
%include "cold.asm"
%include "compiler.asm"
%include "constants.asm"
%include "dictionary.asm"
%include "dot.asm"
%include "double.asm"
%include "exceptions.asm"
%include "execute.asm"
%include "fetch.asm"
%include "find.asm"
%include "include.asm"
%include "interpret.asm"
%include "io.asm"
%include "language.asm"
%include "locals.asm"
%include "loop.asm"
%include "memory.asm"
%include "move.asm"
%include "number.asm"
%include "opt.asm"
%include "parse.asm"
%include "quit.asm"
%include "stack.asm"
%include "store.asm"
%include "strings.asm"
%include "time.asm"
%include "tools.asm"
%include "transient-alloc.asm"
%include "value.asm"
%include "vocabs.asm"

IN_FELINE

; Objects
%include "object-macros.asm"
%include "primitives.asm"
%include "hashtable.asm"
%include "generic.asm"
%include "fixnum.asm"
%include "bignum.asm"
%include "handles.asm"
%include "objects.asm"
%include "array.asm"
%include "vector.asm"
%include "string.asm"
%include "sbuf.asm"
%include "sequences.asm"
%include "gc.asm"
%include "global.asm"

IN_FORTH

file __FILE__

; ### standard-forth?
code standard_forth?, 'standard-forth?' ; -- -1|0
%ifdef STANDARD_FORTH
        _true
%else
        _false
%endif
        next
endcode

; ### in-static-data-area?
code in_static_data_area?, 'in-static-data-area?' ; addr -- flag
        cmp     rbx, static_data_area
        jb .1
        cmp     rbx, static_data_area_limit
        jae .1
        mov     ebx, 1
        _return
.1:
        xor     ebx, ebx
        next
endcode

; ### feline-last
variable feline_last, 'feline-last', feline_link

; ### last
; the last word
variable last, 'last', last_nfa

section .data
static_data_area_limit:
