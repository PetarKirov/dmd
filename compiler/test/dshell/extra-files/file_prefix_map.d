module pkg.m;

string f() { return __FILE__ ~ "|" ~ __FILE_FULL_PATH__; }

int g(int[] a, size_t i)
{
    assert(i < 10, "too large");
    return a[i];
}

unittest
{
    assert(g([1, 2], 1) == 2);
}
