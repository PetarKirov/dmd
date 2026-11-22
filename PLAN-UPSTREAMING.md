# Upstreaming Plan — `dmdserver-dub`

This branch is the dub-consumable LanguageServer flavor of the DMD frontend:
`rainers/dmd@dmdserver` (the dmdserver patch set, at v2.114.0, ~120 commits ahead of
`dlang/dmd@master`) plus this fork's commits on top. Its consumers are the
`sparkles:dmd-lsp` / `sparkles:dmd-fmt` packages, which pin it by SHA as a dub
git dependency.

This file designs, plans and tracks the upstreaming of this fork's changes.
It is **fork-only** — never itself part of an upstream PR.

## Ground rules

- **Every commit on this branch must be upstreamable in form**, even when its
  content cannot land upstream yet: self-contained, one concern, an
  upstream-style message stating the defect and the fix, and — for behavior
  changes — a test in `compiler/test/unit/…`.
- **The upstream community prioritizes work that makes DMD a better
  library.** That is this branch's whole reason to exist, so changes that
  generalize (visibility for library consumers, packaging fixes, DMDLIB
  fidelity fixes, global-state reduction) should be written for
  `dlang/dmd@master` first and merged down, not written against this branch's
  idiosyncrasies.
- **Three targets**, one per change:
  - `dlang/dmd` — the defect/gap exists on master; PR upstream directly.
  - `rainers/dmdserver` — the change fixes or extends the
    `version(LanguageServer)` / `version(GC)` patch set; PR to rainers, whose
    branch is itself the candidate for eventual upstreaming.
  - fork-only — dub-packaging glue that only makes sense for this branch;
    kept minimal so rebases stay cheap.
- **A merged change is a dropped change**: on the next rebase over its target,
  the fork commit disappears. The table below is expected to shrink.

## Branch topology

```
dlang/dmd @ master
  └─ rainers/dmd @ dmdserver      (+~121: version(GC) server GC,
     │                             version(LanguageServer) patch set)
     └─ PetarKirov/dmd @ dmdserver-dub   (this branch: dub packaging +
                                          library fixes, tracked below)
```

The fork has two more kinds of branch, both on `dlang/dmd@master`:

- **One branch per `dlang/dmd` change** (`fix/…`), the branch its PR is opened
  from. A row targeting `dlang/dmd` is written there first and merged down
  here, so its PR never carries the dmdserver patch set.
- **`sparkles/main`**: master plus the `dlang/dmd` changes the sparkles
  toolchain needs before upstream has them (reproducible output), the compiler
  sparkles builds. Like LDC's `PetarKirov/ldc@sparkles/main`, it is rebased
  onto master and sheds each change once merged.

## Tracked changes

Status: `idea` → `committed` (here) → `PR` (link) → `merged` → dropped on
rebase.

| #   | Change                                                                                                                                                                                    | Commit       | Target             | Status    | Notes                                                                                                                                                                                                                              |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | ------------------ | --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `root.aav`: typed keys from `asRange` under `version(GC)`                                                                                                                                  | `f568c8182d` | rainers/dmdserver  | committed | `version(GC)` exists only in the dmdserver patch set; the fix restores the non-GC implementation's typed pairs. Ready to PR as-is.                                                                                                   |
| 2   | `doc.d`: expose the per-symbol ddoc machinery for library use                                                                                                                              | `cfe48eef1e` | dlang/dmd          | committed | Visibility-only. The upstream framing: a language server needs to render one declaration's doc comment; everything below doc.d's `private:` is unreachable. Expect design discussion (public vs `package(dmd)` vs a narrow facade). |
| 4   | `parse.d`: keep documented-unittest bodies outside the root module                                                                                                                         | `68b32e19c1` | rainers/dmdserver  | committed | LS-gated today. The capability (documented unittest bodies for imported modules) benefits any doc tool; a later `dlang/dmd` proposal could de-gate it behind a `Param` flag.                                                        |
| 5   | dub: drop `astbase.d` from `dmd:parser`                                                                                                                                                    | `706ea87c3d` | fork-only          | committed | A consequence of LS gating (the patch set does not cover astbase's call sites). The upstream-shaped alternative is extending the LS patch set to cover `astbase.d` (rainers), which would delete this commit.                        |
| 6   | dub: enable `LanguageServer` in the library subpackages                                                                                                                                    | `9b8950e7dc` | fork-only          | committed | The branch's raison d'être; upstreamable only if/when the LS patch set itself lands upstream.                                                                                                                                       |
| 8   | `lexer.d`: DMDLIB `commentToken` desync on U+2028/U+2029-terminated `//` comments — the scanner is left mid-sequence (non-DMDLIB advances past the terminator; the DMDLIB return does not) | `c4a65297d3` | dlang/dmd          | committed | Found by `sparkles:dmd-fmt`'s round-trip spike (pinned there by a known-fault test). Bug present on master. Fix + `compiler/test/unit/lexer/lexer_dmdlib.d` coverage.                                                               |
| 9   | `lexer.d`: DMDLIB `whitespaceToken` never fires for bare U+2028/U+2029 — the LS/PS arm skips the `whitespaceToken` block every other whitespace arm has, silently consuming the bytes      | `c4a65297d3` | dlang/dmd          | committed | Same spike; breaks full-fidelity lexing (DMDLIB's stated purpose for the flag). Fix mirrors the `'\n'` arm.                                                                                                                        |
| 10  | dub: `dmd:lexer` does not link standalone — `identifier.d` references `dmd.rootobject`/`dmd.astenums`, compiled only by `dmd:frontend`                                                     | `fe25ba39e3` | dlang/dmd + fork   | committed | Upstream's `dmd:lexer` also lacks `rootobject.d` (its list does have `astenums.d`). Upstream part: add `rootobject.d`. Fork part: also restore `astenums.d` and stop compiling both in `dmd:frontend`, killing two downstream link workarounds (`sparkles:dmd-lsp`'s `--undefined` lflags, `sparkles:dmd-fmt`'s ClassInfo anchor). |
| 11  | `target.d`: `Target.unrestrictedVectors` — LLVM's vector rules at runtime (any size, LDC's op table, power-of-two `alignsize`, SysV partial eightbyte) | `b519d956f9` | dlang/dmd | committed | The runtime counterpart of LDC's `static if (!IN_LLVM)` switches, so a tool can analyze LDC code with the DMD-built frontend. Driven by `sparkles:dmd-lsp`'s dcompute/shader analysis (`__vector(float[2|3])`). `compiler/test/unit/semantic/unrestricted_vectors.d`. |
| 12  | `frontend.d`: `initDMD(…, vendorVersion, configureParams)` — pick the predefined vendor identifier; set params before predefines are derived | `5c18ba5ba7` | dlang/dmd | committed | Today `LDC` is rejected as reserved and `D_BetterC` can never be predefined through the library API. Defaulted trailing params: no behavior change for existing callers. Same unit-test file. |
| 13  | dub: exclude native assembler implementations and the driver C preprocessor from `dmd:frontend`; remove `mars.d`'s unused preprocessor import | `2cb16382bd` | dlang/dmd + fork | committed | `NoBackend` excludes native assembler dispatch, not independently compiled source files. DMD coverage registration retains these files and their references to excluded `backend.iasm`, `backend.ptrntab`, and `link.d`. Keep `iasm/package.d` and the `global.preprocess` hook; the compiler package still includes the real implementations. |
| 14  | `lib/{elf,mach,mscoff}.d`: `-lib` writes reproducible libraries — zero time, owner and group in every member header, as `llvm-ar` does by default | `e290e20084` (`fix/deterministic-lib`) | dlang/dmd | committed | sparkles#760: `dmd -lib` stamped each member with `time()` and the builder's uid/gid, so no two builds matched. On `sparkles/main`, not this branch (the compiler, not the library). `compiler/test/dshell/deterministic_lib.d`. No upstream issue yet. |
| 15  | `-ffile-prefix-map=OLD=NEW`: map source paths in `__FILE__`, `__FILE_FULL_PATH__`, debug information (DWARF `comp_dir`, file names), the ELF file symbol and `-cov` | | dlang/dmd | idea | sparkles#760 and sparkles D19: DMD records absolute paths (the generated test root's, the working directory under `-g`), so its outputs differ between run directories and worktrees. Same option and semantics as LDC's and GCC's. |

## Done

- **`expression.d`: complete the LanguageServer `typeInfoExp` table** (was row
  3). Superseded by rainers/dmdserver at v2.114.0, which generates the table
  from `ExpOpTypePairs`, the list `expSize` is built from, so the two cannot
  drift apart. Dropped when rebasing onto it.
- **dub: exclude `glue/*` from `dmd:frontend` like mainline** (was row 7).
  Mainline's exclusion; the commit became empty on the same rebase.

## Findings to raise upstream as issues/design work (not patches yet)

These are library-quality gaps found by `sparkles:dmd-fmt`'s spikes. Each
deserves an upstream conversation before any patch, because the right fix is
a design decision about DMD-as-a-library:

- **Lexer output is a function of hidden global state.** The
  special-identifier handling (`__EOF__` → `TOK.endOfFile`, `__DATE__`
  rewrites, `#line` recognition in `parseSpecialTokenSequence`) compares
  against `dmd.id.Id` globals: an uninitialized process gets a *materially
  different token stream* (lexing runs past `__EOF__`) with no error. A
  standalone `Lexer` should either not depend on `Id.initialize()` or assert
  that it ran.
- **The lexer is not usable concurrently.** `Identifier.idPool`'s string
  table is process-global and unsynchronized; two threads lexing
  independently segfault. Any multi-document library consumer (an LSP) must
  serialize all lexing. Thread-safe or per-instance identifier tables are a
  prerequisite for DMD as a serious library.
- **`commentToken` and `doDocComment` cannot be combined.** Every comment arm
  returns the `TOK.comment` before the `doDocComment` branch runs, so a
  full-fidelity consumer that also wants the compiler's ddoc attachment must
  lex twice. Either document the exclusivity or populate
  `blockComment`/`lineComment` alongside `commentToken`.

## Process

1. New fork commits land here first, upstreamable in form (see ground
   rules), and get a row (or update one) in the table above in the same
   commit.
2. PRs go to the row's target; the row's Status column carries the PR link.
3. After a merge, the next rebase drops the commit and the row moves to a
   short "Done" list (or is deleted once the branch no longer carries it).
4. Rebase cadence follows the `sparkles` pin-upgrade procedure
   (`docs/specs/dmd-lsp/`, BLD1/BLD2 in that repository).
