#!/usr/bin/env bash
set -euo pipefail

fail=0

check_eq() {
  local name="$1" actual="$2" expected="$3"
  if [ "${actual}" != "${expected}" ]; then
    echo "FAIL ${name}: expected ${expected}, got ${actual:-<empty>}" >&2
    fail=1
  fi
}

check_nonempty() {
  local name="$1" value="$2"
  if [ -z "${value}" ]; then
    echo "FAIL ${name}: empty" >&2
    fail=1
  fi
}

component_tag="$(
  sed -nE 's|^[[:space:]]+default: "registry\.gitlab\.com/coroboros/infrastructure/karate:([^"]+)".*|\1|p' templates/karate.yml | head -1
)"

allowed_tags="$(
  find images -mindepth 2 -maxdepth 2 -name image.env | sort |
  while IFS= read -r env_file; do
    # shellcheck source=/dev/null
    . "${env_file}"
    printf '%s-%s\n' "${KARATE_VERSION}" "${KARATE_JAVA_RUNTIME}"
  done |
  sort -u
)"

check_nonempty allowed-tags "${allowed_tags}"
check_nonempty component-image "${component_tag}"

if ! printf '%s\n' "${allowed_tags}" | grep -qxF "${component_tag}"; then
  echo "FAIL component-image: ${component_tag} is not declared in images/" >&2
  fail=1
fi

while IFS= read -r env_file; do
  row_dir="$(dirname "${env_file}")"
  row_tag="$(basename "${row_dir}")"
  row_dockerfile="${row_dir}/Dockerfile"

  # shellcheck source=/dev/null
  . "${env_file}"

  docker_version="$(sed -nE 's/^ARG KARATE_VERSION="([^"]+)".*/\1/p' "${row_dockerfile}" | head -1)"
  docker_sha="$(sed -nE 's/^ARG KARATE_SHA256="([^"]+)".*/\1/p' "${row_dockerfile}" | head -1)"
  docker_runtime="$(sed -nE 's/^ARG KARATE_JAVA_RUNTIME="([^"]+)".*/\1/p' "${row_dockerfile}" | head -1)"
  docker_java_image="$(sed -nE 's/^ARG KARATE_JAVA_IMAGE="([^"]+)".*/\1/p' "${row_dockerfile}" | head -1)"
  expected_tag="${KARATE_VERSION}-${KARATE_JAVA_RUNTIME}"

  check_nonempty "karate-version:${row_tag}" "${KARATE_VERSION:-}"
  check_nonempty "karate-sha:${row_tag}" "${KARATE_SHA256:-}"
  check_nonempty "karate-runtime:${row_tag}" "${KARATE_JAVA_RUNTIME:-}"
  check_nonempty "karate-java-image:${row_tag}" "${KARATE_JAVA_IMAGE:-}"
  check_eq "row-dir:${row_tag}" "${row_tag}" "${expected_tag}"
  check_eq "docker-version:${row_tag}" "${docker_version}" "${KARATE_VERSION}"
  check_eq "docker-sha:${row_tag}" "${docker_sha}" "${KARATE_SHA256}"
  check_eq "docker-runtime:${row_tag}" "${docker_runtime}" "${KARATE_JAVA_RUNTIME}"
  check_eq "docker-java-image:${row_tag}" "${docker_java_image}" "${KARATE_JAVA_IMAGE}"
done < <(find images -mindepth 2 -maxdepth 2 -name image.env | sort)

while IFS= read -r tag; do
  [ -n "${tag}" ] || continue
  if ! printf '%s\n' "${allowed_tags}" | grep -qxF "${tag}"; then
    echo "FAIL stale karate image tag: ${tag}" >&2
    fail=1
  fi
done < <(
  grep -RhoE '[0-9]+\.[0-9]+\.[0-9]+-temurin[0-9]+' \
    .gitlab-ci.yml README.md templates skills images 2>/dev/null | sort -u
)

if grep -RhoE 'registry\.gitlab\.com/coroboros/infrastructure/karate:temurin[0-9]+([@"[:space:]]|$)' \
  README.md templates skills 2>/dev/null | grep -q .; then
  echo "FAIL stale rolling runtime image tag; use ${component_tag}" >&2
  fail=1
fi

if [ "${fail}" -ne 0 ]; then
  exit 1
fi

echo "karate version sync OK: ${component_tag}"
