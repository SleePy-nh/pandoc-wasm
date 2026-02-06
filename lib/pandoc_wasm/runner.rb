# frozen_string_literal: true

require 'open3'

module PandocWasm
  class Runner
    # Run the wasm binary via the WASI runtime.
    # All positional arguments are passed through to the binary.
    #
    # @param args [Array<String>] arguments passed to the wasm binary
    # @param wasm_dir [String] directory to expose to the WASI sandbox (default: ".")
    # @return [Hash] { stdout: String, stderr: String, success: Boolean }
    # @raise [PandocWasm::BinaryNotFound] if the binary does not exist
    # @raise [PandocWasm::ExecutionError] on non-zero exit code
    def self.run(*args, wasm_dir: '.')
      binary = PandocWasm.binary_path

      unless File.exist?(binary)
        raise PandocWasm::BinaryNotFound,
              "pandoc.wasm not found at #{binary}. " \
              'Run PandocWasm.download_to_binary_path! to download it.'
      end

      cmd = [
        PandocWasm.runtime,
        'run',
        '--dir', wasm_dir,
        binary,
        *args
      ]

      stdout, stderr, status = Open3.capture3(*cmd)

      unless status.success?
        raise PandocWasm::ExecutionError,
              "pandoc exited with status #{status.exitstatus}: #{stderr}"
      end

      { stdout: stdout, stderr: stderr, success: true }
    end
  end
end
