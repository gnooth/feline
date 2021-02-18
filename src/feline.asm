; Copyright (C) 2012-2021 Peter Graves <gnooth@gmail.com>

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
%include "externs.asm"
%include "macros.asm"
%include "loop-macros.asm"
%include "inlines.asm"

section .data
static_data_area:

%include "io.asm"
%include "stack.asm"

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
%include "byte-vector.asm"
%include "handles.asm"
%include "lvar.asm"
%include "locals.asm"
%include "hashtable-common.asm"
%include "hashtable.asm"
%include "fixnum-hashtable.asm"
%include "equal-hashtable.asm"
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
%include "bit-array.asm"
%include "string.asm"
%include "string-slice.asm"
%include "sbuf.asm"
%include "slice.asm"
%include "range.asm"
%include "sequences.asm"
%include "symbol.asm"
%include "keyword.asm"
%include "vocab.asm"
%include "wrapper.asm"
%include "quotation.asm"
%include "slot.asm"
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
%include "file-output-stream.asm"
%include "string-output-stream.asm"
%include "stream.asm"
%include "gc2.asm"
%include "syntax.asm"
%include "assert.asm"
%include "xalloc.asm"
%include "compile-word.asm"
%include "recover.asm"
%include "files.asm"
%include "load.asm"
%include "errors.asm"
%include "tools.asm"
%include "ansi.asm"
%include "color.asm"
%include "socket.asm"
%include "mutex.asm"
%include "defer.asm"

%ifdef WIN64 ; Windows

feline_constant have_gtkui?, 'have-gtkui?', NIL

%ifdef WINUI
%include "winui.asm"
feline_constant have_winui?, 'have-winui?', TRUE
%else
feline_constant have_winui?, 'have-winui?', NIL
%endif

%endif ; Windows

%ifndef WIN64 ; Linux

feline_constant have_winui?, 'have-winui?', NIL

%ifdef GTKUI
%include "gtkui.asm"
feline_constant have_gtkui?, 'have-gtkui?', TRUE
%else
feline_constant have_gtkui?, 'have-gtkui?', NIL
%endif

%endif ; Linux

; ### in-static-data-area?
code in_static_data_area?, 'in-static-data-area?', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; addr -- ?
        cmp     rbx, static_data_area
        jb .1
        cmp     rbx, static_data_area_limit
        jae .1
        mov     ebx, TRUE
        next
.1:
        mov     ebx, NIL
        next
endcode

code last_static_symbol, 'last-static-symbol', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
        _dup
        mov     rbx, symbol_link
        next
endcode

section .data
static_data_area_limit:
