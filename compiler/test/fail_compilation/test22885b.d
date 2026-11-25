/*
TEST_OUTPUT:
---
fail_compilation/test22885b.d(16): Error: function `@safe void test22885b.C.m(int delegate() @safe[] xs...)` does not override any function
fail_compilation/test22885b.d(15):        did you mean to override `@safe void test22885b.B.m(scope int delegate() @safe[] xs...)`?
---
*/
// https://github.com/dlang/dmd/issues/22885
// A call through `B.m` keeps its arguments' frames on the stack, so an
// override may not drop the declared `scope` that covers the delegates.

alias Dg = int delegate() @safe;
Dg g;

class B { void m(scope Dg[] xs...) @safe {} }
class C : B { override void m(Dg[] xs...) @safe { g = xs[0]; } }
class D : B { override void m(scope Dg[] xs...) @safe {} }
