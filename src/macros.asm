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

%macro  pushrbx 0
        mov     [rbp - BYTES_PER_CELL], rbx
        lea     rbp, [rbp - BYTES_PER_CELL]
%endmacro

%macro  poprbx  0
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%define USE_TAGS

%ifdef USE_TAGS

%define TAG_BITS        3

%define FIXNUM_TAG      1
%define BOOLEAN_TAG     6

%macro  _fixnum? 0
        _tag
%if FIXNUM_TAG = 0
        _zeq
%else
        _lit FIXNUM_TAG
        _equal
%endif
%endmacro

%macro  _tag 0                          ; object -- tag
        and     rbx, (1 << TAG_BITS) - 1
%endmacro

%macro  _tag_fixnum 0
        shl     rbx, TAG_BITS
%if FIXNUM_TAG <> 0
        add     rbx, FIXNUM_TAG
%endif
%endmacro

%macro  _untag_fixnum 0
        sar     rbx, TAG_BITS
%endmacro

%define f_value BOOLEAN_TAG

%define t_value BOOLEAN_TAG + (1 << TAG_BITS)

%macro  _f 0
        pushrbx
        mov     ebx, f_value
%endmacro

%macro  _t 0
        pushrbx
        mov     ebx, t_value
%endmacro

%macro  _tag_boolean 0
        test    rbx, rbx
        jz      %%1
        mov     ebx, t_value
        jmp     %%2
%%1:
        mov     ebx, f_value
%%2:
%endmacro

%macro  _untag_boolean 0                ; t|f -- 1|0
        shr     rbx, TAG_BITS
%endmacro

%else ; not using tags

%define TAG_BITS        0

%macro  _fixnum? 0
        mov     rbx, -1
%endmacro

%macro  _tag_fixnum 0
%endmacro

%macro  _untag_fixnum 0
%endmacro

%define f_value 0

%define t_value -1

%macro  _f 0
        pushrbx
        mov     ebx, f_value
%endmacro

%macro  _t 0
        pushrbx
        mov     rbx, t_value
%endmacro

%macro  _tag_boolean 0
%endmacro

%macro  _untag_boolean 0
%endmacro

%endif ; USE_TAGS

%macro  _tag_char 0
        _tag_fixnum
%endmacro

%macro  _untag_char 0
        _untag_fixnum
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
        %error "_return in inline"
%endif
%endmacro

%macro  pushd   1
        pushrbx
        mov     rbx, %1
%endmacro

%macro  popd    1
        mov     %1, rbx
        poprbx
%endmacro

%ifdef WIN64
%macro  xcall   1
        push    rbp
        mov     rbp, [cold_rbp_data]
        sub     rsp, 32
        test    rsp, 0x0f
        jnz     %%fixstack
        call    %1
        jmp     %%out
%%fixstack:
        sub     rsp, 8
        call    %1
        add     rsp, 8
%%out:
        add     rsp, 32
        pop     rbp
%endmacro
%else
; Linux
%define xcall   call
%endif

%macro  _       1
        call    %1
%endmacro

%macro  _lit    1
        pushd   %1
%endmacro

%define current_file    0

%macro  file    1
%strlen len1    %1
%strlen len2    FELINE_SOURCE_DIR
section .data
        align   DEFAULT_DATA_ALIGNMENT
%%name:
        db      len1 + len2 + 1
        db      FELINE_SOURCE_DIR
%ifdef WIN64
        db      '\'
%else
        db      '/'
%endif
        db      %1
        db      0
%define current_file    %%name
%endmacro

; Types
%define TYPE_VARIABLE   1
%define TYPE_VALUE      2
%define TYPE_2VALUE     3
%define TYPE_DEFERRED   4
%define TYPE_CONSTANT   5
%define TYPE_GLOBAL     6

; Object types
OBJECT_TYPE_FIRST               equ 1

OBJECT_TYPE_VECTOR              equ 1
OBJECT_TYPE_STRING              equ 2
OBJECT_TYPE_SBUF                equ 3
OBJECT_TYPE_ARRAY               equ 4

OBJECT_TYPE_LAST                equ 4

; Object flag bits.
OBJECT_MARKED_BIT               equ 1
OBJECT_TRANSIENT_BIT            equ 2
OBJECT_ALLOCATED_BIT            equ 4

%define forth_link      0

%define feline_link     0

%macro  IN_FELINE 0
%undef  in_forth
%define in_feline
%endmacro

%macro  IN_FORTH 0
%undef  in_feline
%define in_forth
%endmacro

%macro  name_token 2                    ; label, name

%strlen len     %2
        section .data
        align   DEFAULT_DATA_ALIGNMENT
        dq      current_file
        dq      __LINE__
        dq      %1_xt                   ; xt pointer field

%ifdef in_feline
        dq      feline_link
%elifdef in_forth
        dq      forth_link              ; link field
%else
        %fatal "no vocabulary specified"
%endif

%1_nfa:
        db      len
        db      %2
        db      0
        align   DEFAULT_DATA_ALIGNMENT

; Link field points to name field.
%ifdef in_feline
%define feline_link     %1_nfa
%elifdef in_forth
%define forth_link      %1_nfa
%else
        %fatal "no vocabulary specified"
%endif

%endmacro

%macro  execution_token 1-4             ; label, flags, inline size, type
        global %1
        section .data
        align   DEFAULT_DATA_ALIGNMENT
%1_xt:
        dq      %1                      ; address of code
        dq      0                       ; comp field
        dq      %1_pfa                  ; parameter field address
        dq      %1_nfa                  ; nfa
        db      %2                      ; flags
        db      %3                      ; inline size
        db      %4                      ; type
        align   DEFAULT_DATA_ALIGNMENT
%1_pfa:                                 ; define pfa (but don't reserve any space)
%endmacro

%macro  head 2-5 0, 0, 0                ; label, name, flags, inline size, type
        name_token %1, %2
        execution_token %1, %3, %4, %5
%endmacro

%macro  _toname 0                       ; xt -- nfa
        mov     rbx, [rbx + BYTES_PER_CELL * 3]
%endmacro

%macro  _namefrom 0                     ; nt -- xt
        mov     rbx, [rbx - BYTES_PER_CELL * 2]
%endmacro

%macro  _set_xt 0                       ; xt nfa --
; stores xt in the xt pointer field of the name token
        mov     rax, [rbp]              ; xt in rax
        mov     [rbx - BYTES_PER_CELL * 2], rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
%endmacro

%macro  _tocode 0                       ; xt -- code-address
        mov     rbx, [rbx]
%endmacro

%macro  _name_to_code 0
        _namefrom
        _tocode
%endmacro

%macro  _tocomp 0                       ; xt -- comp-field
        add     rbx, BYTES_PER_CELL
%endmacro

%macro  _tolink 0                       ; xt -- lfa
        _toname
        sub     rbx, BYTES_PER_CELL
%endmacro

%macro  _tobody 0
        mov     rbx, [rbx + BYTES_PER_CELL * 2]
%endmacro

%macro  _toflags 0
        add     rbx, BYTES_PER_CELL * 4
%endmacro

%macro  _toinline 0
        add     rbx, BYTES_PER_CELL * 4 + 1
%endmacro

%macro  _totype 0
        add     rbx, BYTES_PER_CELL * 4 + 2
%endmacro

%macro  _toview 0
        _toname
        sub     rbx, BYTES_PER_CELL * 4
%endmacro

%macro  _name_to_link 0
        sub     rbx, BYTES_PER_CELL
%endmacro

%macro  _ltoname 0
        add     rbx, BYTES_PER_CELL
%endmacro

%macro  _nametoflags 0
        _namefrom
        _toflags
%endmacro

%macro  _nametotype 0
        _namefrom
        _totype
%endmacro

%macro  code 2-5 0, 0, 0
        head %1, %2, %3, %4, %5
        section .text
        align   DEFAULT_CODE_ALIGNMENT
%1:
%endmacro

%macro  endcode 0-1
%ifdef  in_inline
        %error "endcode in inline"
%endif
%endmacro

%macro  inline 2-5 0, 0, 0
        %push inline
        %define in_inline
        head %1, %2, 0, %$ret - %1
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
        head %1, %2, 0, 0, TYPE_DEFERRED
        section .data
        global %1_data
        align   DEFAULT_DATA_ALIGNMENT
%1_data:
        dq      %3_xt
        section .text
        align   DEFAULT_CODE_ALIGNMENT
%1:
        mov     rax, %1_data
        mov     rax, [rax]
        jmp     [rax]
        ret                             ; for decompiler
%endmacro

%macro  variable 3                      ; label, name, value
        head    %1, %2, 0, %1_ret - %1, TYPE_VARIABLE
        section .data
        global %1_data
        align   DEFAULT_DATA_ALIGNMENT
%1_data:
        dq      %3
        section .text
%1:
        pushrbx
        mov     ebx, %1_data            ; REVIEW assumes 32-bit address
%1_ret:
        next
%endmacro

%macro  value 3                         ; label, name, value
        head    %1, %2, 0, %1_ret - %1, TYPE_VALUE
        section .data
        global %1_data
        align   DEFAULT_DATA_ALIGNMENT
%1_data:
        dq      %3
        section .text
%1:
        pushrbx
        mov     rbx, [%1_data]
%1_ret:
        next
%endmacro

%macro  constant 3                      ; label, name, value
        head    %1, %2, 0, %1_ret - %1, TYPE_CONSTANT
        section .text
%1:
        pushrbx
        mov     rbx, %3
%1_ret:
        next
%endmacro

%macro  _from 1
        pushrbx
        mov     rbx, [%1_data]
%endmacro

%macro  _to 1                           ; label
        mov     [%1_data], rbx          ; REVIEW 32-bit address
        poprbx
%endmacro

%macro  _clear 1                        ; label
        xor     eax, eax
        mov     [%1_data], rax          ; REVIEW 32-bit address
%endmacro

%macro  _zeroto 1                       ; label
        xor     eax, eax
        mov     [%1_data], rax          ; REVIEW 32-bit address
%endmacro

%macro  _plusto 1                       ; label
        add     [%1_data], rbx          ; REVIEW 32-bit address
        poprbx
%endmacro

%macro  _oneplusto 1                    ; label
        inc     qword [%1_data]
%endmacro

%macro  _dotq 1
section .data
%strlen len     %1
%%string:
        db      len                     ; length byte
        db      %1                      ; string
        db      0                       ; null byte at end
section .text
        pushrbx
        mov     rbx, %%string
        call    counttype
%endmacro

%macro  _abortq 1
section .data
%strlen len     %1
%%string:
        db      len                     ; length byte
        db      %1                      ; string
        db      0                       ; null byte at end
section .text
        pushrbx
        mov     rbx, %%string
        call    parenabortquote
%endmacro

%macro  _quote 1                        ; -- string
section .data
%strlen len     %1
%%string:
        dw      OBJECT_TYPE_STRING
        db      0                       ; flags byte
        db      0                       ; not used
        dd      0                       ; not used
        dq      len                     ; length
        db      %1                      ; string
        db      0                       ; null byte at end
section .text
        pushrbx
        mov     rbx, %%string
%endmacro

%macro  _cquote 1                       ; -- c-addr
section .data
%strlen len     %1
%%string:
        db      len                     ; length byte
        db      %1                      ; string
        db      0                       ; null byte at end
section .text
        pushrbx
        mov     rbx, %%string
%endmacro

%macro  _squote 1                       ; -- c-addr u
section .data
%strlen len     %1
%%string:
        db      %1                      ; string
        db      0                       ; null byte at end
section .text
        lea     rbp, [rbp - BYTES_PER_CELL * 2]
        mov     [rbp + BYTES_PER_CELL], rbx
        mov     qword [rbp], %%string
        mov     rbx, len
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
%ifdef USE_TAGS
        %push if
        section .text
        cmp     rbx, f_value
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jz      %1_ifnot
%else
        _if %1
%endif
%endmacro

%macro  _zeq_if 1
        %push if
        section .text
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jnz      %1_ifnot
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
        poprbx
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

%macro _repeat 1
section .text
        jmp     %1_begin
%1_end:
%endmacro

%macro  _until 1
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jz      %1_begin
%endmacro

%macro _drop 0
        poprbx
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

%macro  _do_common 0
        mov     rdx, [rbp]              ; limit in rdx
        mov     rax, $8000000000000000  ; offset loop limit by $8000000000000000
        add     rdx, rax
        push    rdx                     ; r: -- leave-addr limit
        sub     rbx, rdx                ; subtract modified limit from index
        push    rbx                     ; r: -- leave-addr limit index
        _2drop
%endmacro

%macro  _do 1
        mov     rax, %1_exit            ; leave-addr in rax
        push    rax                     ; r: -- leave-addr
        _do_common
%1_top:
%endmacro

%macro  _?do 1
        mov     rax, %1_exit            ; leave-addr in rax
        push    rax                     ; r: -- leave-addr
        cmp     rbx, [rbp]
        jne     %1_ok
        _2drop
        ret                             ; same as jumping to %1_exit
%1_ok:
        _do_common
%1_top:
%endmacro

%macro  _loop 1
        inc     qword [rsp]
        jno     %1_top
        add     rsp, BYTES_PER_CELL * 3
%1_exit:
%endmacro

%macro  _i 0
        pushrbx
        mov     rbx, [rsp]
        add     rbx, [rsp + BYTES_PER_CELL]
%endmacro

%macro  _i_plus 0
        mov     rax, [rsp]
        add     rax, [rsp + BYTES_PER_CELL]
        add     rbx, rax
%endmacro

%macro  _leave 0
        add     rsp, BYTES_PER_CELL * 2
        ret                             ; same as jumping to %1_exit
%endmacro

%macro  _unloop 0
        add     rsp, BYTES_PER_CELL * 3
%endmacro

%macro  _zero 0
        _lit 0
%endmacro

%macro  _true 0
        _lit -1
%endmacro

%macro  _false 0
        _lit 0
%endmacro

%macro  _ccommac 1
        _lit    %1
        _ ccommac
%endmacro

%macro  _locals_enter 0
        push    r14
        lea     r14, [r14 - BYTES_PER_CELL * MAX_LOCALS];
%endmacro

%macro  _locals_leave 0
        pop     r14
%endmacro

%define local0          [r14]
%define local1          [r14 + BYTES_PER_CELL]
%define local2          [r14 + BYTES_PER_CELL * 2]
%define local3          [r14 + BYTES_PER_CELL * 3]
%define local4          [r14 + BYTES_PER_CELL * 4]

%macro  _local0 0
        pushrbx
        mov     rbx, local0
%endmacro

%macro  _to_local0 0
        mov     local0, rbx
        poprbx
%endmacro

%macro  _local1 0
        pushrbx
        mov     rbx, local1
%endmacro

%macro  _to_local1 0
        mov     local1, rbx
        poprbx
%endmacro

%macro  _local2 0
        pushrbx
        mov     rbx, local2
%endmacro

%macro  _to_local2 0
        mov     local2, rbx
        poprbx
%endmacro
