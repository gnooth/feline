\ Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

\ This program is free software: you can redistribute it and/or modify
\ it under the terms of the GNU General Public License as published by
\ the Free Software Foundation, either version 3 of the License, or
\ (at your option) any later version.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
\ GNU General Public License for more details.

\ You should have received a copy of the GNU General Public License
\ along with this program.  If not, see <http://www.gnu.org/licenses/>.

forth!

[undefined] x86-64 [if] vocabulary x86-64 [then]

x86-64 definitions

decimal

\ "0 = default operand size   1 = 64-bit operand size"
8 constant rex.w

\ "1-bit (high) extension of the ModRM reg field, thus permitting access to 16 registers."
4 constant rex.r

\ "1-bit (high) extension of the SIB index field, thus permitting access to 16 registers."
2 constant rex.x

\ "1-bit (high) extension of the ModRM r/m field, SIB base field, or opcode reg field,
\ thus permitting access to 16 registers."
1 constant rex.b
