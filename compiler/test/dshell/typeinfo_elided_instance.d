/* A struct instance whose codegen is elided in this object file (its module is
 * not a root) still gets its TypeInfo here when an instance emitted here needs
 * it: `_d_arrayliteralTX!(Interval!U3)`, emitted under -allinst for the array
 * literal in `Ranges!U3.make`, which only the importer's -unittest build
 * analyzes. The TypeInfo points at `Interval!U3`'s `__xopEquals` and
 * `__xtoHash`; the library, built without -unittest, has no `Interval!U3`, so
 * they must be emitted along with the TypeInfo, or the link fails.
 */
import dshell;

int main()
{
    const dir = "$EXTRA_FILES/typeinfo_elided_instance";
    const lib = "$OUTPUT_BASE/typeinfo_elided_instance_lib$LIBEXT";
    run("$DMD -m$MODEL -lib -of" ~ lib ~ " " ~ dir ~ "/lib.d");
    run("$DMD -m$MODEL -unittest -allinst -I" ~ dir ~ " -of$OUTPUT_BASE/typeinfo_elided_instance$EXE "
        ~ dir ~ "/app.d " ~ lib);
    return 0;
}
