; Copyright (C) 2012-2020 Peter Graves <gnooth@gmail.com>

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

%define BYTES_PER_CELL 8

%macro  _dup 0
        mov     [rbp - BYTES_PER_CELL], rbx
        lea     rbp, [rbp - BYTES_PER_CELL]
%endmacro

%macro  pushrbx 0
        mov     [rbp - BYTES_PER_CELL], rbx
        lea     rbp, [rbp - BYTES_PER_CELL]
%endmacro

%macro _drop 0
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  poprbx  0
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%define LOWTAG_BITS     3
%define LOWTAG_MASK     7

%define FIXNUM_TAG_BITS         1
%define FIXNUM_TAG_MASK         (1 << FIXNUM_TAG_BITS) - 1

%define FIXNUM_TAG      1

%define MOST_POSITIVE_FIXNUM     4611686018427387903
%define MOST_NEGATIVE_FIXNUM    -4611686018427387904

%define CHAR_TAG        0xe2
%define CHAR_TAG_BITS   8

%define BOOLEAN_TAG_BITS        3
%define BOOLEAN_TAG_MASK        (1 << BOOLEAN_TAG_BITS) - 1

%define BOOLEAN_TAG     6

%macro  _tag_fixnum 0
        shl     rbx, FIXNUM_TAG_BITS
        or      rbx, FIXNUM_TAG
%endmacro

%define tagged_fixnum(n)        ((n << FIXNUM_TAG_BITS) + FIXNUM_TAG)

%define tagged_zero     FIXNUM_TAG

%macro  _untag_fixnum 0
        sar     rbx, FIXNUM_TAG_BITS
%endmacro

%macro  _untag_fixnum 1
        sar     %1, FIXNUM_TAG_BITS
%endmacro

%macro  _untag_2_fixnums 0
        sar     rbx, FIXNUM_TAG_BITS
        sar     qword [rbp], FIXNUM_TAG_BITS
%endmacro

%macro  _verify_fixnum 0
        test    bl, FIXNUM_TAG
        jz      error_not_fixnum
%endmacro

%macro  _verify_fixnum 1
        mov     rax, %1
        test    al, FIXNUM_TAG
        jz      error_not_fixnum_rax
%endmacro

%macro  _check_fixnum 0
        _verify_fixnum
        _untag_fixnum
%endmacro

%macro  _check_fixnum 1
        _verify_fixnum %1
        _untag_fixnum %1
%endmacro

%macro  _verify_index 0
        test    bl, FIXNUM_TAG
        jz      error_not_index
        test    rbx, rbx
        js      error_not_index
%endmacro

%macro  _verify_index 1
        mov     rax, %1
        test    al, FIXNUM_TAG
        jz      error_not_index_rax
        test    rax, rax
        js      error_not_index_rax
%endmacro

%macro  _check_index 0
        _verify_index
        _untag_fixnum
%endmacro

%macro  _check_index 1
        _verify_index %1
        _untag_fixnum %1
%endmacro

%macro  _check_index_rax 0
        test    al, FIXNUM_TAG
        jz      error_not_index
        test    rax, rax
        js      error_not_index
        sar     rax, FIXNUM_TAG_BITS
%endmacro

%define f_value BOOLEAN_TAG
%define t_value BOOLEAN_TAG + (1 << LOWTAG_BITS)

%define NIL     BOOLEAN_TAG
%define TRUE    BOOLEAN_TAG + (1 << LOWTAG_BITS)

%macro  _f 0
        _dup
        mov     ebx, NIL
%endmacro

%macro  _t 0
        _dup
        mov     ebx, TRUE
%endmacro

%macro  _nil 0
        _dup
        mov     ebx, NIL
%endmacro

%macro  _true 0
        _dup
        mov     ebx, TRUE
%endmacro

%macro  _tag_boolean 0
; converts 0 in rbx to nil, anything else to true
        mov     eax, NIL
        test    rbx, rbx
        mov     ebx, TRUE
        cmovz   ebx, eax
%endmacro

%macro  _as_boolean 0
; converts anything in rbx but nil to true
        mov     eax, TRUE
        cmp     rbx, NIL
        cmovne  rbx, rax
%endmacro

%macro  _char? 0                        ; x -> ?
        cmp     bl, CHAR_TAG
        mov     eax, NIL
        mov     ebx, TRUE
        cmovne  ebx, eax
%endmacro

%macro  _tag_char 0
        shl     rbx, CHAR_TAG_BITS
        or      rbx, CHAR_TAG
%endmacro

%macro  _untag_char 0
        shr     rbx, CHAR_TAG_BITS
%endmacro

%macro  _untag_char 1
        shr     %1, CHAR_TAG_BITS
%endmacro

%macro  _verify_char 0
        cmp     bl, CHAR_TAG
        jne     error_not_char
%endmacro

%macro  _verify_char 1
        mov     rax, %1
        cmp     al, CHAR_TAG
        jne     error_not_char
%endmacro

%macro  _check_char 0
        _verify_char
        _untag_char
%endmacro

%macro  _check_char 1
        _verify_char %1
        _untag_char %1
%endmacro

%define tagged_char(n)  ((n << CHAR_TAG_BITS) + CHAR_TAG)

%define MOST_POSITIVE_INT64      9223372036854775807
%define MOST_NEGATIVE_INT64     -9223372036854775808

; tagged handles
%define HANDLE_TAG_BITS         8
%define HANDLE_TAG              0xf2

%macro  _tag_handle 0
        shl     rbx, HANDLE_TAG_BITS
        or      rbx, HANDLE_TAG
%endmacro

%macro  _untag_handle 0
        shr     rbx, HANDLE_TAG_BITS
%endmacro

%define DEFAULT_DATA_ALIGNMENT  8

%define DEFAULT_CODE_ALIGNMENT 16

%macro  next    0
%ifndef in_inline
        ret
%else
        %error "next in inline"
%endif
%endmacro

%macro  _return 0
%ifndef in_inline
        ret
%else
        %error "return in inline"
%endif
%endmacro

%macro  _rep_return 0
; https://repzret.org/p/repzret/
%ifndef in_inline
        rep
        ret
%else
        %error "return in inline"
%endif
%endmacro

%macro  pushd   1
        _dup
        mov     rbx, %1
%endmacro

%macro  popd    1
        mov     %1, rbx
        _drop
%endmacro

%ifdef WIN64

; Windows
%macro  xcall   1
        push    rbp
        mov     rbp, rsp
        sub     rsp, 32
        and     rsp, ~8
        call    %1
        mov     rsp, rbp
        pop     rbp
%endmacro

%else

; Linux
%macro  xcall   1
        push    rbp
        mov     rbp, rsp
        and     rsp, ~8
        call    %1
        mov     rsp, rbp
        pop     rbp
%endmacro

%endif

; argument registers for xcall
%ifdef WIN64
%define arg0_register   rcx
%define arg1_register   rdx
%define arg2_register   r8
%define arg3_register   r9
%else
; Linux
%define arg0_register   rdi
%define arg1_register   rsi
%define arg2_register   rdx
%define arg3_register   rcx
%endif

%macro  _       1
        call    %1
%endmacro

%macro  _lit    1
        _dup
        mov     rbx, %1
%endmacro

%macro  _tagged_fixnum 1
        _dup
        mov     rbx, tagged_fixnum(%1)
%endmacro

%macro  _tagged_char 1
        _dup
        mov     rbx, tagged_char(%1)
%endmacro

%macro  _char_code 0
        _untag_char
        _tag_fixnum
%endmacro

%macro  _code_char 0
        _untag_fixnum
        _tag_char
%endmacro

; DEPRECATED use asm_global
%macro  _global 1
        global %1
        section .data
        align   DEFAULT_DATA_ALIGNMENT
%1:
        dq      0
%endmacro

; DEPRECATED use asm_global
%macro  _global 2
        global %1
        section .data
        align   DEFAULT_DATA_ALIGNMENT
%1:
        dq      %2
%endmacro

; asm-only globals
%macro  asm_global 1
        global %1
        section .data
        align   DEFAULT_DATA_ALIGNMENT
%1:
        dq      0
%endmacro

%macro  asm_global 2
        global %1
        section .data
        align   DEFAULT_DATA_ALIGNMENT
%1:
        dq      %2
%endmacro

; static string
%macro  string 2                        ; label, string
        section .data
        align   DEFAULT_DATA_ALIGNMENT
%strlen len     %2
%1:
        ; object header
        dw      TYPECODE_STRING
        db      0                       ; flags byte
        db      0                       ; not used
        dd      0                       ; not used

        ; slot 1
        dq      len                     ; length

        ; slot 2
        dq      NIL                     ; hashcode

        db      %2                      ; string
        db      0                       ; null byte at end
%endmacro

%ifdef WIN64
%define PATH_SEPARATOR_CHAR     '\'
%else
%define PATH_SEPARATOR_CHAR     '/'
%endif

%define current_file    0

%macro  file    1
%strcat str     FELINE_SOURCE_DIR, PATH_SEPARATOR_CHAR, %1
section .data
        align   DEFAULT_DATA_ALIGNMENT
%%label:
        string  %%path, str
%define current_file    %%label
%endmacro

; symbol bit flags
%define SYMBOL_PRIMITIVE        $0001
%define SYMBOL_IMMEDIATE        $0002
%define SYMBOL_INLINE           $0004
%define SYMBOL_GLOBAL           $0008
%define SYMBOL_CONSTANT         $0010
%define SYMBOL_SPECIAL          $0020
%define SYMBOL_PRIVATE          $0040
%define SYMBOL_GENERIC          $0080
%define SYMBOL_ALWAYS_INLINE    $0100
%define SYMBOL_INTERNAL         $0200
%define SYMBOL_THREAD_LOCAL     $0400
%define SYMBOL_DEFERRED         $0800

%macro  subroutine 1
        %push subroutine
        global %1
        section .text
        align   DEFAULT_CODE_ALIGNMENT
%1:
%endmacro

%macro  endsub 0
        %pop subroutine
%endmacro

%define symbol_link     0

; static symbol
%macro  symbol 2-6 0, 0, 0, NIL         ; label, name, code address, code size, flags, value

        string  %%name, %2

        section .data
        align   DEFAULT_DATA_ALIGNMENT
        dq      symbol_link
%1:
        ; object header
        dw      TYPECODE_SYMBOL         ; object typecode
        db      0                       ; object flags byte
        db      0                       ; not used
        dd      0                       ; not used

        dq      %%name                  ; symbol name (will be tagged in hash-vocabs)

;         dq      FELINE_VOCAB_NAME       ; vocab name
        dq      NIL                     ; vocab name (will be set in hash-vocabs)

        dq      NIL                     ; hashcode (link field)
        dq      NIL                     ; def
        dq      NIL                     ; props

        global  %1_symbol_value

%1_symbol_value:
        dq      %6                      ; value
        dq      %3                      ; raw code address
        dq      %4                      ; raw code size (includes ret instruction)
        dq      %5                      ; raw bit flags
        dq      current_file            ; file
        dq      tagged_fixnum(__LINE__) ; tagged line number

%define symbol_link     %1

%endmacro

%macro  head 2-4 0, 0                   ; label, name, flags, inline size
        symbol S_%1, %2, %1, %4, %3
%endmacro

%define symbol(x) S_ %+ x               ; symbol(dup) -> S_dup

%macro  _symbol 1                       ; _symbol dup -> _lit S_dup
        _dup
        mov     rbx, symbol(%1)
        _tag_static_symbol
%endmacro

%macro  special 2                       ; label, name

        head    %1, %2, SYMBOL_SPECIAL, %1_ret - %1

        section .text
        align   DEFAULT_CODE_ALIGNMENT
%1:
        _dup
        mov     rbx, S_%1
        _tag_static_symbol
        ret
%1_ret:

%endmacro

%macro  code 2-4 SYMBOL_PRIMITIVE, 0
        %push code
        head %1, %2, %3, %$end - %1
        global %1
        section .text
        align   DEFAULT_CODE_ALIGNMENT
%1:
%endmacro

%macro  endcode 0-1
%ifdef  in_inline
        %error "endcode in inline"
%endif
        section .text
%$end:
        %pop code
%endmacro

%macro  inline 2-5 0, 0, 0
        %push inline
        %define in_inline

        ; adjust size to include ret instruction
        head %1, %2, SYMBOL_INLINE, %$ret - %1 + 1

        section .text
        align   DEFAULT_CODE_ALIGNMENT
%1:
%endmacro

%macro  always_inline 2-5 0, 0, 0
        %push inline
        %define in_inline

        ; adjust size to include ret instruction
        head %1, %2, SYMBOL_INLINE | SYMBOL_ALWAYS_INLINE, %$ret - %1 + 1

        section .text
        align   DEFAULT_CODE_ALIGNMENT
%1:
%endmacro

%macro  endinline 0
%ifdef  in_inline
        %undef in_inline
        section .text
%$ret:
        ret
%else
        %error "endinline not in inline"
%endif
        %pop inline
%endmacro

%macro  deferred 3                      ; label, name, action
        symbol S_%1, %2, %1, %1_ret - %1 + 1, SYMBOL_DEFERRED, %3
        section .text
        align DEFAULT_CODE_ALIGNMENT
%1:
        mov     rax, [S_%1_symbol_value]
        jmp     rax
%1_ret:
        next
%endmacro

%macro  value 3                         ; label, name, value
        head    %1, %2, 0, %1_ret - %1
        section .data
        global %1_data
        align   DEFAULT_DATA_ALIGNMENT
%1_data:
        dq      %3
        section .text
%1:
        _dup
        mov     rbx, [%1_data]
%1_ret:
        next
%endmacro

%macro  feline_global 3                 ; label, name, value
        symbol S_%1, %2, %1, %1_ret - %1 + 1, SYMBOL_GLOBAL | SYMBOL_INLINE, %3
        section .text
        align DEFAULT_CODE_ALIGNMENT
%1:
        _dup
        mov     rbx, [S_%1_symbol_value]
%1_ret:
        next
%endmacro

%macro  feline_global 2                 ; label, name
        feline_global %1, %2, NIL
%endmacro

%macro  feline_constant 3               ; label, name, value
        symbol S_%1, %2, %1, %1_ret - %1 + 1, SYMBOL_CONSTANT | SYMBOL_INLINE, %3
        section .text
        align DEFAULT_CODE_ALIGNMENT
%1:
        _dup
        mov     rbx, %3
%1_ret:
        next
%endmacro

%macro  _to 1                           ; label
        mov     [%1_data], rbx          ; REVIEW 32-bit address
        _drop
%endmacro

%macro  _zeroto 1                       ; label
        xor     eax, eax
        mov     [%1_data], rax          ; REVIEW 32-bit address
%endmacro

%macro  _oneplusto 1                    ; label
        inc     qword [%1_data]
%endmacro

; tagged static objects
%define STATIC_OBJECT_TAG_BITS  8
%define STATIC_STRING_TAG       0xd2
%define STATIC_SYMBOL_TAG       0xc2

%macro  _tag_static_string 0
        shl     rbx, STATIC_OBJECT_TAG_BITS
        or      rbx, STATIC_STRING_TAG
%endmacro

%macro  _untag_static_string 0
        shr     rbx, STATIC_OBJECT_TAG_BITS
%endmacro

%macro  _tag_static_symbol 0
        shl     rbx, STATIC_OBJECT_TAG_BITS
        or      rbx, STATIC_SYMBOL_TAG
%endmacro

%macro  _untag_static_symbol 0
        shr     rbx, STATIC_OBJECT_TAG_BITS
%endmacro

%macro  _quote 1                        ; -> string
        section .data
        align   DEFAULT_DATA_ALIGNMENT
%strlen len     %1
%%string:
        dw      TYPECODE_STRING
        db      0                       ; flags byte
        db      0                       ; not used
        dd      0                       ; not used
        dq      len                     ; length
        dq      NIL                     ; hashcode
        db      %1                      ; string
        db      0                       ; null byte at end
        section .text
        _dup
        mov     rbx, %%string
        _tag_static_string
%endmacro

%macro  _write_char 1
        _tagged_char %1
        _ write_char
%endmacro

%macro  _write 1
        _quote %1
        _ write_string
%endmacro

%macro  _print 1
        _quote %1
        _ write_string
        _ nl
%endmacro

%macro  _debug_print 1
%ifdef DEBUG_PRINT
        _quote %1
        _ debug_print
%endif
%endmacro

%macro  _error 1
        _quote %1
        _ error
%endmacro

%macro  _if 1
        %push if
        section .text
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jz      %1_ifnot
%endmacro

%macro  _tagged_if 1
        %push if
        section .text
        cmp     rbx, NIL
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jz      %1_ifnot
%endmacro

%macro  _tagged_if_not 1
        %push if
        section .text
        cmp     rbx, NIL
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jnz     %1_ifnot
%endmacro

%macro  _fixnum?_if 1
        %push if
        section .text
        and     ebx, FIXNUM_TAG_MASK
        cmp     ebx, FIXNUM_TAG
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jne      %1_ifnot
%endmacro

%macro  _dup_fixnum?_if 1
        %push if
        section .text
        mov     eax, ebx
        and     eax, FIXNUM_TAG_MASK
        cmp     eax, FIXNUM_TAG
        jne      %1_ifnot
%endmacro

%macro  _over_fixnum?_if 1
        %push if
        section .text
        mov     rax, qword [rbp]
        and     eax, FIXNUM_TAG_MASK
        cmp     eax, FIXNUM_TAG
        jne      %1_ifnot
%endmacro

%macro  _zeq_if 1
        %push if
        section .text
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jnz      %1_ifnot
%endmacro

%macro  _ult_if 1
        %push if
        section .text
        cmp     [rbp], rbx
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        jnc     %1_ifnot
%endmacro

%macro  _dup_if 1
        %push if
        section .text
        test    rbx, rbx
        jz      %1_ifnot
%endmacro

%macro  _?dup_if 1
        %push if
        section .text
        test    rbx, rbx
        jnz     %%skip
        _drop
        jz      %1_ifnot
%%skip:
%endmacro

%macro  _else 1
%ifctx if
        %repl   else
        section .text
        jmp     %1_then
%1_ifnot:
%else
        %error  "expected _if before _else"
%endif
%endmacro

%macro  _then 1
%ifctx if
%1_ifnot:
        %pop
%elifctx else
%1_then:
        %pop
%else
        %error  "expected _if or _else before _then"
%endif
%endmacro

%macro  _begin 1
section .text
%1_begin:
%endmacro

%macro _again 1
section .text
        jmp     %1_begin
%endmacro

%macro _while 1
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        je      %1_end
%endmacro

%macro  _tagged_while 1
        cmp     rbx, NIL
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        je      %1_end
%endmacro

%macro _repeat 1
section .text
        jmp     %1_begin
%1_end:
%endmacro

%macro _2drop 0
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _3drop 0
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
%endmacro

%macro  _4drop 0
        mov     rbx, [rbp + BYTES_PER_CELL * 3]
        lea     rbp, [rbp + BYTES_PER_CELL * 4]
%endmacro

%macro  _fixnum_zero? 0
        mov     eax, TRUE
        cmp     rbx, tagged_zero
        mov     ebx, NIL
        cmovz   ebx, eax
%endmacro

%macro  _zero 0
        _dup
        xor     ebx, ebx
%endmacro

; static quotation
%macro _quotation 1
        %push quotation
        section .text
        jmp     %1_end
        align   DEFAULT_CODE_ALIGNMENT
%1_code:
%endmacro

%macro _end_quotation 1
%ifctx quotation
        section .text
        ret
        section .data
        align   DEFAULT_DATA_ALIGNMENT
%1_quotation:
        ; object header
        dw      TYPECODE_QUOTATION      ; object typecode
        db      0                       ; object flags byte
        db      0                       ; not used
        dd      0                       ; not used

        dq      NIL                     ; array
        dq      %1_code                 ; code address

        section .text
        align   DEFAULT_CODE_ALIGNMENT
%1_end:
        _dup
        mov     rbx, %1_quotation
        %pop
%else
        %error  "not in a quotation"
%endif
%endmacro

%macro  _eq? 0                          ; obj1 obj2 -> ?
        cmp     rbx, [rbp]
        mov     eax, TRUE
        mov     ebx, NIL
        cmove   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _eq? 1                          ; obj -> ?
        cmp     rbx, %1
        mov     eax, TRUE
        mov     ebx, NIL
        cmove   ebx, eax
%endmacro

%macro  _rdtsc 0                        ; -- uint64
; "The high-order 32 bits are loaded into EDX, and the low-order 32 bits are
; loaded into the EAX register. This instruction ignores operand size."
        rdtsc
        _dup
        mov     ebx, eax
        shl     rdx, 32
        add     rbx, rdx
%endmacro

%macro  _debug_?enough 1                ; minimum-number-of-parameters --
%ifdef  DEBUG
        _lit tagged_fixnum(%1)
        _ ?enough
%endif
%endmacro

%macro  _debug_?enough_1 0
%ifdef  DEBUG
        _ ?enough_1
%endif
%endmacro

%macro  _os_malloc 0
        xcall   malloc
%endmacro

%macro  _os_realloc 0
        xcall   realloc
%endmacro

%macro  _os_free 0
        xcall   free
%endmacro

%macro  _feline_free 0
        mov     arg0_register, rbx
        _drop
        xcall   free
%endmacro
