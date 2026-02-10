# frozen_string_literal: true

require_relative 'lib/pandoc_wasm/version'

Gem::Specification.new do |spec|
  spec.name          = 'pandoc_wasm'
  spec.version       = PandocWasm::VERSION
  spec.authors       = ['Nathan Himpens']
  spec.email         = ['']

  spec.summary       = 'Pandoc compiled to WebAssembly for document conversion in WASI environments'
  spec.description   = 'Pandoc compiled to WebAssembly for document conversion in WASI environments. ' \
                        'Run pandoc (Markdown to HTML, DOCX, PPTX, etc.) without native installation.'
  spec.homepage      = 'https://github.com/NathanHimpens/pandoc-wasm'
  spec.license       = 'GPL-2.0-or-later'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = spec.homepage
  spec.metadata['changelog_uri']         = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Whitelist files included in the gem
  spec.files = Dir.glob('lib/**/*') + %w[README.md LICENSE.txt CHANGELOG.md pandoc_wasm.gemspec Rakefile]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Ruby standard library dependencies (no external gems needed)
  spec.required_ruby_version = '>= 2.7.0'

  # Post-install message
  spec.post_install_message = <<~MSG
    pandoc_wasm installed successfully!

    The pandoc.wasm binary (~166 MB) is NOT bundled with the gem.
    Download it by calling:

      PandocWasm.download_to_binary_path!

    For Rails, add this to an initializer (e.g. config/initializers/pandoc_wasm.rb):

      PandocWasm.download_to_binary_path! unless PandocWasm.available?
  MSG
end
