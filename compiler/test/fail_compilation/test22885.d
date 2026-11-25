/*
REQUIRED_ARGS: -preview=dip1000
TEST_OUTPUT:
---
fail_compilation/test22885.d(32): Error: assigning scope variable `xs` to global variable `g` is not allowed in a `@safe` function
fail_compilation/test22885.d(33): Error: assigning scope variable `x` to global variable `g` is not allowed in a `@safe` function
fail_compilation/test22885.d(34): Error: assigning scope variable `x` to global variable `g` is not allowed in a `@safe` function
fail_compilation/test22885.d(35): Error: returning `xs[0]` escapes a reference to variadic parameter `xs`
fail_compilation/test22885.d(36): Error: assigning scope variable `ys` to global variable `g` is not allowed in a `@safe` function
fail_compilation/test22885.d(37): Error: assigning scope variable `xs` to non-scope parameter `d` calling `take` is not allowed in a `@safe` function
fail_compilation/test22885.d(39): Error: assigning scope variable `xs` to global variable `ga` is not allowed in a `@safe` function
fail_compilation/test22885.d(39): Error: copying scope variable `xs` into allocated memory is not allowed in a `@safe` function
fail_compilation/test22885.d(40): Error: copying the `scope` delegates of `xs` into allocated memory is not allowed in a `@safe` function
fail_compilation/test22885.d(41): Error: copying scope variable `xs` into allocated memory is not allowed in a `@safe` function
fail_compilation/test22885.d(42): Error: copying the `scope` delegates of `xs` into allocated memory is not allowed in a `@safe` function
fail_compilation/test22885.d(42): Error: copying the `scope` delegates of `xs` into allocated memory is not allowed in a `@safe` function
fail_compilation/test22885.d(43): Error: copying the `scope` delegates of `xs` into non-scope `ga[]` is not allowed in a `@safe` function
fail_compilation/test22885.d(44): Error: assigning the `scope` delegates of `xs` to non-scope variadic parameter `ys` is not allowed in a `@safe` function
fail_compilation/test22885.d(46): Error: assigning scope variable `arr` to global variable `g` is not allowed in a `@safe` function
---
*/
// https://github.com/dlang/dmd/issues/22885
// A declared `scope` on a lazy variadic array covers its delegates: the caller
// keeps the frames they close over on its stack, so they must not escape.

alias Dg = int delegate() @safe;
Dg g;
Dg[] ga;

@safe:

void index(scope Dg[] xs...) { g = xs[0]; }
void loop(scope Dg[] xs...) { foreach (x; xs) g = x; }
void loopRef(scope Dg[] xs...) { foreach (ref x; xs) g = x; }
Dg ret(scope Dg[] xs...) { return xs[0]; }
void copy(scope Dg[] xs...) { auto ys = xs[1 .. $]; g = ys[0]; }
void param(scope Dg[] xs...) { take(xs[0]); }
void take(Dg d) { g = d; }
void literal(scope Dg[] xs...) { ga = [xs[0]]; }
void append(scope Dg[] xs...) { ga ~= xs; }
void appendElem(scope Dg[] xs...) { ga ~= xs[0]; }
void concat(scope Dg[] xs...) { ga = xs ~ xs; }
void sliceCopy(scope Dg[] xs...) { ga[] = xs[]; }
void forward(scope Dg[] xs...) { stash(xs); }
void stash(Dg[] ys...) { ga ~= ys; }
void plain(scope Dg[] arr) { g = arr[0]; }


// without `scope`, the delegates may escape (the caller allocates a closure)
void ok1(Dg[] xs...) { g = xs[0]; ga ~= xs; ga = xs ~ xs; ga[] = xs[]; stash(xs); }
Dg ok2(Dg[] xs...) { foreach (x; xs) g = x; return xs[0]; }
int ok3(scope Dg[] xs...) { int s; foreach (x; xs) s += x(); scope Dg d = xs[0]; return s + d() + ok3(xs[1 .. $]); }
