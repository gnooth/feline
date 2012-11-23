code value, 'value'
        _ header
        _lit dovalue
        _ commacall
        _ comma
        next
endcode

code dovalue, 'dovalue'
        pop     rax                     ; return address
        pushrbx
        mov     rbx, [rax]
        next
endcode

code storeto, 'to', IMMEDIATE
        _ tick
        _ tobody
        _ state
        _ fetch
        _if storeto1
        _lit lit
        _ commacall
        _ comma
        _lit store
        _ commacall
        _else storeto1
        _ store
        _then storeto1
        next
endcode
