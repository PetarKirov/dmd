// EXTRA_SOURCES: imports/importc_inline_alias_cycle_c.c
// With an ImportC `inline` function in the program, the scan for unreferenced
// inline functions walked into a function through an `alias` to it, and from
// its body into the same alias again, until the stack overflowed.

import importc_inline_alias_cycle_c;

int f(int n)
{
    alias self = f;
    return n ? self(n - 1) : use(1);
}

int g(int n);
int h(int n)
{
    alias other = g;
    return n ? other(n - 1) : 0;
}
int g(int n)
{
    alias other = h;
    return n ? other(n - 1) : 0;
}
