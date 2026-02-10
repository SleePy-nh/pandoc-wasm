# frozen_string_literal: true

require_relative 'test_helper'

class DownloaderTest < Minitest::Test
  include PandocWasmTestHelper

  def test_constants_defined
    assert_equal 'NathanHimpens', PandocWasm::Downloader::REPO_OWNER
    assert_equal 'pandoc-wasm', PandocWasm::Downloader::REPO_NAME
    assert_equal 'pandoc.wasm', PandocWasm::Downloader::ASSET_NAME
  end

  def test_download_accepts_to_keyword
    # Verify the method signature accepts to: keyword
    assert PandocWasm::Downloader.method(:download).parameters.any? { |type, name| name == :to }
  end

  def test_release_tag_matches_gem_version
    expected = "v#{PandocWasm::VERSION}"
    assert_equal expected, PandocWasm::Downloader.release_tag
  end

  def test_download_raises_on_network_error
    # Stub download_asset to simulate a network failure
    PandocWasm::Downloader.stub(:download_asset, ->(_tag, _path) { raise 'Network error' }) do
      assert_raises(RuntimeError) do
        PandocWasm::Downloader.download(to: '/tmp/test_pandoc.wasm')
      end
    end
  end

  def test_download_expands_target_path
    # Stub download_asset to verify the path gets expanded
    downloaded_to = nil

    PandocWasm::Downloader.stub(:download_asset, ->(tag, path) { downloaded_to = path }) do
      PandocWasm::Downloader.download(to: '~/test_pandoc.wasm')
    end

    assert_equal File.expand_path('~/test_pandoc.wasm'), downloaded_to
  end

  def test_download_returns_true_on_success
    PandocWasm::Downloader.stub(:download_asset, ->(_tag, _path) { nil }) do
      result = PandocWasm::Downloader.download(to: '/tmp/test_pandoc.wasm')
      assert_equal true, result
    end
  end

  def test_download_uses_version_tag
    captured_tag = nil

    PandocWasm::Downloader.stub(:download_asset, ->(tag, _path) { captured_tag = tag }) do
      PandocWasm::Downloader.download(to: '/tmp/test_pandoc.wasm')
    end

    assert_equal "v#{PandocWasm::VERSION}", captured_tag
  end
end
