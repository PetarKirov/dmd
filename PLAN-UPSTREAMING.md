# Upstreaming Plan — `dmdserver-dub`

This branch is the dub-consumable LanguageServer flavor of the DMD frontend:
`rainers/dmd@dmdserver` (the dmdserver patch set, ~121 commits ahead of
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

## Tracked changes

Status: `idea` → `committed` (here) → `PR` (link) → `merged` → dropped on
rebase.

| #   | Change                                                                                                                                                                                    | Commit       | Target             | Status    | Notes                                                                                                                                                                                                                              |
| --- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------ | ------------------ | --------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | `root.aav`: typed keys from `asRange` under `version(GC)`                                                                                                                                  | `8fea76c042` | rainers/dmdserver  | committed | `version(GC)` exists only in the dmdserver patch set; the fix restores the non-GC implementation's typed pairs. Ready to PR as-is.                                                                                                   |
| 2   | `doc.d`: expose the per-symbol ddoc machinery for library use                                                                                                                              | `5ab681e9d7` | dlang/dmd          | committed | Visibility-only. The upstream framing: a language server needs to render one declaration's doc comment; everything below doc.d's `private:` is unreachable. Expect design discussion (public vs `package(dmd)` vs a narrow facade). |
| 3   | `expression.d`: complete the LanguageServer `typeInfoExp` table                                                                                                                            | `75cc02845a` | rainers/dmdserver  | committed | Fixes LS-gated code (13 ops behind `expSize`; `EXP.interpolated` crashed the server). Consider adding a drift guard (static assert over `expSize`) so the hand-written table cannot fall behind again.                              |
| 4   | `parse.d`: keep documented-unittest bodies outside the root module                                                                                                                         | `ea88375142` | rainers/dmdserver  | committed | LS-gated today. The capability (documented unittest bodies for imported modules) benefits any doc tool; a later `dlang/dmd` proposal could de-gate it behind a `Param` flag.                                                        |
| 5   | dub: drop `astbase.d` from `dmd:parser`                                                                                                                                                    | `f0d906d555` | fork-only          | committed | A consequence of LS gating (the patch set does not cover astbase's call sites). The upstream-shaped alternative is extending the LS patch set to cover `astbase.d` (rainers), which would delete this commit.                        |
| 6   | dub: enable `LanguageServer` in the library subpackages                                                                                                                                    | `bde0e8accc` | fork-only          | committed | The branch's raison d'être; upstreamable only if/when the LS patch set itself lands upstream.                                                                                                                                       |
| 7   | dub: exclude `glue/*` from `dmd:frontend` like mainline                                                                                                                                    | `1830250968` | (already upstream) | merged    | A sync commit — mainline already has the exclusion. Drops on the next rebase.                                                                                                                                                       |
| 8   | `lexer.d`: DMDLIB `commentToken` desync on U+2028/U+2029-terminated `//` comments — the scanner is left mid-sequence (non-DMDLIB advances past the terminator; the DMDLIB return does not) | `21a89a5368` | dlang/dmd          | committed | Found by `sparkles:dmd-fmt`'s round-trip spike (pinned there by a known-fault test). Bug present on master. Fix + `compiler/test/unit/lexer/lexer_dmdlib.d` coverage.                                                               |
| 9   | `lexer.d`: DMDLIB `whitespaceToken` never fires for bare U+2028/U+2029 — the LS/PS arm skips the `whitespaceToken` block every other whitespace arm has, silently consuming the bytes      | `21a89a5368` | dlang/dmd          | committed | Same spike; breaks full-fidelity lexing (DMDLIB's stated purpose for the flag). Fix mirrors the `'\n'` arm.                                                                                                                        |
| 10  | dub: `dmd:lexer` does not link standalone — `identifier.d` references `dmd.rootobject`/`dmd.astenums`, compiled only by `dmd:frontend`                                                     | `d807e7a579` | dlang/dmd + fork   | committed | Upstream's `dmd:lexer` also lacks `rootobject.d` (its list does have `astenums.d`). Upstream part: add `rootobject.d`. Fork part: also restore `astenums.d` and stop compiling both in `dmd:frontend`, killing two downstream link workarounds (`sparkles:dmd-lsp`'s `--undefined` lflags, `sparkles:dmd-fmt`'s ClassInfo anchor). |

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
