/* REQUIRED_ARGS: -betterC
   PERMUTE_ARGS: -preview=dip1000
 */
// https://github.com/dlang/dmd/issues/22885
// A `scope` lazy variadic array needs no closure, so no GC: it works in -betterC

alias Lz = int delegate() @safe pure nothrow @nogc;

int sum(scope Lz[] xs...) @safe pure nothrow @nogc
{
    int s;
    foreach (x; xs)
        s += x();
    return s;
}

int first(scope Lz[] xs...) @safe pure nothrow @nogc => xs[0]();

int locals(int a, int b) @safe pure nothrow @nogc => sum(a, b + 1, sum(a, b));
int deep(int n) @safe pure nothrow @nogc => n == 0 ? 0 : sum(n, deep(n - 1));

struct T
{
    int v;
    __gshared int dtors;
    ~this() @nogc nothrow { v = -1; ++dtors; }
    int get() const @safe pure nothrow @nogc => v;
}

int temp(int a) @nogc nothrow => sum(T(a).get, T(a + 1).get);

extern (C) int main()
{
    assert(locals(1, 2) == 1 + 3 + 3);
    int n;
    assert(first(++n, ++n) == 1);
    assert(n == 1);
    assert(deep(1000) == 1000 * 1001 / 2);
    assert(temp(4) == 9);
    assert(T.dtors == 2);
    return 0;
}
