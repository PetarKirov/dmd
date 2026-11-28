/*
DISABLED: win osx linux32 freebsd32 openbsd32 netbsd32 hurd32
REQUIRED_ARGS: -vasm -inline
TEST_OUTPUT:
---
_D15fold_const_push4testFS7imports17fold_const_push_a1EZv:
$r:[^\n]*$
$r:[^\n]*$
0004:   6A 03                    push      3
0006:   FF 75 10                 push      dword ptr 010h[RBP]
$r:[^\n]*$
$r:[^\n]*$
$r:[^\n]*$
$r:[^\n]*$
$r:[^\n]*$
$r:[^\n]*$
$r:[^\n]*$
$r:[^\n]*$
$r:[^\n]*$
$r:[^\n]*$
---
*/

// Inlining `mid` widens the argument 3, cast to `ubyte`, with OPu8_16, and the
// backend folds that widening into the operator's own node, writing only `Vint`.
// The node's constant shares its union with the operands' pointers, so the
// upper bytes kept the high half of E1's address, and the 8 byte push of
// `depth` carried them (`mov RAX,05D8200000003h`): the object file differed
// between compilations.

import imports.fold_const_push_a;

void test(E e) { mid(3, e); }
