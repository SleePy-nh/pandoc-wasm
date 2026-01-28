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

### Sign: Packages with Custom Setup.hs fail with threaded RTS error
**Date**: 2026-01-28
**Symptom**: Build fails with "unable to find library -lHSrts-1.0.3_thr" during configure step
**Root Cause**: Custom Setup.hs executables link with threaded RTS, which doesn't exist in WASM
**Fix**: Patch packages to use `build-type: Simple` instead of Custom. Example: xml-conduit uses Custom for doctests - change to Simple.

### Sign: Executables with -threaded fail to link on WASM
**Date**: 2026-01-28
**Symptom**: Final link fails with "unable to find library -lHSrts-1.0.3_thr"
**Root Cause**: GHC WASM doesn't have a threaded runtime system
**Fix**: Patch the cabal file to remove `-threaded` from ghc-options. Example: pandoc-cli has `-threaded` hardcoded.

### Sign: Custom Build Types Break Cross-Compilation
**Date**: 2026-01-28
**Symptom**: Error "unable to find library -lHSrts-1.0.3_thr" when building setup executable
**Root Cause**: Packages with `build-type: Custom` need their Setup.hs compiled for the HOST, not the TARGET (WASM). Cabal cross-compilation doesn't handle this correctly.
**Fix**: 
- Use packages with Simple build type when possible
- Patch packages to change Custom to Simple if they don't actually need Custom
- Look into cabal's setup-depends configuration for cross-compilation

### Sign: GHC WASM Parallel Compilation Race Conditions
**Date**: 2026-01-28
**Symptom**: Missing .dyn_o files, "does not exist (No such file or directory)" during compilation
**Root Cause**: Parallel GHC compilation on WASM cross-compiler has race conditions
**Fix**: Use `--ghc-options="-j1"` to force single-threaded compilation

### Sign: cborg 0.2.10.0 Has 32-bit Bugs
**Date**: 2026-01-28  
**Symptom**: Syntax errors in isWord64Canonical, missing GHC.IntWord64 import
**Root Cause**: cborg's 32-bit ARCH code was never tested on modern GHC; has syntax errors and uses deprecated GHC.IntWord64
**Fix**: Patch Magic.hs, Decoding.hs, Read.hs to fix conversions and remove GHC.IntWord64 imports

### Sign: crypton argon2 needs ARGON2_NO_THREADS for WASI
**Date**: 2026-01-28
**Symptom**: Error "call to undeclared function 'pthread_exit'"  
**Root Cause**: WASI doesn't support pthread_exit, but crypton's argon2 code uses pthreads
**Fix**: Add `#define ARGON2_NO_THREADS 1` at top of cbits/argon2/thread.h and thread.c for __wasi__ or __wasm__
