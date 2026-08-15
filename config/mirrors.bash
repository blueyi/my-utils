# Mainland China package/binary mirrors.
# Sourced from resetrc.bash. Default on; disable with:
#   export MY_UTILS_MIRRORS=off   # in ~/.env.rc (survives create_links.sh)
#
# File-based configs are NOT gated by this flag (they apply to GUI/non-login too):
#   ~/.npmrc              → config/npm/npmrc
#   ~/.cargo/config.toml  → config/cargo/config.toml
# Unlink those two to fully revert npm/Cargo.

: "${MY_UTILS_MIRRORS:=cn}"

_my_utils_mirrors_cn() {
  case "${MY_UTILS_MIRRORS}" in
    cn|CN|1|true|on|ON) return 0 ;;
    *) return 1 ;;
  esac
}

if _my_utils_mirrors_cn; then
  # Go: official proxy.golang.org times out on this network
  export GOPROXY="${GOPROXY:-https://goproxy.cn,direct}"
  export GOSUMDB="${GOSUMDB:-sum.golang.google.cn}"

  # Node / nvm / node-gyp dist
  export NODEJS_ORG_MIRROR="${NODEJS_ORG_MIRROR:-https://npmmirror.com/mirrors/node}"
  export NVM_NODEJS_ORG_MIRROR="${NVM_NODEJS_ORG_MIRROR:-$NODEJS_ORG_MIRROR}"

  # Electron / Playwright / Puppeteer / node-sass (also duplicated in npmrc)
  export ELECTRON_MIRROR="${ELECTRON_MIRROR:-https://npmmirror.com/mirrors/electron/}"
  export ELECTRON_BUILDER_BINARIES_MIRROR="${ELECTRON_BUILDER_BINARIES_MIRROR:-https://npmmirror.com/mirrors/electron-builder-binaries/}"
  export PLAYWRIGHT_DOWNLOAD_HOST="${PLAYWRIGHT_DOWNLOAD_HOST:-https://npmmirror.com/mirrors/playwright}"
  export PUPPETEER_DOWNLOAD_BASE_URL="${PUPPETEER_DOWNLOAD_BASE_URL:-https://npmmirror.com/mirrors/chrome-for-testing}"
  export SASS_BINARY_SITE="${SASS_BINARY_SITE:-https://npmmirror.com/mirrors/node-sass}"

  # uv python-build-standalone (GitHub Releases; same layout as npmmirror binary)
  export UV_PYTHON_INSTALL_MIRROR="${UV_PYTHON_INSTALL_MIRROR:-https://registry.npmmirror.com/-/binary/python-build-standalone}"
fi

unset -f _my_utils_mirrors_cn
