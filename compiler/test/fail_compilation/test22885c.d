/*
REQUIRED_ARGS: -preview=dip1000
TEST_OUTPUT:
---
fail_compilation/test22885c.d(22): Error: function `test22885c.caller` is `@nogc` yet allocates closure for `caller()` with the GC
fail_compilation/test22885c.d(22):        delegate `int() => a` closes over variable `a`
fail_compilation/test22885c.d(22):        `a` declared here
fail_compilation/test22885c.d(25): Error: function `test22885c.tcaller` is `@nogc` yet allocates closure for `tcaller()` with the GC
fail_compilation/test22885c.d(25):        delegate `int() => a` closes over variable `a`
fail_compilation/test22885c.d(25):        `a` declared here
---
*/
// https://github.com/dlang/dmd/issues/22885
// Without a declared `scope`, the delegates of a lazy variadic array may
// escape, so the caller still allocates a closure: the implicit `scope` of a
// typesafe variadic array covers only the array.

alias Dg = int delegate() @safe;
Dg g;

void keep(Dg[] xs...) @safe @nogc { g = xs[0]; }
void caller(int a) @safe @nogc { keep(a); }

T tkeep(T)(T delegate() @safe [] xs...) @nogc { g = xs[0]; return 0; }
void tcaller(int a) @safe @nogc { tkeep!int(a); }
