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
- [x] Address basement WASM/GHC 9.12 compatibility (patched)
- [x] Address digest zlib dependency (disabled pkg-config)
- [ ] Address any remaining dependency issues (monitoring)

### Phase 3: Validation
- [ ] Create test markdown files (small.md, medium.md, large.md)
- [ ] pandoc.wasm binary exists (expect 50-100MB)
- [ ] Successfully convert small.md to PPTX
- [ ] Successfully convert medium.md to PPTX
- [ ] Successfully convert large.md to PPTX
- [ ] Output PPTX files are valid

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
