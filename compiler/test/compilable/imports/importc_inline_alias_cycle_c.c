// See compilable/importc_inline_alias_cycle.d

static inline int twice(int x) { return 2 * x; }
int use(int x) { return twice(x); }
