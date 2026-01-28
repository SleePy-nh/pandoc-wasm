# Pandoc WASM Compilation

## Goal
Compile Pandoc to WebAssembly for converting Markdown to PPTX (and other formats).

## Current State
- ghc-wasm-meta: Partially installed at ~/.ghc-wasm/ - WASI SDK present but GHC WASM compiler missing
- wasmtime: Available at ~/.ghc-wasm/wasmtime/bin/wasmtime (v41.0.0)
- Target: Pandoc 3.8.3 (latest stable on Hackage)

## Criteria

### Phase 0: Complete ghc-wasm-meta Installation
- [x] Run bootstrap.sh to install GHC WASM compiler
- [x] Verify wasm32-wasi-ghc --version works (9.12.3.20251231)

### Phase 1: Project Setup and Build
- [x] Create cabal.project with WASM-compatible configuration
- [x] Run wasm32-wasi-cabal update
- [ ] Build pandoc-cli with wasm32-wasi-cabal (IN PROGRESS)

### Phase 2: Handle Dependency Failures (if needed)
- [x] Address basement WASM/GHC 9.12 compatibility (patched From.hs, OffsetSize.hs)
- [x] Address memory WASM/GHC 9.12 compatibility (patched CompatPrim64.hs, PtrMethods.hs)
- [x] Address network WASI compatibility (added stubs for getaddrinfo/getnameinfo, structs, CMSG macros)
- [x] Address digest zlib dependency (disabled pkg-config)
- [x] Address cborg 32-bit/GHC 9.12 issues (patched Magic.hs, Decoding.hs, Read.hs)
- [x] Address crypton argon2 pthread issue (added ARGON2_NO_THREADS define)
- [x] Address xml-conduit Custom build type issue (patched to Simple build type)
- [x] Address pandoc-cli threaded RTS issue (removed -threaded flag)

### Phase 3: Validation
- [x] Create test markdown files (small.md, medium.md, large.md)
- [x] pandoc.wasm binary exists (166MB - larger than expected due to embedded data)
- [x] Successfully convert small.md to PPTX (27KB)
- [x] Successfully convert medium.md to PPTX (30KB)
- [x] Successfully convert large.md to PPTX (46KB)
- [x] Output PPTX files are valid (verified with unzip -l)

## Test Command
```bash
# Verify WASM compilation produces working output
source ~/.ghc-wasm/env && wasmtime run --dir . pandoc.wasm -- -f markdown -t pptx -o test.pptx small.md
```

## Notes
- Use flags: `-lua -server` to disable problematic features
- Use `+embed_data_files` to include templates in binary
- wasmtime needs `--dir .` to access host filesystem
- No external processes or network in WASI
- Use `--ghc-options="-j1"` to avoid parallel compilation race conditions
- Packages with `build-type: Custom` are problematic for cross-compilation
  - xml-conduit uses Custom build type, causing setup linking failures
  - Next step: investigate cabal setup-depends for cross-compilation or patch xml-conduit
