#!/usr/bin/env bash
set -euo pipefail

if [ $# -lt 1 ] || [ $# -gt 2 ]; then
  echo "Usage: $0 <manifest-path> [platform-tag]" >&2
  exit 2
fi

manifest_path="$1"
platform_tag="${2:-linux-x86_64}"

if [ ! -f "${manifest_path}" ]; then
  echo "Manifest file not found: ${manifest_path}" >&2
  exit 1
fi

version_seen=0
artifact_count=0
line_no=0

while IFS= read -r raw_line || [ -n "${raw_line}" ]; do
  line_no=$((line_no + 1))
  line="$(printf '%s' "${raw_line}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ -z "${line}" ] || [ "${line#\#}" != "${line}" ]; then
    continue
  fi

  IFS='|' read -r record_type name version platform url_primary url_mirror sha256 signature extra <<< "${line}"
  if [ -n "${extra:-}" ]; then
    echo "Invalid line ${line_no}: too many fields" >&2
    exit 1
  fi

  case "${record_type}" in
    manifest_version)
      if [ -z "${name}" ]; then
        echo "Invalid line ${line_no}: empty manifest version" >&2
        exit 1
      fi
      version_seen=1
      ;;
    artifact)
      if ! printf '%s' "${name}" | grep -Eq '^[A-Za-z0-9._-]+$'; then
        echo "Invalid line ${line_no}: bad artifact name '${name}'" >&2
        exit 1
      fi
      if [ -z "${version}" ]; then
        echo "Invalid line ${line_no}: empty artifact version" >&2
        exit 1
      fi
      if [ -z "${platform}" ]; then
        echo "Invalid line ${line_no}: empty platform" >&2
        exit 1
      fi
      if [ -z "${url_primary}" ] || [ "${url_primary}" = "-" ]; then
        echo "Invalid line ${line_no}: primary URL required" >&2
        exit 1
      fi
      if ! printf '%s' "${url_primary}" | grep -Eq '^(https?|file)://'; then
        echo "Invalid line ${line_no}: primary URL must be http(s):// or file://" >&2
        exit 1
      fi
      if ! printf '%s' "${sha256}" | grep -Eq '^[a-fA-F0-9]{64}$'; then
        echo "Invalid line ${line_no}: invalid sha256 '${sha256}'" >&2
        exit 1
      fi
      if [ "${platform}" = "${platform_tag}" ] || [ "${platform}" = "all" ]; then
        artifact_count=$((artifact_count + 1))
      fi
      ;;
    *)
      echo "Invalid line ${line_no}: unknown record type '${record_type}'" >&2
      exit 1
      ;;
  esac
done < "${manifest_path}"

if [ "${version_seen}" -ne 1 ]; then
  echo "Manifest validation failed: manifest_version record missing" >&2
  exit 1
fi

if [ "${artifact_count}" -eq 0 ]; then
  echo "Manifest validation failed: no artifacts for platform ${platform_tag}" >&2
  exit 1
fi

echo "Manifest validation passed: ${manifest_path} (platform=${platform_tag}, artifacts=${artifact_count})"
