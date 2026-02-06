# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'

class IntegrationTest < Minitest::Test
  include PandocWasmTestHelper

  # Full user workflow: configure -> download -> check -> run
  def test_full_user_workflow
    Dir.mktmpdir do |dir|
      target = File.join(dir, 'pandoc.wasm')

      # 1. Configure binary path and runtime
      PandocWasm.binary_path = target
      PandocWasm.runtime = 'wazero'

      assert_equal target, PandocWasm.binary_path
      assert_equal 'wazero', PandocWasm.runtime

      # 2. Binary not available yet
      refute PandocWasm.available?

      # 3. Download (stub writes a fake file to the configured path)
      PandocWasm::Downloader.stub(:download, ->(to:) { File.write(to, 'fake-wasm-binary'); true }) do
        result = PandocWasm.download_to_binary_path!
        assert_equal true, result
      end

      # 4. Binary is now available
      assert PandocWasm.available?

      # 5. Run conversion — verify the command uses configured runtime + binary_path
      captured_cmd = nil
      fake_capture3 = lambda do |*cmd|
        captured_cmd = cmd
        status = Minitest::Mock.new
        status.expect(:success?, true)
        ['', '', status]
      end

      Open3.stub(:capture3, fake_capture3) do
        result = PandocWasm.run('-o', 'output.pptx', '--slide-level=2', 'input.md', wasm_dir: dir)
        assert_equal true, result[:success]
      end

      # 6. Verify the full command shape
      assert_equal 'wazero', captured_cmd[0], 'should use configured runtime'
      assert_equal 'run', captured_cmd[1]
      assert_equal '--dir', captured_cmd[2]
      assert_equal dir, captured_cmd[3], 'should use provided wasm_dir'
      assert_equal target, captured_cmd[4], 'should use configured binary_path'
      # args are passed through in order after the binary
      assert_equal ['-o', 'output.pptx', '--slide-level=2', 'input.md'], captured_cmd[5..], 'args passed through'
    end
  end

  # Attempting to run before downloading raises BinaryNotFound
  def test_run_before_download_raises_binary_not_found
    Dir.mktmpdir do |dir|
      target = File.join(dir, 'pandoc.wasm')

      # Configure but do NOT download
      PandocWasm.binary_path = target
      PandocWasm.runtime = 'wasmtime'

      refute PandocWasm.available?

      error = assert_raises(PandocWasm::BinaryNotFound) do
        PandocWasm.run('-o', 'output.pptx', 'input.md', wasm_dir: dir)
      end

      assert_match(/not found/, error.message)
      assert_match(/download_to_binary_path/, error.message)
    end
  end
end
