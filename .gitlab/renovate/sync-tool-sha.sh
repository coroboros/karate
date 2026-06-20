#!/usr/bin/env bash
# Re-sync row checksums and Dockerfile defaults.
set -euo pipefail

sha256_of() {
  local tmp; tmp="$(mktemp)"
  curl -fsSL "$1" -o "$tmp"
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$tmp" | cut -d' ' -f1
  else shasum -a 256 "$tmp" | cut -d' ' -f1; fi
}

set_arg() { sed -i.bak -E "s|(^ARG ${2}=\")[^\"]+(\")|\1${3}\2|" "${1}" && rm -f "${1}.bak"; }
set_env() { sed -i.bak -E "s|(^${2}=\")[^\"]+(\")|\1${3}\2|" "${1}" && rm -f "${1}.bak"; }

sync_row() {
  local row_env="$1" row_dir row_dockerfile sha
  row_dir="$(dirname "${row_env}")"
  row_dockerfile="${row_dir}/Dockerfile"

  # shellcheck source=/dev/null
  . "${row_env}"

  if [ -z "${KARATE_VERSION:-}" ] || [ -z "${KARATE_JAVA_RUNTIME:-}" ] || [ -z "${KARATE_JAVA_IMAGE:-}" ]; then
    echo "Karate image row is incomplete: ${row_env}" >&2
    exit 1
  fi

  sha="$(sha256_of "https://github.com/karatelabs/karate/releases/download/v${KARATE_VERSION}/karate-${KARATE_VERSION}.jar")"

  set_env "${row_env}" KARATE_SHA256 "${sha}"
  set_arg "${row_dockerfile}" KARATE_VERSION "${KARATE_VERSION}"
  set_arg "${row_dockerfile}" KARATE_SHA256 "${sha}"
  set_arg "${row_dockerfile}" KARATE_JAVA_RUNTIME "${KARATE_JAVA_RUNTIME}"
  set_arg "${row_dockerfile}" KARATE_JAVA_IMAGE "${KARATE_JAVA_IMAGE}"

  echo "karate SHA-256 re-synced to ${KARATE_VERSION} in ${row_env}"
}

while IFS= read -r row_env; do
  sync_row "${row_env}"
done < <(find images -mindepth 2 -maxdepth 2 -name image.env | sort)
