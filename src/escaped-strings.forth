\ Copyright (C) 2015-2016 Peter Graves <gnooth@gmail.com>

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

\ Based on the reference implementation from http://www.forth200x.org/escaped-strings.html.

decimal

: add-char      \ char $addr --
\ Add the character to the end of the counted string.
    tuck count + c!
    1 swap c+!
;

: append        \ c-addr u $dest --
\ Add the string described by c-addr u to the counted string at
\ $dest. The strings must not overlap.
    >r
    tuck r@ count + swap cmove          \ add source to end
    r> c+!                              \ add length to count
;

: extract-hex   \ c-addr1 u1 -- c-addr2 u2 n
\ Extract a two-digit hex number from the start of the string,
\ returning the remaining string and the converted number.
  base@ >r
  hex
  0 0 2over drop 2 >number 2drop drop
  >r 2 /string  r>
  r> base!
;

create escape-table     \ -- addr
\ Translation table for \a..\z.
       7  c,    \ \a BEL (Alert)
       8  c,    \ \b BS  (Backspace)
      'c' c,    \ \c
      'd' c,    \ \d
      27  c,    \ \e ESC (Escape)
      12  c,    \ \f FF  (Form feed)
      'g' c,    \ \g
      'h' c,    \ \h
      'i' c,    \ \i
      'j' c,    \ \j
      'k' c,    \ \k
      10  c,    \ \l LF  (Line feed)
      'm' c,    \ \m
      10  c,    \ \n (Linux only)
      'o' c,    \ \o
      'p' c,    \ \p
      '"' c,    \ \q "   (Double quote)
      13  c,    \ \r CR  (Carriage Return)
      's' c,    \ \s
       9  c,    \ \t HT  (horizontal tab}
      'u' c,    \ \u
      11  c,    \ \v VT  (vertical tab)
      'w' c,    \ \w
      'x' c,    \ \x
      'y' c,    \ \y
       0  c,    \ \z NUL (no character)

: add-escape    \ c-addr1 u1 $dest -- c-addr2 u2
\ Add an escape sequence to the counted string at $dest, returning the
\ remaining string.
    local $dest                         \ c-addr1 u1
    dup 0= if                           \ zero length check
        drop exit
    then
    over c@ 'x' = if                    \ hex number?
        1 /string extract-hex
        $dest add-char
        exit
    then
    over c@ 'm' = if                    \ CR/LF pair
        1 /string  13 $dest add-char  10 $dest add-char  exit
    then
    over c@ 'n' = if                    \ CR/LF pair? (Windows only)
        1 /string
        13 $dest add-char
        10 $dest add-char
        exit
    then
    over c@ 'a' 'z' 1+ within if
        over c@ 'a' - escape-table + c@ $dest add-char
    else
        over c@ $dest add-char
    then
    1 /string
;

: parse\"       \ c-addr1 u1 dest -- c-addr2 u2
\ Parses a string up to an unescaped '"', translating '\' escapes to
\ characters. The translated string is a counted string at dest.
\ The supported escapes (case sensitive) are:
\ \a      BEL          (alert)
\ \b      BS           (backspace)
\ \e      ESC (not in C99)
\ \f      FF           (form feed)
\ \l      LF (ASCII 10)
\ \m      CR/LF pair - for HTML etc.
\ \n      newline - CRLF for Windows, LF for Linux
\ \q      double-quote
\ \r      CR (ASCII 13)
\ \t      HT (tab)
\ \v      VT
\ \z      NUL (ASCII 0)
\ \"      double-quote
\ \xAB    Two char Hex numerical character value
\ \\      backslash itself
\ \       before any other character represents that character
    local dest                          \ -- c-addr1 u1
    0 dest c!
    begin                               \ -- c-addr1 u1
        dup
    while
        \ check for terminator
        over c@ '"' <>
        while
            over c@ '\' = if
                \ deal with escapes
                1 /string
                dest add-escape
            else
                \ normal character
                over c@ dest add-char
                1 /string
            then
        repeat
    then
    dup if
        \ step over terminating "
        1 /string
    then
;

: read-escaped  \ "ccc<quote>" -- c-addr
    1024 transient-alloc local pocket
    source >in @ /string tuck           \ -- len c-addr len
    pocket parse\" nip
    - >in +!
    pocket
;

: s\"           \ "ccc<quote>" -- c-addr u
    read-escaped count
    state @ if
        postpone sliteral
    then
; immediate
