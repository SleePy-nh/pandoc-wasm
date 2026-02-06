# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'

class RunnerTest < Minitest::Test
  include PandocWasmTestHelper

  # -- raises BinaryNotFound when binary is missing --

  def test_raises_binary_not_found
    PandocWasm.binary_path = '/tmp/nonexistent_pandoc_wasm_test.wasm'

    error = assert_raises(PandocWasm::BinaryNotFound) do
      PandocWasm::Runner.run('-o', 'output.pptx', 'input.md')
    end

    assert_match(/not found/, error.message)
    assert_match(/download_to_binary_path/, error.message)
  end

  # -- builds the correct command --

  def test_builds_correct_command
    Dir.mktmpdir do |dir|
      binary = File.join(dir, 'pandoc.wasm')
      File.write(binary, 'fake')
      PandocWasm.binary_path = binary
      PandocWasm.runtime = 'wasmtime'

      captured_cmd = nil
      fake_capture3 = lambda do |*cmd|
        captured_cmd = cmd
        ['', '', stub_status(true, 0)]
      end

      Open3.stub(:capture3, fake_capture3) do
        PandocWasm::Runner.run('-o', 'output.pptx', 'input.md', wasm_dir: '/mydir')
      end

      expected = ['wasmtime', 'run', '--dir', '/mydir', binary, '-o', 'output.pptx', 'input.md']
      assert_equal expected, captured_cmd
    end
  end

  # -- includes extra_args in command --

  def test_passes_all_args_through
    Dir.mktmpdir do |dir|
      binary = File.join(dir, 'pandoc.wasm')
      File.write(binary, 'fake')
      PandocWasm.binary_path = binary

      captured_cmd = nil
      fake_capture3 = lambda do |*cmd|
        captured_cmd = cmd
        ['', '', stub_status(true, 0)]
      end

      Open3.stub(:capture3, fake_capture3) do
        PandocWasm::Runner.run('-o', 'out.pptx', '--slide-level=2', '--reference-doc=ref.pptx', 'in.md')
      end

      # args appear after the binary path, in the order given
      args_part = captured_cmd[5..]
      assert_equal ['-o', 'out.pptx', '--slide-level=2', '--reference-doc=ref.pptx', 'in.md'], args_part
    end
  end

  # -- uses configured runtime --

  def test_uses_configured_runtime
    Dir.mktmpdir do |dir|
      binary = File.join(dir, 'pandoc.wasm')
      File.write(binary, 'fake')
      PandocWasm.binary_path = binary
      PandocWasm.runtime = 'wasmer'

      captured_cmd = nil
      fake_capture3 = lambda do |*cmd|
        captured_cmd = cmd
        ['', '', stub_status(true, 0)]
      end

      Open3.stub(:capture3, fake_capture3) do
        PandocWasm::Runner.run('-o', 'out.pptx', 'in.md')
      end

      assert_equal 'wasmer', captured_cmd.first
    end
  end

  # -- returns result hash on success --

  def test_returns_result_hash_on_success
    Dir.mktmpdir do |dir|
      binary = File.join(dir, 'pandoc.wasm')
      File.write(binary, 'fake')
      PandocWasm.binary_path = binary

      fake_capture3 = lambda do |*_cmd|
        ["some output\n", "some warning\n", stub_status(true, 0)]
      end

      result = nil
      Open3.stub(:capture3, fake_capture3) do
        result = PandocWasm::Runner.run('-o', 'out.pptx', 'in.md')
      end

      assert_equal true, result[:success]
      assert_equal "some output\n", result[:stdout]
      assert_equal "some warning\n", result[:stderr]
    end
  end

  # -- raises ExecutionError on failure --

  def test_raises_execution_error_on_failure
    Dir.mktmpdir do |dir|
      binary = File.join(dir, 'pandoc.wasm')
      File.write(binary, 'fake')
      PandocWasm.binary_path = binary

      fake_capture3 = lambda do |*_cmd|
        ['', "Unknown format\n", stub_status(false, 1)]
      end

      error = nil
      Open3.stub(:capture3, fake_capture3) do
        error = assert_raises(PandocWasm::ExecutionError) do
          PandocWasm::Runner.run('-o', 'out.pptx', 'in.md')
        end
      end

      assert_match(/status 1/, error.message)
      assert_match(/Unknown format/, error.message)
    end
  end

  # -- default wasm_dir is "." --

  def test_default_wasm_dir
    Dir.mktmpdir do |dir|
      binary = File.join(dir, 'pandoc.wasm')
      File.write(binary, 'fake')
      PandocWasm.binary_path = binary

      captured_cmd = nil
      fake_capture3 = lambda do |*cmd|
        captured_cmd = cmd
        ['', '', stub_status(true, 0)]
      end

      Open3.stub(:capture3, fake_capture3) do
        PandocWasm::Runner.run('-o', 'out.pptx', 'in.md')
      end

      dir_flag_idx = captured_cmd.index('--dir')
      assert_equal '.', captured_cmd[dir_flag_idx + 1]
    end
  end

  private

  # Create a minimal status object for stubbing Open3.capture3
  def stub_status(success, exitstatus)
    status = Minitest::Mock.new
    status.expect(:success?, success)
    # exitstatus is only called on failure path
    status.expect(:exitstatus, exitstatus) unless success
    status
  end
end
