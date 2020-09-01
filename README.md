# Feline 0.0.0.58

September 1, 2020

Feline is a concatenative programming language in the spirit of Forth, Joy and
Factor.

Feline runs on Linux and Windows, x86-64 only (the implementation is mostly
written in x86-64 assembly language).

If you have the right tools installed (GNU Make, gcc, nasm), you should be able
to build it on Linux by just typing `make` in the top-level source directory. A
full build should take less than a minute on reasonably modern hardware.

Building on Windows is more of an adventure. The hard part is getting the GNU
tools installed. I'm using gcc (tdm64-1) 5.1.0, GNU Make 4.2.1, and nasm
2.13.01 on Windows 10.

Feline also builds and runs on the Windows 10 Linux Subsystem, where you can
use `apt-get` to install the tools.

After starting Feline, you can type `+color` at the `in: user>` prompt if you'd
like a more colorful experience, but the default color setup is only suitable if
your console window has a dark background. `-color` turns color off.

To a first approximation, Feline looks like Forth:
```
  in: user> 1 2 +
  -- Data stack:
      3                                             -- fixnum
```
Like Forth, Feline is a postfix language (mostly).

Feline automatically displays the data stack after each expression is
evaluated. To clear the stack, type `clear`.

Feline definitions look like Forth definitions:
```
  in: user> : test "This is a test!" write ;
  in: user> test
  This is a test!
```
Like Forth, words in Feline are delimited by whitespace, and any character at
all may be part of a Feline name. So it's possible to do silly things:
```
  in:user> : 1234 42 ;
  in:user> 1234
  -- Data stack:
      42                                            -- fixnum
```
Unlike Forth, Feline is case-sensitive, and all of the builtin words are lower
case.

You can list all the words, one per line:
```
  in:user> all-words [ symbol-name print ] each
```
In this example, `all-words` returns a vector (a 1-dimensional mutable array)
containing all the words in the system (including any words you've defined
during the current session). The vector is returned by putting a reference to
it on top of the data stack.

The next expression, `[ symbol-name print ]`, is a quotation. A quotation is an
anonymous function. The bracket notation for quotations comes from Factor (and
indirectly from Joy) and should not be confused with the Forth use of brackets
to enter interpretation state in the middle of a definition.

The elements of the vector returned by `all-words` are symbols. In the
quotation, `symbol-name` puts the name of the symbol on top of the stack, and
`print` prints the object that is on top of the stack, removing it from the
stack in the process (the object itself is not harmed in any way, but it is no
longer on the stack). `print` also prints a newline following the symbol name.

`each` is a combinator which applies the quotation to each element of the
vector.

If you forget what `each` does, you can get help:
```
  in: user> h each
  each
      ( seq quot -- )            quot: ( element -- )
      Apply `quot` to each element of `seq` in order.
```
`h` is an interactive shortcut. Like most interactive shortcuts in Feline, `h`
is a prefix operator, so `h each` provides help on the word `each`.

Out of the box there are about 1300 words in Feline:
```
  in: user> all-words length .
  1555
```
But only about 100 of them currently have help. (Sad!)

You can use the interactive shortcut `a` (apropos) to print words matching a
specified pattern:
```
  in: user> a dup
  2dup
  dupd
  dup
  3dup
```
You can look at the source for any Feline word:
```
  in: user> e dup
```
When you're done looking, control q gets you out of the editor. (The Feline
editor is not recommended for any actual editing.)

You can disassemble any Feline word using the interactive shortcut `d`:
```
  in: user> d dup
  0x406280 48 89 5d f8                    mov     qword [rbp-8], rbx
  0x406284 48 8d 6d f8                    lea     rbp, [rbp-8]
  0x406288 c3                             ret
  3 instructions 9 bytes
```
Going beyond Forth, Feline provides types, objects, garbage collection, and
simple generic functions. This makes it look more like Factor, and a lot of
ideas, some code, and the names of many things in Feline have been adapted (or
simply stolen) from Factor.

The editor (in the feral subdirectory) and disassembler (in src) are examples
of non-trivial programs written in Feline.

Please bear in mind that the development of Feline is still at a very early
stage. Almost everything is still subject to change.

Thanks for your support.
