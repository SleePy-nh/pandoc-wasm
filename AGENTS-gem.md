# AGENTS.md -- Guidelines for Building Ruby Gems

This document describes the architecture, conventions, and best practices for
building production-quality Ruby gems. It is meant to be copied into every new
gem repository and adapted to the specific gem's purpose.

Sources: [Gem Check (Evil Martians)](https://gemcheck.evilmartians.io/),
[RubyGems Patterns](https://guides.rubygems.org/patterns/),
[Writing Ruby Gems (Pat Allan)](https://freelancing-gods.com/slides/gems.html),
community best practices.

---

## 1. Naming Conventions

| Concept | Convention | Example |
|---------|-----------|---------|
| Single-concept gem | `snake_case` with underscores | `my_gem` |
| Namespaced gem | hyphen between namespace and name | `my_org-auth` |
| Module name | `PascalCase` matching the gem name | `MyGem` / `MyOrg::Auth` |
| Main file | `lib/<gem_name>.rb` | `lib/my_gem.rb` |
| Sub-files | `lib/<gem_name>/` directory | `lib/my_gem/version.rb` |

Rules (from RubyGems official guide + Pat Allan):

- Use underscores to separate words within a single concept: `my_gem` -> `MyGem`.
- Use hyphens to separate namespaces: `my_org-auth` -> `MyOrg::Auth`.
- The main require file MUST match the gem name exactly: `require 'my_gem'`.
- The directory structure under `lib/` MUST mirror the module nesting.
- NEVER add files at the top level of `lib/` that could collide with stdlib or
  other gems (e.g. do NOT create `lib/json.rb`).

---

## 2. File Layout

```
lib/
  <gem_name>.rb                   # Main entry point -- requires, module definition
  <gem_name>/
    version.rb                    # VERSION constant (semver string)
    configuration.rb              # Configuration class (if needed)
    errors.rb                     # Custom error classes
    ...                           # Domain-specific files
app/                              # (Rails Engine/Railtie gems only)
  models/
  controllers/
  ...
exe/                              # CLI executables (if any)
  <gem_name>
bin/                              # Development binstubs
test/ or spec/                    # Test suite
  test_helper.rb or spec_helper.rb
  <gem_name>_test.rb
  ...
<gem_name>.gemspec                # Gem specification
Gemfile                           # Uses `gemspec` directive
Rakefile                          # Default task = test suite
README.md                         # Usage documentation
CHANGELOG.md                      # Version history
LICENSE.txt                       # License (default: MIT)
```

---

## 3. Gemspec Conventions

### Required metadata

```ruby
Gem::Specification.new do |spec|
  spec.name          = '<gem_name>'
  spec.version       = MyGem::VERSION
  spec.authors       = ['Author Name']
  spec.email         = ['author@example.com']
  spec.summary       = 'One-line summary of what the gem does.'
  spec.description   = 'Longer description if needed.'
  spec.homepage      = 'https://github.com/<owner>/<gem_name>'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.1.0'

  spec.metadata['homepage_uri']    = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri']   = "#{spec.homepage}/blob/main/CHANGELOG.md"
end
```

### File inclusion -- whitelist, never blacklist

```ruby
spec.files = Dir.glob('lib/**/*') + Dir.glob('exe/*') +
             %w[README.md LICENSE.txt CHANGELOG.md]
spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
spec.require_paths = ['lib']
```

Do NOT include tests, CI configs, development files, or documentation beyond
the README in the packaged gem. This keeps the gem lightweight.

### Dependencies

- Use `add_dependency` for runtime dependencies. Keep them minimal.
- Use `add_development_dependency` for test/dev tools.
- Use the pessimistic version constraint (`~>`) whenever possible:
  `spec.add_dependency 'some_gem', '~> 2.0'`.
- NEVER use `gem` calls inside your gem code. Let the gemspec handle it.
- NEVER `require 'rubygems'` inside your gem -- it is loaded automatically.

---

## 4. API Design Principles

These principles come from the Evil Martians Gem Check checklist:

### 4.1 Reduce boilerplate, preserve flexibility

Simple things should be simple, complex things should be possible. Provide
sensible defaults (convention over configuration) while allowing full control
for advanced use cases.

### 4.2 Principle of least astonishment

- Predicate methods (`available?`, `valid?`) MUST return `true` or `false`.
- Finder methods return the object or `nil`, never `false`.
- Use keyword arguments when a method needs more than 2 parameters.

### 4.3 Raise meaningful, actionable errors

- Always include a clear error message: error classes for machines, messages
  for humans.
- Use `ArgumentError` for wrong/missing arguments.
- Define custom error classes for domain-specific exceptions.
- Avoid negative words in error messages ("bad", "wrong"). Use neutral terms
  ("invalid", "unexpected", "missing").
- When re-raising, preserve the cause: `raise MyError, "msg"` instead of
  `raise MyError.new("msg")`.

### 4.4 Error class hierarchy

```ruby
module MyGem
  class Error < StandardError; end

  # Domain-specific errors inherit from Error
  class ConfigurationError < Error; end
  class NotFoundError < Error; end
  class ExecutionError < Error; end
end
```

### 4.5 No monkey-patching

- NEVER monkey-patch core classes (`String`, `Hash`, `Array`, etc.).
- Use Refinements if you absolutely need syntactic sugar on core types.
- Patch third-party libs via `Module#prepend`, never `alias_method`.

---

## 5. Architecture Patterns

### 5.1 Configuration pattern

Provide a block-based configuration when the gem has more than 2 settings:

```ruby
module MyGem
  class Configuration
    attr_accessor :api_key, :timeout, :logger

    def initialize
      @timeout = 30
      @logger  = Logger.new($stdout)
    end
  end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end

# Usage:
MyGem.configure do |config|
  config.api_key = 'abc123'
  config.timeout = 60
end
```

For simple gems with 1-2 settings, class-level accessors are sufficient:

```ruby
module MyGem
  class << self
    attr_writer :api_key

    def api_key
      @api_key || ENV['MY_GEM_API_KEY']
    end
  end
end
```

Always support environment variables for twelve-factor-compatible configuration.

### 5.2 Service pattern with ActiveInteraction

When a gem exposes operations that represent business actions (commands,
services, use cases), use the **ActiveInteraction** gem to structure them.
ActiveInteraction provides typed inputs with automatic validation, composable
services, and ActiveModel compatibility.

**When to use ActiveInteraction:**
- The gem exposes discrete operations with typed inputs/outputs.
- Operations need input validation before execution.
- Services compose with one another.
- The gem is used within a Rails application or alongside ActiveModel.

**Runtime dependency:**

```ruby
spec.add_dependency 'active_interaction', '~> 5.3'
```

**Base service pattern:**

```ruby
# lib/my_gem/services/base_service.rb
module MyGem
  module Services
    class BaseService < ActiveInteraction::Base
      # Shared logic, helpers, error handling
    end
  end
end
```

**Concrete service pattern:**

```ruby
# lib/my_gem/services/create_thing_service.rb
module MyGem
  module Services
    class CreateThingService < BaseService
      string  :name
      integer :quantity, default: 1
      object  :config, class: MyGem::Configuration, default: nil

      validates :name, presence: true

      def execute
        # Business logic here
        # Return value becomes the result
        # Use errors.add(:base, "msg") for domain errors
        # Use compose(OtherService, inputs) for composition
      end
    end
  end
end
```

**ActiveInteraction conventions:**

- Group services in `app/services/` (Rails) or `lib/<gem>/services/` (gem).
- Organize by domain: `services/datasets/`, `services/ai/`, `services/utils/`.
- Create a `BaseService < ActiveInteraction::Base` per domain when shared logic
  exists.
- Use `.run!` when failure should raise, `.run` when you need the outcome
  object.
- Use typed filters (`string`, `integer`, `record`, `object`, `array`,
  `boolean`, `hash`) instead of untyped arguments.
- Use `set_callback :execute, :before/:after` for cross-cutting concerns
  (logging, tracking, cleanup).
- Use `compose(OtherService, args)` to chain services. Errors propagate
  automatically.
- Use `class_attribute` for per-subclass configuration with defaults.

### 5.3 Adapterize third-party dependencies

When your gem talks to an external system (HTTP API, database, message queue),
hide it behind an adapter interface. This allows users to swap implementations
and simplifies testing.

```ruby
module MyGem
  module Adapters
    class Base
      def call(request)
        raise NotImplementedError
      end
    end

    class HttpAdapter < Base
      def call(request)
        # HTTParty, Faraday, Net::HTTP, etc.
      end
    end
  end
end
```

### 5.4 Provide logging (when necessary)

Allow the user to inject a Logger instance. Never use `puts` for logging.

```ruby
MyGem.configure do |config|
  config.logger = Rails.logger
end
```

### 5.5 Make code testable

- Provide test helpers, matchers, or mocks if the gem has side effects.
- Ensure configuration can be reset between tests.
- Provide in-memory or mock adapters for external integrations.

---

## 6. Recommended Dependencies

Keep runtime dependencies minimal. Only add what the gem truly needs. Below are
well-known, production-proven gems organized by use case. Prefer these over
lesser-known alternatives.

### Runtime dependencies (add only what you need)

| Use case | Gem | Notes |
|----------|-----|-------|
| Service objects | `active_interaction` (~> 5.3) | Typed inputs, validation, composition. Use when the gem exposes operations/commands. |
| HTTP requests | `httparty` | Simple, well-known. |
| State machines | `aasm` | Mature, well-documented. Integrates with ActiveRecord. |
| Authorization | `action_policy` | Modern, performant alternative to Pundit/CanCanCan. |
| JSON processing | `oj` | Faster than stdlib JSON. Drop-in replacement. |
| Background jobs | `solid_queue` | Rails 8+ default. Or `sidekiq` for Redis-based. |
| Encryption | `lockbox` | Field-level encryption for sensitive data. |
| Soft deletes | `paranoia` | Adds `.with_deleted` scope, `deleted_at` column. |

### Development dependencies (common)

| Use case | Gem | Notes |
|----------|-----|-------|
| Testing | `minitest` (stdlib) | Default for gems. No extra dependency. |
| Testing (alt) | `rspec-rails` | If the gem is Rails-centric and team prefers RSpec. |
| Factories | `factory_bot` / `factory_bot_rails` | Test data generation. |
| Fake data | `faker` | Generates realistic test data. |
| HTTP mocking | `webmock` | Stub HTTP requests in tests. |
| VCR | `vcr` | Record and replay HTTP interactions. |
| Code coverage | `simplecov` | Coverage reports. |
| Linting | `rubocop` or `standardrb` | Consistent code style. |
| Security audit | `brakeman`, `bundler-audit` | Static analysis and CVE checking. |

### Dependency rules

1. More dependencies = more chances for failure and harder upgrades.
2. Do NOT add `rails` if you only need `activemodel` or `activesupport`.
3. Do NOT add `activesupport` if you only need one method -- use a refinement.
4. Do NOT add optional-use-case gems as runtime dependencies. Document them and
   let users add them themselves.
5. Monitor dependencies for CVEs with `bundler-audit`.

---

## 7. Module Implementation Pattern

The main entry point (`lib/<gem_name>.rb`) follows this structure:

```ruby
# frozen_string_literal: true

require_relative '<gem_name>/version'
require_relative '<gem_name>/configuration'
require_relative '<gem_name>/errors'
# require_relative '<gem_name>/...'

module MyGem
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
```

For gems that also serve as a Rails Engine:

```ruby
require_relative '<gem_name>/engine' if defined?(Rails::Railtie)
```

---

## 8. Versioning

Follow [Semantic Versioning](https://semver.org):

| Change type | Version bump | Example |
|-------------|-------------|---------|
| Bug fix, no API change | PATCH | 1.0.0 -> 1.0.1 |
| New feature, backward compatible | MINOR | 1.0.0 -> 1.1.0 |
| Breaking change | MAJOR | 1.0.0 -> 2.0.0 |

The version constant lives in `lib/<gem_name>/version.rb`:

```ruby
# frozen_string_literal: true

module MyGem
  VERSION = '0.1.0'
end
```

Additional rules:

- Use pre-release versions for betas: `1.0.0.beta1`, `2.0.0.rc1`.
- Show deprecation warnings for at least one minor version before removing
  features.
- Keep a `CHANGELOG.md` following [keepachangelog.com](https://keepachangelog.com)
  format.
- Tag every release in git: `git tag v1.0.0`.

---

## 9. Documentation

### 9.1 README.md (required)

Every gem MUST have a README that includes:

1. **One-line description** -- what the gem does.
2. **Installation** -- `gem install` and Gemfile instructions.
3. **Quick start** -- minimal working example.
4. **Configuration** -- all available options with defaults.
5. **Usage examples** -- simple and advanced scenarios.
6. **API reference** -- or a link to YARD-generated docs.
7. **Contributing** -- how to set up the dev environment and run tests.
8. **License** -- which license the gem uses.

### 9.2 CHANGELOG.md (required)

Use the [Keep a Changelog](https://keepachangelog.com) format:

```markdown
## [Unreleased]

## [1.1.0] - 2025-03-15
### Added
- New feature X.

### Fixed
- Bug in Y.

## [1.0.0] - 2025-01-01
### Added
- Initial release.
```

### 9.3 Code documentation

- Use YARD for inline documentation on public methods.
- Code examples in docs MUST have correct syntax and consistent style. Lint
  them with `rubocop-md` if needed.
- Write code in a consistent style. Use `rubocop` or `standardrb`.

---

## 10. Testing Strategy

### 10.1 Framework

Use **Minitest** (stdlib) by default for standalone gems. Use **RSpec** if the
gem is Rails-centric and the team uses RSpec.

Tests run with `rake test` (or `rake spec`). The Rakefile's default task MUST
be the test suite.

```ruby
# Rakefile
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test
```

### 10.2 Test helper -- configuration reset

Because gems store configuration in module-level state, every test file MUST
reset state between tests:

```ruby
# test/test_helper.rb
require 'minitest/autorun'
require '<gem_name>'

module MyGemTestHelper
  def setup
    @original_configuration = MyGem.instance_variable_get(:@configuration)
  end

  def teardown
    MyGem.instance_variable_set(:@configuration, @original_configuration)
  end
end
```

### 10.3 Stubbing conventions

- **External HTTP calls**: Use `webmock` to stub. NEVER make real HTTP calls in
  unit tests.
- **ActiveInteraction services**: Stub with `.run` / `.run!` or use
  `Minitest::Mock` / RSpec mocks.
- **File system operations**: Use `Dir.mktmpdir` for temp files. Clean up in
  teardown.
- **Time-dependent code**: Use `timecop` or `travel_to` (Rails).

### 10.4 Test checklist

Every gem MUST have tests covering:

**Public API:**
- [ ] All public methods behave as documented.
- [ ] Default configuration values are correct.
- [ ] Configuration can be overridden.
- [ ] Error classes have the correct hierarchy.
- [ ] VERSION matches semver format (`/\A\d+\.\d+\.\d+/`).

**Error paths:**
- [ ] Invalid inputs raise appropriate errors with clear messages.
- [ ] Network/IO failures are handled gracefully.
- [ ] Edge cases (nil, empty string, wrong type) are covered.

**Integration:**
- [ ] A full workflow test exercises the public API end-to-end.
- [ ] Services compose correctly (if using ActiveInteraction).

**ActiveInteraction services (if applicable):**
- [ ] `.run!` returns the expected result on success.
- [ ] `.run` returns an outcome with errors on invalid inputs.
- [ ] Filters reject invalid types.
- [ ] Composed services propagate errors correctly.
- [ ] Callbacks fire in the expected order.

### 10.5 ActiveInteraction testing pattern

```ruby
class CreateThingServiceTest < Minitest::Test
  def test_success
    result = MyGem::Services::CreateThingService.run!(
      name: 'Widget',
      quantity: 5
    )
    assert_equal expected_value, result
  end

  def test_invalid_input
    outcome = MyGem::Services::CreateThingService.run(name: '')
    refute outcome.valid?
    assert outcome.errors[:name].any?
  end

  def test_composition
    # Stub the composed service if needed
    MyGem::Services::OtherService.stub(:run!, 'stubbed_result') do
      result = MyGem::Services::CreateThingService.run!(name: 'Test')
      assert_equal 'expected', result
    end
  end
end
```

---

## 11. Publishing & Releasing

### 11.1 Pre-release checklist

- [ ] All tests pass.
- [ ] CHANGELOG.md is up to date.
- [ ] Version is bumped in `version.rb`.
- [ ] README reflects any API changes.
- [ ] `bundle exec rake build` succeeds.
- [ ] No secrets, credentials, or dev files in `spec.files`.

### 11.2 Release process

```bash
# 1. Build the gem
gem build <gem_name>.gemspec

# 2. Test locally
gem install <gem_name>-x.y.z.gem

# 3. Publish
gem push <gem_name>-x.y.z.gem

# 4. Tag in git
git tag v<x.y.z>
git push origin v<x.y.z>
```

Or use Bundler's rake tasks:

```bash
bundle exec rake release
```

### 11.3 Security

- Enable MFA on your RubyGems.org account.
- Add `spec.metadata['rubygems_mfa_required'] = 'true'` to the gemspec.
- NEVER yank a published version unless it contains a critical security issue.
- Run `bundler-audit` and `brakeman` (for Rails gems) in CI.

---

## 12. Rails Integration

### 12.1 Rails Engine

If the gem adds models, controllers, views, or assets to a Rails app:

```ruby
# lib/my_gem/engine.rb
module MyGem
  class Engine < ::Rails::Engine
    isolate_namespace MyGem
  end
end
```

Load it from the main entry point:

```ruby
require_relative 'my_gem/engine' if defined?(Rails::Railtie)
```

### 12.2 Railtie

If the gem only needs to hook into Rails boot (add initializers, rake tasks)
without providing app-level files:

```ruby
# lib/my_gem/railtie.rb
module MyGem
  class Railtie < ::Rails::Railtie
    initializer 'my_gem.configure' do
      # hook into Rails startup
    end

    rake_tasks do
      load 'tasks/my_gem.rake'
    end
  end
end
```

---

## 13. Code Quality

### 13.1 Style

- Use `rubocop` or `standardrb` for consistent formatting.
- Add `# frozen_string_literal: true` at the top of every Ruby file.
- Follow the [Ruby Style Guide](https://github.com/rubocop/ruby-style-guide).

### 13.2 Dependencies hygiene

- Specify pessimistic version constraints (`~>`) for all dependencies.
- Run `bundler-audit check` in CI to detect known vulnerabilities.
- Use Dependabot or Depfu for automated dependency updates.

### 13.3 Interoperability

- Test against multiple Ruby versions (at minimum: current stable and
  previous stable).
- Avoid global/class variable mutation that breaks Ractor compatibility.
- Do not manipulate `$LOAD_PATH` -- RubyGems handles it.

---

## 14. Adapting This Document

To use this AGENTS.md in a new gem project:

1. Copy this file into the root of the gem repository.
2. Replace all occurrences of `MyGem` / `my_gem` / `<gem_name>` with the
   actual gem module and file names.
3. Remove sections that do not apply (e.g., Rails Engine if the gem is
   not Rails-related, ActiveInteraction if not service-oriented).
4. Add gem-specific sections as needed (e.g., CLI usage, binary downloads,
   specific adapter patterns).
5. Keep this file up to date as the gem evolves.
