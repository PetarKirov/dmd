/**
 * Map source path prefixes in what the compiler emits (`-ffile-prefix-map`).
 *
 * A path the compiler writes into its output — `__FILE__`, `__FILE_FULL_PATH__`,
 * the file names of failed asserts, bounds errors and coverage, and debug
 * information, the working directory included — is written with its prefix
 * replaced, so builds of the same sources in different directories produce the
 * same output. The files the compiler reads and writes are not affected, and
 * neither are its diagnostics.
 *
 * As in GCC and LDC, a prefix matches textually, without regard to path
 * components, and the mapping given last wins.
 *
 * Copyright:   Copyright (C) 1999-2026 by The D Language Foundation, All Rights Reserved
 * License:     $(LINK2 https://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
 * Source:      $(LINK2 https://github.com/dlang/dmd/blob/master/compiler/src/dmd/common/prefixmap.d, common/_prefixmap.d)
 * Documentation: https://dlang.org/phobos/dmd_common_prefixmap.html
 * Coverage:    https://codecov.io/gh/dlang/dmd/src/master/compiler/src/dmd/common/prefixmap.d
 */
module dmd.common.prefixmap;

import core.stdc.stdlib : malloc;
import core.stdc.string : memcpy, strlen;

nothrow:

private struct PrefixMapping
{
    const(char)[] old;
    const(char)[] new_;
}

private __gshared PrefixMapping[] mappings;

/**
 * Add a mapping: paths starting with `old` are emitted starting with `new_`.
 * Params:
 *   old = the prefix to replace
 *   new_ = its replacement
 */
void addFilePrefixMap(const(char)[] old, const(char)[] new_)
{
    mappings ~= PrefixMapping(old, new_);
}

/**
 * Parse `OLD=NEW`, the argument of `-ffile-prefix-map`, and add the mapping.
 * Params:
 *   arg = `OLD=NEW`; `OLD` may not contain `=`
 * Returns: whether `arg` holds a `=`
 */
bool addFilePrefixMap(const(char)[] arg)
{
    foreach (i, c; arg)
        if (c == '=')
        {
            addFilePrefixMap(arg[0 .. i], arg[i + 1 .. $]);
            return true;
        }
    return false;
}

/// Remove every mapping.
void clearFilePrefixMaps()
{
    mappings = null;
}

/**
 * Map `path` as the compiler emits it.
 * Params:
 *   path = a path the compiler is about to write into its output
 * Returns: `path` with the prefix of the last matching mapping replaced, or
 *   `path` itself when none matches
 */
const(char)[] remapFilePrefix(return scope const(char)[] path)
{
    foreach_reverse (ref m; mappings)
        if (path.length >= m.old.length && path[0 .. m.old.length] == m.old)
            return m.new_ ~ path[m.old.length .. $];
    return path;
}

/// ditto, for a zero-terminated path; a mapped one is newly allocated.
const(char)* remapFilePrefix(return scope const(char)* path)
{
    if (!path || !mappings.length)
        return path;
    const p = path[0 .. strlen(path)];
    const r = remapFilePrefix(p);
    if (r.ptr == p.ptr)
        return path;
    auto z = cast(char*) malloc(r.length + 1);
    memcpy(z, r.ptr, r.length);
    z[r.length] = 0;
    return z;
}

unittest
{
    scope (exit) clearFilePrefixMaps();

    // A literal converts to either overload: name the slice one.
    static const(char)[] remap(const(char)[] path) => remapFilePrefix(path);

    assert(remap("/src/a.d") == "/src/a.d");

    addFilePrefixMap("/src", ".");
    assert(remap("/src/a.d") == "./a.d");
    assert(remap("/srcb/a.d") == "./b/a.d"); // textual, as in GCC
    assert(remap("/other/a.d") == "/other/a.d");

    // The mapping given last wins.
    assert(addFilePrefixMap("/src/gen=generated"));
    assert(remap("/src/gen/m.d") == "generated/m.d");
    assert(remap("/src/a.d") == "./a.d");

    // Zero-terminated paths: unmapped ones come back as they are.
    const(char)* unmapped = "/other/a.d";
    assert(remapFilePrefix(unmapped) is unmapped);
    const mapped = remapFilePrefix("/src/a.d".ptr);
    assert(mapped[0 .. strlen(mapped)] == "./a.d");

    assert(!addFilePrefixMap("no-equals"));
}
