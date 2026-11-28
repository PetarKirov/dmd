module imports.fold_const_push_a;

struct E {}

void sink(ubyte depth, E e, long a, long b, long c, long d, long f, long g);

void mid(ubyte depth, E e) { sink(depth, e, 0, 0, 0, 0, 0, 0); }

void sinkBool(bool r, E e, long a, long b, long c, long d, long f, long g);

void sinkInt(int v, E e, long a, long b, long c, long d, long f, long g);

void midByte(byte depth, E e) { sinkInt(depth, e, 0, 0, 0, 0, 0, 0); }

void sinkUint(uint v, E e, long a, long b, long c, long d, long f, long g);

void midCom(uint x, E e) { sinkUint(~x, e, 0, 0, 0, 0, 0, 0); }
