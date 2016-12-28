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
%include "externs.asm"
%include "macros.asm"
%include "inlines.asm"

IN_FORTH

section .data
static_data_area:

string FELINE_VOCAB_NAME, 'feline'

%include "arith.asm"
%include "include.asm"
%include "io.asm"
%include "memory.asm"
%include "move.asm"
%include "stack.asm"
%include "store.asm"
%include "strings.asm"

IN_FELINE

%include "cold.asm"
%include "debug.asm"
%include "key.asm"
%include "vocabs.asm"
%include "object-macros.asm"
%include "handles.asm"
%include "primitives.asm"
%include "hashtable.asm"
%include "generic.asm"
%include "fixnum.asm"
%include "bignum.asm"
%include "objects.asm"
%include "array.asm"
%include "vector.asm"
%include "string.asm"
%include "sbuf.asm"
%include "slice.asm"
%include "range.asm"
%include "sequences.asm"
%include "symbol.asm"
%include "vocab.asm"
%include "wrapper.asm"
%include "quotation.asm"
%include "curry.asm"
%include "tuple.asm"
%include "globals.asm"
%include "combinators.asm"
%include "quit.asm"
%include "lexer.asm"
%include "time.asm"
%include "gc.asm"
%include "parsing-words.asm"
%include "assert.asm"
%include "compile-word.asm"
%include "recover.asm"
%include "files.asm"
%include "load.asm"
%include "tools.asm"
%include "locals.asm"
%include "ansi.asm"

subroutine in_static_data_area?         ; addr -- 1/0
        cmp     rbx, static_data_area
        jb .1
        cmp     rbx, static_data_area_limit
        jae .1
        mov     ebx, 1
        _return
.1:
        xor     ebx, ebx
        next
endsub

subroutine last_static_symbol
        pushrbx
        mov     rbx, symbol_link
        ret
endsub

section .data
static_data_area_limit:
