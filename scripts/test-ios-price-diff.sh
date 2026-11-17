#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

swiftc \
  "$repo_root/ios/utils/PriceUpdateDiff.swift" \
  "$repo_root/scripts/ios-price-diff-regression/main.swift" \
  -module-cache-path "$build_dir/module-cache" \
  -o "$build_dir/price-diff-regression"
"$build_dir/price-diff-regression"
