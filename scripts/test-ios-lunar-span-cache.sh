#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

swiftc \
  "$repo_root/ios/models/LunarDate.swift" \
  "$repo_root/ios/utils/LunarMonthSpanCache.swift" \
  "$repo_root/ios/utils/LunarDateUtil.swift" \
  "$repo_root/scripts/ios-lunar-span-regression/ConstantsStub.swift" \
  "$repo_root/scripts/ios-lunar-span-regression/main.swift" \
  -module-cache-path "$build_dir/module-cache" \
  -o "$build_dir/lunar-span-regression"

"$build_dir/lunar-span-regression"
