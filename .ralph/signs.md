# Signs (Lessons Learned)

> Add signs here when you encounter issues, so future agents avoid the same traps.

## Format

```
### Sign: [Short Title]
**Date**: YYYY-MM-DD
**Symptom**: What went wrong
**Root Cause**: Why it happened
**Fix**: What to do instead
```

## Signs

### Sign: Basement 0.0.16 requires extensive patching for GHC 9.4+/WASM
**Date**: 2026-01-28
**Symptom**: Build fails with "Could not find module GHC.IntWord64", type mismatches with Word32#/Word#
**Root Cause**: GHC.IntWord64 was removed in GHC 9.4+. Int64#/Word64# primitives are now in GHC.Prim. Also, Word32# and Word# are distinct types requiring explicit conversion.
**Fix**: 
1. Remove all `import GHC.IntWord64` - use GHC.Prim instead
2. Add int64/word64 primitives to explicit GHC.Prim imports where needed
3. Use wordToWord32#/word32ToWord#/int32ToInt# for conversions
4. Add `#define FOUNDATION_SYSTEM_WASM` to cbits/foundation_system.h

### Sign: digest package needs -pkg-config flag for WASM
**Date**: 2026-01-28
**Symptom**: Configure fails looking for system zlib.h
**Root Cause**: digest tries to find system zlib via pkg-config, but WASM cross-compile has no system zlib
**Fix**: Add `package digest` with `flags: -pkg-config` in cabal.project to use bundled zlib from zlib-clib
