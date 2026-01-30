#!/usr/bin/env node

/**
 * Downloads pandoc.wasm from GitHub Releases
 * This script runs automatically after npm install via the postinstall hook
 */

const https = require('https');
const fs = require('fs');
const path = require('path');

const REPO_OWNER = 'NathanHimpens';
const REPO_NAME = 'pandoc-wasm';
const ASSET_NAME = 'pandoc.wasm';
const WASM_PATH = path.join(__dirname, '..', 'pandoc.wasm');

// Get version from package.json
const packageJson = require('../package.json');
const version = packageJson.version;

/**
 * Get the latest release tag from GitHub API
 */
function getLatestReleaseTag() {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'api.github.com',
      path: `/repos/${REPO_OWNER}/${REPO_NAME}/releases/latest`,
      headers: {
        'User-Agent': 'pandoc-wasm-downloader',
        'Accept': 'application/vnd.github.v3+json'
      }
    };

    https.get(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const release = JSON.parse(data);
            resolve(release.tag_name);
          } catch (e) {
            reject(new Error(`Failed to parse release data: ${e.message}`));
          }
        } else if (res.statusCode === 404) {
          // No releases yet, try to use version from package.json
          console.log(`No GitHub release found. Using version ${version} from package.json.`);
          resolve(`v${version}`);
        } else {
          reject(new Error(`GitHub API returned status ${res.statusCode}: ${data}`));
        }
      });
    }).on('error', (e) => {
      reject(new Error(`Failed to fetch release info: ${e.message}`));
    });
  });
}

/**
 * Download the asset from GitHub Releases
 */
function downloadAsset(tag) {
  return new Promise((resolve, reject) => {
    // Try to get the release by tag first to find the asset URL
    const options = {
      hostname: 'api.github.com',
      path: `/repos/${REPO_OWNER}/${REPO_NAME}/releases/tags/${tag}`,
      headers: {
        'User-Agent': 'pandoc-wasm-downloader',
        'Accept': 'application/vnd.github.v3+json'
      }
    };

    https.get(options, (res) => {
      let data = '';

      res.on('data', (chunk) => {
        data += chunk;
      });

      res.on('end', () => {
        if (res.statusCode === 404) {
          // Release doesn't exist yet, skip download
          console.log(`Release ${tag} not found on GitHub. Skipping download.`);
          console.log('You can manually download pandoc.wasm from the repository or build it yourself.');
          resolve(false);
          return;
        }

        if (res.statusCode !== 200) {
          reject(new Error(`GitHub API returned status ${res.statusCode}: ${data}`));
          return;
        }

        try {
          const release = JSON.parse(data);
          const asset = release.assets.find(a => a.name === ASSET_NAME);

          if (!asset) {
            console.log(`Asset ${ASSET_NAME} not found in release ${tag}.`);
            console.log('You can manually download pandoc.wasm from the repository or build it yourself.');
            resolve(false);
            return;
          }

          // Download the asset
          console.log(`Downloading ${ASSET_NAME} from release ${tag}...`);
          console.log(`Size: ${(asset.size / 1024 / 1024).toFixed(2)} MB`);

          const file = fs.createWriteStream(WASM_PATH);
          const downloadUrl = new URL(asset.browser_download_url);

          const downloadOptions = {
            hostname: downloadUrl.hostname,
            path: downloadUrl.pathname + downloadUrl.search,
            headers: {
              'User-Agent': 'pandoc-wasm-downloader',
              'Accept': 'application/octet-stream'
            }
          };

          https.get(downloadOptions, (downloadRes) => {
            if (downloadRes.statusCode !== 200) {
              file.close();
              fs.unlinkSync(WASM_PATH);
              reject(new Error(`Failed to download asset: ${downloadRes.statusCode}`));
              return;
            }

            downloadRes.pipe(file);

            file.on('finish', () => {
              file.close();
              // Make executable
              fs.chmodSync(WASM_PATH, 0o755);
              console.log(`✓ Successfully downloaded ${ASSET_NAME}`);
              resolve(true);
            });
          }).on('error', (e) => {
            file.close();
            fs.unlinkSync(WASM_PATH);
            reject(new Error(`Download failed: ${e.message}`));
          });
        } catch (e) {
          reject(new Error(`Failed to parse release data: ${e.message}`));
        }
      });
    }).on('error', (e) => {
      reject(new Error(`Failed to fetch release: ${e.message}`));
    });
  });
}

/**
 * Main function
 */
async function main() {
  // Check if file already exists
  if (fs.existsSync(WASM_PATH)) {
    console.log('pandoc.wasm already exists. Skipping download.');
    return;
  }

  try {
    const tag = await getLatestReleaseTag();
    const downloaded = await downloadAsset(tag);
    
    if (!downloaded) {
      console.warn('\n⚠️  pandoc.wasm was not downloaded automatically.');
      console.warn('This is normal if no GitHub release exists yet.\n');
      console.warn('To use this package, you need to:');
      console.warn('1. Build pandoc.wasm yourself (see README.md)');
      console.warn('2. Create a GitHub release with pandoc.wasm attached');
      console.warn('3. Or manually copy pandoc.wasm to this directory\n');
      // Don't exit with error - allow the package to be installed
      // The user can manually add the file later
      return;
    }
  } catch (error) {
    console.error('Error downloading pandoc.wasm:', error.message);
    console.error('\nYou can:');
    console.error('1. Build it yourself following the instructions in README.md');
    console.error('2. Manually download it from a GitHub release');
    console.error('3. Copy it from the build directory after compilation');
    // Don't exit with error - allow installation to continue
    // The user can manually add the file later
    console.warn('\n⚠️  Installation will continue, but pandoc.wasm must be added manually.');
  }
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { main, downloadAsset, getLatestReleaseTag };
