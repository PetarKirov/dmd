/* TEST_OUTPUT:
---
fail_compilation/importc_tag_redeclaration.c(12): Error: redefinition of `a` with different type: `struct A` vs `struct B`
fail_compilation/importc_tag_redeclaration.c(15): Error: redefinition of `c` with different type: `struct A` vs `const struct A`
---
*/

struct A { int x; };
struct B { int x; };

extern struct A a;
extern struct B a;

extern struct A c;
extern const struct A c;
