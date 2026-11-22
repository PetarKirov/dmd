import dshell;

import std.algorithm.searching : canFind;

// -ffile-prefix-map: the same sources, built in two directories, give the
// same object, naming neither directory: in `__FILE__`, `__FILE_FULL_PATH__`,
// the file names of failed assertions and bounds errors, -cov's registration
// and the debug information.
void main()
{
    version (Windows)
        return; // CodeView is mapped too, but this test spells POSIX paths

    const(ubyte)[][2] objects;
    foreach (i, dir; ["one", "second-dir"])
    {
        const root = shellExpand("$OUTPUT_BASE/" ~ dir);
        mkdirRecurse(root ~ "/src/pkg");
        copy(shellExpand("$EXTRA_FILES/file_prefix_map.d"), root ~ "/src/pkg/m.d");
        const obj = root ~ "/m" ~ shellExpand("$OBJ");
        run("$DMD -m$MODEL -c -g -cov -unittest -checkaction=context"
            ~ " -ffile-prefix-map=" ~ root ~ "=. -of" ~ obj ~ " " ~ root ~ "/src/pkg/m.d");
        objects[i] = cast(const(ubyte)[]) std.file.read(obj);
        enforce(!(cast(const(char)[]) objects[i]).canFind(root), "the object names " ~ root);
    }
    enforce(objects[0] == objects[1], "the objects differ between the two directories");
}
