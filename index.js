/**
 * @nathanhimpens/pandoc-wasm
 * 
 * Exports the path to the pandoc.wasm binary.
 * The binary is automatically downloaded from GitHub Releases during npm install.
 */

const path = require('path');
const fs = require('fs');

const wasmPath = path.join(__dirname, 'pandoc.wasm');

// Check if the file exists, if not, provide helpful error message
if (!fs.existsSync(wasmPath)) {
  console.warn(
    'Warning: pandoc.wasm not found. It should be downloaded automatically during installation.\n' +
    'If you see this message, try running: npm run postinstall'
  );
}

module.exports = wasmPath;

// Also export as default for ES modules compatibility
module.exports.default = wasmPath;
