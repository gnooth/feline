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
%include "locals.asm"
%include "loop.asm"
%include "memory.asm"
%include "move.asm"
%include "number.asm"
%include "objects.asm"
%include "opt.asm"
%include "parse.asm"
%include "quit.asm"
%include "stack.asm"
%include "store.asm"
%include "strings.asm"
%include "transient-strings.asm"
%include "tools.asm"
%include "value.asm"

file __FILE__

; ### last
; the last word
variable last, 'last', last_nfa
