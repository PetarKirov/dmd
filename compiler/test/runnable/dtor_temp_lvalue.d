/* The value of a full expression whose result is an lvalue inside one of its
 * own temporaries, such as `T(9).v`, is read before the temporaries are
 * destroyed. Inlining `T(9).get()` gives that form, so `-inline` (one of the
 * default permutations) and lazy arguments hit it too.
 */

struct T
{
    int v;
    static int dtors;
    ~this() { v = -1; ++dtors; }
    int get() { return v; }
}

struct Outer
{
    T t;
    int[2] a;
    ~this() { a[] = -1; }
}

int field() { return T(9).v; }
int member() { return T(9).get; }
int[2] array() { return Outer(T(1), [7, 8]).a; }
int dg(int delegate() d) { return d(); }
int lz(lazy int x) { return x; }
int lzTwice(lazy int x) { return x + x; }

int g = 5;
struct Bump
{
    int* p;
    ~this() { *p = 99; }
    ref int get() { return *p; }
}
int global() { return Bump(&g).get; }        // the value before the destructor
ref int globalRef() { return *Bump(&g).p; } // the variable itself

void main()
{
    assert(field() == 9);
    assert(member() == 9);
    assert(array() == [7, 8]);
    assert(dg(() => T(9).get) == 9);
    assert(lz(T(9).get) == 9);
    assert(lz(T(9).v) == 9);
    assert(lzTwice(T(4).get) == 8);

    int x = T(3).get;
    assert(x == 3);
    if (T(2).get != 2)
        assert(0);

    T.dtors = 0;
    assert(member() == 9 && T.dtors == 1);

    g = 5;
    assert(global() == 5);
    assert(g == 99);
    g = 5;
    assert(&globalRef() is &g);
    assert(g == 99);
}
