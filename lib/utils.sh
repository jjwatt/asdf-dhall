
set -euo pipefail

TOOL_NAME="dhall"
# TOOL_TEST="dhall --help"

curl_opts=(-fsSL)
url=https://api.github.com/repos/dhall-lang/dhall-haskell/releases/tags

get_os_arch() {
  local name
  name="$(uname)"
  name="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
  case "$name" in
    linux*)
      export ASDF_OSARCH=Linux
      ;;
    darwin*)
      export ASDF_OSARCH=macos
      ;;
    *)
      fail "Platform not supported: $name."
  esac
  printf "%s\n" "$ASDF_OSARCH"
}

fail() {
  printf "asdf-%s: %s" "$TOOL_NAME" "$*"
}

get_download_urls() {
  local version="$1"
  local os_arch="$2"
  curl  "${curl_opts[@]}" "${url}/$version" \
  | grep 'download_url' \
  | grep "$os_arch" \
  | cut -d: -f2-
}

download_release() {
  # args: version os_arch [ download_path ]
  local version os_arch download_path
  version="$1"
  os_arch="$2"
  download_path="${3-}"
  # download_path is optional

  if [ -z "$download_path" ]; then
    if [ -z "${ASDF_DOWNLOAD_PATH-}" ]; then
      ASDF_DOWNLOAD_PATH="$(mktemp -d "${TMPDIR:-/tmp}"/asdf-dhall.XXX)"
    fi  
    download_path="$ASDF_DOWNLOAD_PATH"
    echo "in if condition: download_path: $download_path"
  fi
  printf "* Downloading %s release %s from %s\n" \
    "${TOOL_VERSION-}" \
    "$version" \
    "$url"

  printf "DEBUG: Downloading to %s\n" "$download_path"
  get_download_urls "$version" "$os_arch" \
    | xargs -P"${ASDF_CONCURRENCY:-1}" -I{} \
    sh -c "curl -sSfL {} | tar -jx -C $download_path"
}

install_version() {
  local install_type version install_path
  install_type="$1"
  version="$2"
  install_path="$3"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi
  (
    cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"
    printf "%s %s installation successful\n" \
      "$TOOL_NAME" \
      "$version"
  ) || (
    rm -rf "$install_path"
    fail "There was an error installing $TOOL_NAME $version. Cleaning up."
  )
}
