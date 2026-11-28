/*
DISABLED: win osx linux32 freebsd32 openbsd32 netbsd32 hurd32
REQUIRED_ARGS: -vasm -inline
TEST_OUTPUT:
---
_D14push_const_arg4testFS7imports16push_const_arg_a1EZv:
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
_D14push_const_arg7testComFS7imports16push_const_arg_a1EZv:
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

// Inlining `midByte` widens -1 to int, and the backend folds that into the
// operator's node, writing only the int: the push of the argument read
// 8 bytes, the rest being the high half of an operand's address
// (`mov RAX,060A8FFFFFFFFh`).

import imports.push_const_arg_a;

void test(E e) { midByte(-1, e); }

// `~0u` folds to all 64 bits set: a 4 byte argument is pushed from its own
// bytes, sign extended, so it stays `push -1`.

void testCom(E e) { midCom(0, e); }
