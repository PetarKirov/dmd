/* PERMUTE_ARGS: -preview=dip1000
 */
// https://github.com/dlang/dmd/issues/22885
// A declared `scope` on a lazy variadic array of delegates covers the
// delegates, so the caller allocates no closure for its arguments.
// https://dlang.org/spec/function.html#lazy_variadic_functions

alias Lz = int delegate() @safe pure nothrow @nogc;

@safe pure nothrow @nogc:

int sum(scope Lz[] xs...)
{
    int s;
    foreach (x; xs)
        s += x();
    return s;
}

// the issue's example
void flash(scope int delegate()[] arr...) {}
void issue() { int y; flash(++y, ++y); }

// captures
int locals(int a, int b) => sum(a, b + 1);
int byRef(ref int a) => sum(a, 2);
void byOut(out int a) { cast(void) sum(a = 1); }
int nested(int a) => sum(sum(a), 1, sum(a, sum(a)));
int nestedFn(int a)
{
    int inner() => sum(a);
    return sum(inner(), a);
}
int literals(int a) => sum(() => a, () => a + 1); // explicit delegate literals
struct S { int f; int m() => sum(f, f); }

// templates, IFTI, UFCS, named and default arguments before the variadic
T tsum(T)(scope T delegate() @safe pure nothrow @nogc [] xs...) { T s = 0; foreach (x; xs) s += x(); return s; }
int ifti(int a) => tsum!int(a, a) + tsum!int(() => a); // IFTI: dlang/dmd#19167

struct Ui { int depth; int[8] log; }
int column(return ref Ui ui, int gap = 0, bool compact = false, scope Lz[] children...)
{
    ui.depth++;
    int s = gap + compact;
    foreach (child; children)
        s += child();
    ui.depth--;
    return s;
}
int label(return ref Ui ui, int text = 0) => text + ui.depth;
int pane(ref Ui ui, int rows)
    => ui.column(gap: 1, children:
        ui.label(text: rows),
        ui.column(compact: true, children: ui.label(text: 2), ui.label()),
        ui.label());

// indirect calls: function pointers, delegates and virtual functions
int viaFp(int a)
{
    int function(scope Lz[] xs...) @safe pure nothrow @nogc fp = &sum;
    return fp(a, a);
}
int viaDg(int a)
{
    scope dg = (scope Lz[] xs...) => sum(xs);
    return dg(a, a + 1);
}
class K
{
    int f;
    int v(scope Lz[] xs...) @safe pure nothrow @nogc => sum(xs) + f;
    final int m(int a) @safe pure nothrow @nogc => v(a, f);
}
int virtualCall(K k, int a) => k.v(a);

// forwarding the array: as the array, or one delegate at a time
int forward(scope Lz[] xs...) => sum(xs) + sum(xs[1 .. $]) + sum(xs[0]());

// CTFE
static assert(sum(1, 2, 3) == 6);
static assert(() { int n; return sum(++n, ++n) * 10 + n; }() == 32);

// A declared `scope` is mangled; the implicit one of a typesafe variadic is not
int keep(Lz[] xs...) => cast(int) xs.length;
static assert(sum.mangleof == "_D9test228853sumFNaNbNiNfMADFNaNbNiNfZiXi");
static assert(keep.mangleof == "_D9test228854keepFNaNbNiNfADFNaNbNiNfZiXi");
static assert(__traits(getParameterStorageClasses, sum, 0) == AliasSeq!("scope"));
static assert(__traits(getParameterStorageClasses, keep, 0).length == 0);
alias AliasSeq(T...) = T;

// A function with a `scope` parameter converts to a type without one
static assert(is(typeof(&sum) : int function(Lz[] xs...) @safe pure nothrow @nogc));
