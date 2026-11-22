// A variable of a tagged type may be declared more than once, as a header
// and the file that includes it both do: generated Wayland protocol code
// declares `extern const struct wl_interface x;` in each.

struct S { int x; };
union U { int i; float f; };
enum E { e0, e1 };

extern struct S s;
extern struct S s;
struct S s = { 1 };

extern const struct S cs;
extern const struct S cs;
const struct S cs = { 2 };

extern union U u;
extern union U u;

extern enum E e;
extern enum E e;

struct Fwd;
extern const struct Fwd fwd;
struct Fwd { int y; };
extern const struct Fwd fwd;
