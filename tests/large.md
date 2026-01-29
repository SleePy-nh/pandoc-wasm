# Large Test Document

This document contains extensive content to stress-test Pandoc's WASM conversion.

## Chapter 1: Introduction

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Praesent euismod, nisl eget aliquam ultricies, nunc nisl aliquet nunc, quis aliquam nisl nisl eget nisl.

### Background

The development of WebAssembly has opened new possibilities for running complex software in browsers and serverless environments.

### Objectives

1. Test markdown to PPTX conversion
2. Validate WASM binary functionality
3. Ensure cross-platform compatibility

## Chapter 2: Technical Details

### WebAssembly Overview

WebAssembly (Wasm) is a binary instruction format for a stack-based virtual machine.

```wasm
(module
  (func $add (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.add))
```

### Pandoc Architecture

Pandoc reads various input formats and converts them to an internal representation.

| Component | Purpose |
|-----------|---------|
| Reader | Parses input format |
| AST | Internal representation |
| Writer | Outputs target format |
| Filter | Transforms content |

### WASI Compatibility

The WebAssembly System Interface provides system-level capabilities:

- File system access
- Standard I/O streams
- Environment variables
- Random number generation

## Chapter 3: Implementation

### Building from Source

The build process requires:

1. GHC WASM compiler
2. WASI SDK
3. Cabal build tool

### Patching Dependencies

Several packages required patches for WASM compatibility:

- **basement**: Fixed primitive type conversions
- **memory**: Disabled mmap, fixed FFI
- **network**: Added WASI stubs

### Compilation Flags

```bash
wasm32-wasi-cabal build pandoc-cli
```

## Chapter 4: Testing

### Unit Tests

Basic conversion tests verify core functionality.

### Integration Tests

End-to-end tests validate complete workflows.

### Performance Tests

Benchmarks measure conversion speed and memory usage.

## Chapter 5: Results

### Successful Conversions

All target formats were successfully tested:

- Markdown to HTML ✓
- Markdown to PPTX ✓
- Markdown to PDF (via LaTeX) ✓

### Binary Size

The compiled WASM binary is approximately 166MB.

### Runtime Performance

Initial load time is longer due to WASM compilation, but subsequent operations are fast.

## Chapter 6: Future Work

### Optimization

- Reduce binary size through tree-shaking
- Improve startup time with AOT compilation
- Add caching for repeated conversions

### Extended Format Support

Additional input/output formats can be enabled by:

1. Ensuring WASI compatibility
2. Testing with various inputs
3. Documenting limitations

## Conclusion

Pandoc WASM successfully compiles and runs, enabling document conversion in WASI-compatible environments.

---

## Appendix A: Code Examples

### Python

```python
import pandoc

def convert(input_file, output_format):
    doc = pandoc.read(file=input_file)
    return pandoc.write(doc, format=output_format)
```

### JavaScript

```javascript
const runPandoc = async (input, format) => {
  const wasm = await WebAssembly.instantiate(pandocWasm);
  return wasm.exports.convert(input, format);
};
```

### Haskell

```haskell
import Text.Pandoc

convert :: FilePath -> Text -> IO (Either PandocError Text)
convert path format = runIO $ do
  doc <- readMarkdown def path
  writeFormat format def doc
```

## Appendix B: Configuration

### Cabal Project Settings

```cabal
package pandoc
  flags: +embed_data_files

package pandoc-cli  
  flags: -lua -server
```

### Environment Variables

```bash
export PANDOC_DATA_DIR=/path/to/data
export PANDOC_TEMPLATES=/path/to/templates
```

## Appendix C: Troubleshooting

### Common Issues

1. **Memory limits**: Increase WASM memory allocation
2. **Missing fonts**: Embed fonts in templates
3. **Network errors**: Network is disabled in WASI

### Debug Mode

Enable verbose output:

```bash
wasmtime run --dir . pandoc.wasm -- --verbose input.md
```
