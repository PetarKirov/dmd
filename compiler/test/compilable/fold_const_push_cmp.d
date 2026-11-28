/*
DISABLED: win osx linux32 freebsd32 openbsd32 netbsd32 hurd32
REQUIRED_ARGS: -vasm -O
TEST_OUTPUT:
---
_D19fold_const_push_cmp4testFiS7imports21fold_const_push_cmp_a1EZv:
$r:[^\n]*$
$r:[^\n]*$
0004:   6A 01                    push      1
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

// Every definition reaching `a != 9` makes it true, and the optimizer replaces
// the comparison with the constant 1 in place, writing only `Vint` after freeing
// the operands: the pushed `bool` carried the high half of E1's address
// (`mov RAX,0570700000001h`).

import imports.fold_const_push_cmp_a;

void test(int k, E e)
{
    int a;
    if (k) a = 5; else a = 7;
    sinkBool(a != 9, e, 0, 0, 0, 0, 0, 0);
}
