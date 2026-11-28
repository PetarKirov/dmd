module imports.fold_const_push_a;

struct E {}

void sink(ubyte depth, E e, long a, long b, long c, long d, long f, long g);

void mid(ubyte depth, E e) { sink(depth, e, 0, 0, 0, 0, 0, 0); }
