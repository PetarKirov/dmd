module lib;

struct Interval(V) { V lower, upper; }

struct Ranges(V)
{
    Interval!V[] segs;
    static Ranges make(V a) { return Ranges([Interval!V(a, a)]); }
}

struct U3
{
    uint v;
    bool opEquals(in U3 o) const => v == o.v;
    size_t toHash() const => v;
}

// Only a -unittest build of an importer analyzes it
version (unittest) Ranges!U3 corpus() { return Ranges!U3.make(U3(1)); }
