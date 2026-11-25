// https://github.com/dlang/dmd/issues/22885
// REQUIRED_ARGS: -preview=dip1000
// PERMUTE_ARGS: -O -g
// Not -inline: inlining `() => T(1).get` reads the temporary after its
// destructor ran, with or without lazy arguments (a separate bug).

/* The arguments of a lazy variadic function whose array of delegates is
 * declared `scope` are evaluated in place, on the caller's stack: the
 * delegates need no closure, so the caller allocates nothing. Without `scope`
 * the delegates may escape, and the caller still allocates a closure.
 * https://dlang.org/spec/function.html#lazy_variadic_functions
 */

import core.memory : GC;

alias Lz = int delegate() @safe pure nothrow @nogc;
alias LzT = int delegate() @safe;

int sum(scope Lz[] xs...) @safe pure nothrow @nogc
{
    int s;
    foreach (x; xs)
        s += x();
    return s;
}

int first(scope Lz[] xs...) @safe pure nothrow @nogc => xs.length ? xs[0]() : -1;
int count(scope Lz[] xs...) @safe pure nothrow @nogc => cast(int) xs.length;
int twice(scope Lz[] xs...) @safe pure nothrow @nogc => xs[0]() + xs[0]();
// evaluates xs[0], then xs[1], then xs[0] again
int order(scope Lz[] xs...) @safe pure nothrow @nogc => 100 * xs[0]() + 10 * xs[1]() + xs[0]();

/******************************************/
// captures: locals, `ref`, `out`, `this`, nested calls

int locals(int a, int b) @safe pure nothrow @nogc => sum(a, b + 1);
int byRef(ref int a) @safe pure nothrow @nogc => sum(a, a *= 2, a);
void byOut(out int a) @safe pure nothrow @nogc { cast(void) sum(a = 3); }
int nested(int a) @safe pure nothrow @nogc => sum(sum(a), sum(a, sum(a + 1)), 1);
int nestedFn(int a) @safe pure nothrow @nogc
{
    int inner() => sum(a, a);
    return sum(inner(), inner());
}

struct S
{
    int f;
    int m() @safe pure nothrow @nogc => sum(f, f * 10);
}

class K
{
    int f = 4;
    int m() @safe pure nothrow @nogc => sum(f, f);
    int v(scope Lz[] xs...) @safe pure nothrow @nogc => sum(xs) + f; // virtual callee
}

void testCaptures() @safe
{
    auto k = new K;
    const before = GC.stats().allocatedInCurrentThread;

    assert(locals(1, 2) == 4);
    int a = 3;
    assert(byRef(a) == 3 + 6 + 6);
    assert(a == 6);
    int o = 7;
    byOut(o);
    assert(o == 3);
    assert(nested(2) == 2 + (2 + 3) + 1);
    assert(nestedFn(5) == 20);
    assert(S(2).m() == 22);
    assert(k.m() == 8);
    int b = 1;
    assert(k.v(b, b + 1) == 7);

    assert(GC.stats().allocatedInCurrentThread == before);
}

/******************************************/
// laziness, evaluation count and order, mutation seen through the frame

void testEvaluation() @safe @nogc
{
    int n;
    assert(first(++n, ++n, ++n) == 1);
    assert(n == 1);
    assert(count(++n, ++n) == 2);
    assert(n == 1);
    assert(count() == 0);
    assert(twice(++n) == 2 + 3);
    assert(n == 3);

    int a = 1;
    assert(order(a, a = 7) == 100 * 1 + 10 * 7 + 7);
    assert(a == 7);
}

/******************************************/
// exceptions thrown by an argument propagate; later arguments are not evaluated

int sumT(scope LzT[] xs...) @safe
{
    int s;
    foreach (x; xs)
        s += x();
    return s;
}

int thrower() @safe { throw new Exception("lazy"); }

void testExceptions() @safe
{
    int n;
    try
    {
        cast(void) sumT(++n, thrower(), ++n);
        assert(0);
    }
    catch (Exception e)
        assert(e.msg == "lazy");
    assert(n == 1);
}

/******************************************/
// struct temporaries live and die inside each evaluation

struct T
{
    int v;
    static int ctors, dtors;
    this(int v) @safe { this.v = v; ++ctors; }
    ~this() @safe { v = -1; ++dtors; }
    int get() const @safe { assert(v > 0); return v; }
}

int sumT2(scope LzT[] xs...) @safe
{
    int s;
    foreach (x; xs)
    {
        assert(T.ctors == T.dtors); // no temporary outlives an evaluation
        s += x();
        assert(T.ctors == T.dtors);
    }
    return s;
}

int firstT(scope LzT[] xs...) @safe => xs[0]() + xs[0]();
int noneT(scope LzT[] xs...) @safe => cast(int) xs.length;

struct P
{
    int v;
    static int posts, dtors;
    this(this) @safe { ++posts; }
    ~this() @safe { ++dtors; }
}

alias LzP = P delegate() @safe;
int sumP(scope LzP[] xs...) @safe
{
    int s;
    foreach (x; xs)
        s += x().v;
    return s;
}

void testTemporaries() @safe
{
    assert(sumT2(T(1).get, T(2).get, T(3).get) == 6);
    assert(T.ctors == 3 && T.dtors == 3);
    assert(firstT(T(4).get, T(5).get) == 8);
    assert(T.ctors == 5 && T.dtors == 5);
    assert(noneT(T(6).get) == 1);
    assert(T.ctors == 5 && T.dtors == 5);

    {
        P p = P(3);
        assert(sumP(p, p) == 6);
        assert(P.posts == 2 && P.dtors == 2);
        p.v = 4;
        assert(sumP(p) == 4); // sees the mutation
        assert(P.posts == 3 && P.dtors == 3);
    }
    assert(P.dtors == 4);
}

/******************************************/
// deep recursion and large frames through lazy arguments

int deep(int n) @safe pure nothrow @nogc => n == 0 ? 0 : sum(n, deep(n - 1));

int bigFrame(int n) @safe pure nothrow @nogc
{
    int[1024] frame = n;
    return sum(frame[0], frame[$ - 1], n ? bigFrame(n - 1) : 0);
}

void testRecursion() @safe
{
    const before = GC.stats().allocatedInCurrentThread;
    assert(deep(5000) == 5000 * 5001 / 2);
    assert(bigFrame(64) == 2 * (64 * 65 / 2));
    assert(GC.stats().allocatedInCurrentThread == before);
}

/******************************************/
// without `scope` the delegates may escape: the caller allocates a closure,
// and the stored delegates still see the caller's (now dead) frame's values

LzT[] stash;

void keep(LzT[] xs...) @safe { stash ~= xs; }

void keepCaller(int a) @safe { keep(a, a * 2, a * 3); }

int clobber(int n) @safe
{
    int[512] junk;
    foreach (i, ref j; junk)
        j = cast(int) i * n;
    return junk[n];
}

void testEscaping() @safe
{
    const before = GC.stats().allocatedInCurrentThread;
    keepCaller(5);
    keepCaller(7);
    assert(GC.stats().allocatedInCurrentThread > before);
    cast(void) clobber(3);
    assert(stash.length == 6);
    assert(stash[0]() == 5 && stash[1]() == 10 && stash[2]() == 15);
    assert(stash[3]() == 7 && stash[4]() == 14 && stash[5]() == 21);
}

/******************************************/
// CTFE

static assert(sum(1, 2, 3) == 6);
static assert(nested(2) == 8);
static assert(() { int n; return first(++n, ++n) * 10 + n; }() == 11);

/******************************************/

void main()
{
    testCaptures();
    testEvaluation();
    testExceptions();
    testTemporaries();
    testRecursion();
    testEscaping();
}
