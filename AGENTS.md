# AGENTS.md — Guidelines for WASM Binary Wrapper Ruby Gems

This document describes the architecture and conventions for Ruby gems that wrap a
WebAssembly binary (executed via a WASI runtime like wasmtime). It is meant to be
copied and adapted for each new gem of this kind.

---

## 1. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Gem name | `<tool>_wasm` (snake_case) | `pandoc_wasm` |
| Module name | `<Tool>Wasm` (PascalCase) | `PandocWasm` |
| Binary asset | `<tool>.wasm` | `pandoc.wasm` |
| GitHub repo | `<owner>/<tool>-wasm` | `NathanHimpens/pandoc-wasm` |

---

## 2. File Layout

```
lib/
  <tool>_wasm.rb              # Main entry point — module configuration + public API
  <tool>_wasm/
    version.rb                # VERSION constant
    downloader.rb             # Downloads the .wasm binary from GitHub Releases
    runner.rb                 # Wraps the WASI runtime system call
test/
  test_helper.rb              # Minitest bootstrap + module state reset helper
  <tool>_wasm_test.rb         # Tests for main module (config, delegation, introspection)
  runner_test.rb              # Tests for Runner (command building, errors, result)
  downloader_test.rb          # Tests for Downloader (signature, errors, path expansion)
  integration_test.rb         # Full user workflow scenario (configure, download, run)
<tool>_wasm.gemspec           # Gem specification
Rakefile                      # rake test runs test/**/*_test.rb via Minitest
AGENTS.md                     # This file — reusable guidelines
```

---

## 3. Public API Contract

Every gem MUST expose exactly these public methods on the top-level module:

### Configuration

```ruby
# Get / set the absolute path where the .wasm binary lives.
# Defaults to lib/<tool>_wasm/<tool>.wasm inside the installed gem.
<Tool>Wasm.binary_path            # => String
<Tool>Wasm.binary_path = "/path"  # setter

# Get / set the WASI runtime executable name.
# Defaults to "wasmtime".
<Tool>Wasm.runtime                # => String
<Tool>Wasm.runtime = "wasmer"     # setter
```

### Download

```ruby
# Download the .wasm binary from the latest GitHub Release to `binary_path`.
# Creates intermediate directories if needed.
# Returns true on success, raises on failure.
<Tool>Wasm.download_to_binary_path!
```

### Execution

```ruby
# Run the wasm binary. All positional arguments are passed through to the binary.
# Translates to:
#   <runtime> run --dir <wasm_dir> <binary_path> <args...>
#
# Returns a Hash: { stdout: String, stderr: String, success: Boolean }
# Raises BinaryNotFound if the binary is missing at binary_path.
# Raises ExecutionError (with stderr) on non-zero exit code.
<Tool>Wasm.run(*args, wasm_dir: ".")
```

### Introspection

```ruby
# Returns true if the binary exists at binary_path.
<Tool>Wasm.available?
```

---

## 4. Error Classes

Define these inside the module:

```ruby
module <Tool>Wasm
  class Error < StandardError; end
  class BinaryNotFound < Error; end
  class ExecutionError < Error; end
end
```

- `BinaryNotFound` — raised when `run` is called but the binary does not exist.
- `ExecutionError` — raised when the WASI runtime exits with a non-zero status.
  The error message MUST include the stderr output.

---

## 5. Module Implementation Pattern

The main module file (`lib/<tool>_wasm.rb`) must follow this structure:

```ruby
# frozen_string_literal: true

require_relative '<tool>_wasm/version'
require_relative '<tool>_wasm/downloader'
require_relative '<tool>_wasm/runner'

module <Tool>Wasm
  class Error < StandardError; end
  class BinaryNotFound < Error; end
  class ExecutionError < Error; end

  DEFAULT_BINARY_PATH = File.join(File.dirname(__FILE__), '<tool>_wasm', '<tool>.wasm').freeze

  class << self
    attr_writer :binary_path, :runtime

    def binary_path
      @binary_path || DEFAULT_BINARY_PATH
    end

    def runtime
      @runtime || 'wasmtime'
    end

    def download_to_binary_path!
      Downloader.download(to: binary_path)
    end

    def run(*args, wasm_dir: '.')
      Runner.run(*args, wasm_dir: wasm_dir)
    end

    def available?
      File.exist?(binary_path)
    end
  end
end
```

---

## 6. Downloader Implementation Pattern

The downloader (`lib/<tool>_wasm/downloader.rb`) must:

1. Accept a `to:` keyword argument — the absolute path where the binary will be written.
2. Fetch the latest release tag from the GitHub API (`/repos/:owner/:repo/releases/latest`).
3. Find the asset named `<tool>.wasm` in the release.
4. Stream-download the asset to the target path.
5. `chmod 0755` the downloaded file.
6. Create intermediate directories with `FileUtils.mkdir_p`.
7. Clean up partial files on failure (`FileUtils.rm_f`).
8. Use only Ruby stdlib (`net/http`, `json`, `fileutils`, `uri`) — no external dependencies.

Constants to adapt per gem:

```ruby
REPO_OWNER = '<github_owner>'
REPO_NAME  = '<tool>-wasm'
ASSET_NAME = '<tool>.wasm'
```

---

## 7. Runner Implementation Pattern

The runner (`lib/<tool>_wasm/runner.rb`) must:

1. Use `Open3.capture3` for proper stdout/stderr/status capture.
2. Build the command array (NOT a shell string) for safety:
   ```ruby
   cmd = [
     <Tool>Wasm.runtime,
     'run',
     '--dir', wasm_dir,
     <Tool>Wasm.binary_path,
     *args
   ]
   ```
3. Raise `BinaryNotFound` before executing if `binary_path` does not exist.
4. Raise `ExecutionError` with stderr content if exit status is non-zero.
5. Return `{ stdout:, stderr:, success: }` on success.

---

## 8. Gemspec Conventions

- `required_ruby_version >= 2.7.0`
- No external runtime dependencies — only Ruby stdlib.
- Use `git ls-files` to determine included files; exclude build artifacts, tests,
  CI configs, patches, and agent working directories.
- Include a `post_install_message` explaining that the .wasm binary will be
  downloaded on first use or via `download_to_binary_path!`.

---

## 9. Adapting for a New Binary

To create a new gem for a different WASM binary:

1. Copy the `lib/` directory structure.
2. Rename all files: replace `pandoc_wasm` with `<tool>_wasm`.
3. Rename the module: replace `PandocWasm` with `<Tool>Wasm`.
4. Update these constants in `downloader.rb`:
   - `REPO_OWNER`
   - `REPO_NAME`
   - `ASSET_NAME`
5. Update `version.rb` with the new gem version.
6. Update the gemspec metadata (name, description, homepage, etc.).
7. If the WASI runtime needs additional flags (e.g. `--mapdir`, `--env`),
   add them as configurable options on the module and pass them through in the runner.

---

## 10. Testing Strategy

Tests use **Minitest** (stdlib, no extra dependency) and run with `rake test`.
The Rakefile expects `test/**/*_test.rb`.

### 10.1 Test Helper — Module State Reset

Because the module stores configuration in instance variables (`@binary_path`,
`@runtime`), every test file MUST include a helper that saves and restores state:

```ruby
# test/test_helper.rb
require 'minitest/autorun'
require 'tmpdir'
require 'fileutils'
require_relative '../lib/<tool>_wasm'

module <Tool>WasmTestHelper
  def setup
    @original_binary_path = <Tool>Wasm.instance_variable_get(:@binary_path)
    @original_runtime     = <Tool>Wasm.instance_variable_get(:@runtime)
  end

  def teardown
    <Tool>Wasm.instance_variable_set(:@binary_path, @original_binary_path)
    <Tool>Wasm.instance_variable_set(:@runtime,     @original_runtime)
  end
end
```

Every test class includes it: `include <Tool>WasmTestHelper`.

### 10.2 Stubbing Conventions

- **Runner tests**: Stub `Open3.capture3` with a lambda to capture the command
  array without actually executing anything. Return `[stdout, stderr, status]`
  where `status` is a `Minitest::Mock` responding to `success?` (and
  `exitstatus` on the failure path).
- **Downloader tests**: Stub the private class methods `get_latest_release_tag`
  and `download_asset` to avoid real HTTP calls.
- **Main module tests**: Stub `Downloader.download` and `Runner.run` to verify
  delegation without side effects.

### 10.3 Fake Binary Pattern

When a test needs the binary to exist (Runner tests), create a temp file:

```ruby
Dir.mktmpdir do |dir|
  binary = File.join(dir, '<tool>.wasm')
  File.write(binary, 'fake')
  <Tool>Wasm.binary_path = binary
  # ... test logic ...
end
```

### 10.4 Test Checklist

When modifying or creating a gem of this type, the test suite MUST cover:

**Main module (`test/<tool>_wasm_test.rb`)**:
- [ ] `binary_path` returns the default path when not configured
- [ ] `binary_path =` overrides the path
- [ ] `runtime` returns `"wasmtime"` by default
- [ ] `runtime =` overrides the runtime
- [ ] `available?` returns `false` when binary is missing
- [ ] `available?` returns `true` when binary exists
- [ ] Error class hierarchy: `BinaryNotFound < Error < StandardError`
- [ ] `VERSION` matches semver format
- [ ] `download_to_binary_path!` delegates to `Downloader.download(to: binary_path)`
- [ ] `run` delegates to `Runner.run` with all arguments forwarded

**Runner (`test/runner_test.rb`)**:
- [ ] Raises `BinaryNotFound` when binary does not exist
- [ ] Builds the correct command array: `[runtime, "run", "--dir", wasm_dir, binary, *args]`
- [ ] Uses the configured `runtime` in the command
- [ ] Returns `{ stdout:, stderr:, success: true }` on success
- [ ] Raises `ExecutionError` with exit status and stderr on failure
- [ ] Defaults `wasm_dir` to `"."`

**Downloader (`test/downloader_test.rb`)**:
- [ ] Constants `REPO_OWNER`, `REPO_NAME`, `ASSET_NAME` are defined
- [ ] `download` method accepts the `to:` keyword argument
- [ ] `download` raises on network error (re-raises after warning)
- [ ] `download` expands the target path via `File.expand_path`
- [ ] `download` returns `true` on success

**Integration (`test/integration_test.rb`)**:
- [ ] Full workflow: configure -> download -> available? -> run succeeds
- [ ] Run before download raises `BinaryNotFound`

### 10.5 Integration Test Pattern

Every gem MUST include an integration test (`test/integration_test.rb`) that
simulates the complete user journey in a single scenario. This ensures the
public API methods compose correctly end-to-end.

The test walks through these steps in order:

1. **Configure** -- set `binary_path` to a temp directory and `runtime` to a
   non-default value (e.g. `"wazero"`) to prove configuration is respected.
2. **Assert not available** -- `available?` returns `false` before download.
3. **Download** -- call `download_to_binary_path!` (stub `Downloader.download`
   to write a fake file to the `to:` path).
4. **Assert available** -- `available?` returns `true` after download.
5. **Run** -- call `run(*args, wasm_dir:)` (stub `Open3.capture3`), then
   inspect the captured command array to verify:
   - `cmd[0]` is the configured runtime
   - `cmd[4]` is the configured `binary_path`
   - `cmd[5..]` matches the args passed in.

A second scenario verifies that calling `run` before downloading raises
`BinaryNotFound`.

```ruby
class IntegrationTest < Minitest::Test
  include <Tool>WasmTestHelper

  def test_full_user_workflow
    Dir.mktmpdir do |dir|
      target = File.join(dir, '<tool>.wasm')

      # 1. Configure
      <Tool>Wasm.binary_path = target
      <Tool>Wasm.runtime = 'wazero'

      # 2. Not available yet
      refute <Tool>Wasm.available?

      # 3. Download (stub writes fake file)
      <Tool>Wasm::Downloader.stub(:download, ->(to:) { File.write(to, 'fake'); true }) do
        <Tool>Wasm.download_to_binary_path!
      end

      # 4. Now available
      assert <Tool>Wasm.available?

      # 5. Run (stub Open3, capture command)
      captured_cmd = nil
      fake_capture3 = lambda do |*cmd|
        captured_cmd = cmd
        status = Minitest::Mock.new
        status.expect(:success?, true)
        ['', '', status]
      end

      Open3.stub(:capture3, fake_capture3) do
        result = <Tool>Wasm.run('-o', 'output.pptx', 'input.md', wasm_dir: dir)
        assert result[:success]
      end

      # 6. Verify command shape
      assert_equal 'wazero', captured_cmd[0]
      assert_equal target, captured_cmd[4]
      assert_equal ['-o', 'output.pptx', 'input.md'], captured_cmd[5..]
    end
  end

  def test_run_before_download_raises_binary_not_found
    Dir.mktmpdir do |dir|
      <Tool>Wasm.binary_path = File.join(dir, '<tool>.wasm')
      assert_raises(<Tool>Wasm::BinaryNotFound) do
        <Tool>Wasm.run('-o', 'output.pptx', 'input.md', wasm_dir: dir)
      end
    end
  end
end
```
