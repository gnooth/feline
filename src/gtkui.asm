; Copyright (C) 2019 Peter Graves <gnooth@gmail.com>

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

file __FILE__

asm_global gtkui_raw_sp0_, 0

; ### gtkui-initialize
code gtkui_initialize, 'gtkui-initialize'

        _ current_thread_raw_sp0
        mov     [gtkui_raw_sp0_], rbx
        _drop

        extern  gtkui__initialize
        xcall   gtkui__initialize

        next
endcode

; ### gtkui_textview_paint
subroutine gtkui_textview_paint         ; void -> void
; 0-arg callback

        ; enter callback
        push    rbx
        push    rbp
        mov     rbp, [gtkui_raw_sp0_]

        _quote "repaint"
        _quote "editor"
        _ ?lookup_symbol
        _ call_symbol

        ; leave callback
        pop     rbp
        pop     rbx

        ret
endsub
