; Copyright (C) 2012-2018 Peter Graves <gnooth@gmail.com>

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
%include "loop-macros.asm"
%include "inlines.asm"

section .data
static_data_area:

string FELINE_VOCAB_NAME, 'feline'

%include "io.asm"
%include "stack.asm"
%include "strings.asm"

%include "cold.asm"
%include "move.asm"
%include "memory.asm"
%include "debug.asm"
%include "key.asm"
%include "vocabs.asm"
%include "boolean.asm"
%include "object-macros.asm"
%include "type.asm"
%include "vector.asm"
%include "handles.asm"
%include "locals.asm"
%include "hashtable.asm"
%include "generic.asm"
%include "method.asm"
%include "fixnum.asm"
%include "uint64.asm"
%include "int64.asm"
%include "bitops.asm"
%include "float.asm"
%include "numbers.asm"
%include "math.asm"
%include "objects.asm"
%include "array.asm"
%include "string.asm"
%include "sbuf.asm"
%include "slice.asm"
%include "range.asm"
%include "sequences.asm"
%include "symbol.asm"
%include "keyword.asm"
%include "vocab.asm"
%include "wrapper.asm"
%include "quotation.asm"
%include "curry.asm"
%include "slot-definition.asm"
%include "tuple.asm"
%include "dynamic-scope.asm"
%include "combinators.asm"
%include "quit.asm"
%include "lexer.asm"
%include "iterator.asm"
%include "string-iterator.asm"
%include "primitives.asm"
%include "format.asm"
%include "time.asm"
%include "thread.asm"
%include "gc.asm"
%include "syntax.asm"
%include "assert.asm"
%include "compile-word.asm"
%include "recover.asm"
%include "file-output-stream.asm"
%include "files.asm"
%include "load.asm"
%include "errors.asm"
%include "tools.asm"
%include "ansi.asm"
%include "color.asm"
%include "socket.asm"
%include "mutex.asm"
%include "defer.asm"

; ### in-static-data-area?
code in_static_data_area?, 'in-static-data-area?', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; addr -- ?
        cmp     rbx, static_data_area
        jb .1
        cmp     rbx, static_data_area_limit
        jae .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

code last_static_symbol, 'last-static-symbol', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
        pushrbx
        mov     rbx, symbol_link
        next
endcode

section .data
static_data_area_limit:
