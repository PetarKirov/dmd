// A default argument's explicit cast survives its copy at each call: with an
// enum based on the cast expression's type, the cast only repaints the type,
// and the copied argument used to be checked as the uncast expression
// ("cannot implicitly convert expression `g()` of type `int` to `E`").

enum E : int { a, b }

int g() { return 1; }
ref int r() { static int x; return x; }

void f(E e = cast(E) g()) {}
void fr(string s = "", E e = cast(E) r()) {}

struct S
{
    E e;
    void m(E err = cast(E) g()) { e = err; }
}

void main()
{
    f();
    fr();
    fr("x");
    S s;
    s.m();
}
