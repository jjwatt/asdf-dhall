
get_download_urls() {
  curl -sSfL "https://api.github.com/repos/dhall-lang/dhall-haskell/releases/tags/$1" \
  | grep 'download_url' \
  | grep "$2" \
  | cut -d: -f2-
}

[ "$(uname)" = Darwin ] && os_arch=macos || os_arch=Linux
[ -z "$ASDF_CONCURRENCY" ] && concurrency=1 || concurrency="$ASDF_CONCURRENCY"
