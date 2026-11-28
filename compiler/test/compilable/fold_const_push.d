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
_D15fold_const_push7testNegFS7imports17fold_const_push_a1EZv:
$r:[^\n]*$
$r:[^\n]*$
0004:   6A FF                    push      0FFFFFFFFh
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
_D15fold_const_push7testComFS7imports17fold_const_push_a1EZv:
$r:[^\n]*$
$r:[^\n]*$
0004:   6A FF                    push      0FFFFFFFFh
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

// The widening of -1 writes only `Vint`, so the upper bytes are not its sign:
// the push reads the int, not 8 bytes (`mov EAX,0FFFFFFFFh` `push RAX`).

void testNeg(E e) { midByte(-1, e); }

// `~0u` folds to all 64 bits set: a 4 byte argument is pushed from its own
// bytes, sign extended, so it stays `push -1`.

void testCom(E e) { midCom(0, e); }
