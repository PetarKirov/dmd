module imports.push_const_arg_a;

struct E {}

void sinkInt(int v, E e, long a, long b, long c, long d, long f, long g);

void midByte(byte depth, E e) { sinkInt(depth, e, 0, 0, 0, 0, 0, 0); }

void sinkUint(uint v, E e, long a, long b, long c, long d, long f, long g);

void midCom(uint x, E e) { sinkUint(~x, e, 0, 0, 0, 0, 0, 0); }
