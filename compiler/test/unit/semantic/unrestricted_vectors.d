module semantic.unrestricted_vectors;

import std.algorithm : each;

import dmd.frontend;
import dmd.astcodegen;

import support;

@afterEach void deinitializeFrontend()
{
    deinitializeDMD();
}

private enum source = q{
    alias vec2 = __vector(float[2]);
    alias vec3 = __vector(float[3]);
    vec2 f(vec2 a, vec2 b) { return a * b + a / b - a; }
    vec3 g(vec3 a) { return -a * a; }
    struct S { vec3 v; float w; }
    static assert(S.v.alignof == 16);
};

@("target - DMD rejects 8- and 12-byte vectors")
unittest
{
    import dmd.target : target;

    initDMD();
    defaultImportPaths.each!addImport;

    auto t = parseModule!ASTCodegen("test.d", source);
    t.module_.fullSemantic();
    assert(t.diagnostics.hasErrors);
}

@("target - unrestrictedVectors accepts any vector size, sized as LLVM does")
unittest
{
    import dmd.target : target;

    initDMD();
    target.unrestrictedVectors = true;
    scope (exit) target.unrestrictedVectors = false;
    defaultImportPaths.each!addImport;

    auto t = parseModule!ASTCodegen("test.d", source);
    t.module_.fullSemantic();
    assert(!t.diagnostics.hasErrors);
}

@("frontend - initDMD predefines the requested vendor version")
unittest
{
    import dmd.globals : global;

    static bool predefined(string ident)
    {
        foreach (id; global.versionids[])
            if (id.toString() == ident)
                return true;
        return false;
    }

    initDMD(null, null, [], ContractChecks(), "LDC");
    assert(predefined("LDC"));
    assert(!predefined("DigitalMars"));
}
