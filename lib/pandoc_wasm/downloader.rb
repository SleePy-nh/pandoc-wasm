# frozen_string_literal: true

require 'net/http'
require 'json'
require 'fileutils'
require 'uri'

module PandocWasm
  class Downloader
    REPO_OWNER = 'NathanHimpens'
    REPO_NAME = 'pandoc-wasm'
    ASSET_NAME = 'pandoc.wasm'

    # Download pandoc.wasm from the GitHub Release matching the gem version.
    #
    # The release tag is derived from PandocWasm::VERSION (e.g. "1.0.1" -> "v1.0.1"),
    # so the downloaded binary always matches the installed gem version.
    #
    # @param to [String] absolute path where the binary will be written
    # @return [true] on success
    # @raise [StandardError] on failure
    def self.download(to:)
      target = File.expand_path(to)
      FileUtils.mkdir_p(File.dirname(target))

      begin
        tag = release_tag
        download_asset(tag, target)
        true
      rescue StandardError => e
        FileUtils.rm_f(target)
        warn "Error downloading pandoc.wasm: #{e.message}"
        raise
      end
    end

    # Returns the GitHub release tag matching the current gem version.
    #
    # @return [String] e.g. "v1.0.1"
    def self.release_tag
      "v#{PandocWasm::VERSION}"
    end

    private

    # Download the asset from a GitHub Release to the given target path
    def self.download_asset(tag, target)
      uri = URI("https://api.github.com/repos/#{REPO_OWNER}/#{REPO_NAME}/releases/tags/#{tag}")

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 30

      request = Net::HTTP::Get.new(uri)
      request['User-Agent'] = 'pandoc-wasm-ruby-downloader'
      request['Accept'] = 'application/vnd.github.v3+json'

      response = http.request(request)

      case response.code
      when '200'
        # continue
      when '404'
        raise "Release #{tag} not found on GitHub"
      else
        raise "GitHub API returned status #{response.code}: #{response.body}"
      end

      release = JSON.parse(response.body)
      asset = release['assets'].find { |a| a['name'] == ASSET_NAME }

      unless asset
        raise "Asset #{ASSET_NAME} not found in release #{tag}"
      end

      download_uri = URI(asset['browser_download_url'])
      max_redirects = 10
      redirects = 0

      File.open(target, 'wb') do |file|
        loop do
          download_http = Net::HTTP.new(download_uri.host, download_uri.port)
          download_http.use_ssl = (download_uri.scheme == 'https')
          download_http.read_timeout = 300

          download_request = Net::HTTP::Get.new(download_uri)
          download_request['User-Agent'] = 'pandoc-wasm-ruby-downloader'
          download_request['Accept'] = 'application/octet-stream'

          download_http.request(download_request) do |dl_response|
            case dl_response
            when Net::HTTPRedirection
              redirects += 1
              raise "Too many redirects" if redirects > max_redirects
              download_uri = URI(dl_response['location'])
              next
            when Net::HTTPSuccess
              dl_response.read_body do |chunk|
                file.write(chunk)
              end
            else
              raise "Failed to download asset: #{dl_response.code}"
            end
          end

          break
        end
      end

      File.chmod(0o755, target)
      true
    end
  end
end
