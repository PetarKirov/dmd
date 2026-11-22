import dshell;

import core.thread : Thread;
import core.time : msecs;

// `-lib` wrote the time it ran and the building user's ids into each
// archive member's header, so two builds of the same sources gave
// different libraries. Built a second apart, they are now byte-identical.
void main()
{
    const lib = shellExpand("$OUTPUT_BASE/deterministic_lib$LIBEXT");
    const(ubyte)[] first;
    foreach (i; 0 .. 2)
    {
        if (i)
            Thread.sleep(1100.msecs);
        run("$DMD -m$MODEL -lib -of" ~ lib
            ~ " $EXTRA_FILES/deterministic_lib_a.d $EXTRA_FILES/deterministic_lib_b.d");
        const bytes = cast(const(ubyte)[]) std.file.read(lib);
        if (i == 0)
            first = bytes;
        else
            enforce(bytes == first, "-lib output differs between identical runs");
    }
}
