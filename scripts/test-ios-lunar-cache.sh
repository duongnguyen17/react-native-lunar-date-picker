#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
build_dir="$(mktemp -d)"
trap 'rm -rf "$build_dir"' EXIT

swiftc \
  -module-cache-path "$build_dir/module-cache" \
  -emit-library \
  -emit-module \
  -module-name UIKit \
  "$repo_root/scripts/ios-lunar-cache-regression/UIKitStub.swift" \
  -o "$build_dir/libUIKit.dylib" \
  -emit-module-path "$build_dir/UIKit.swiftmodule"

swiftc \
  -module-cache-path "$build_dir/module-cache" \
  -I "$build_dir" \
  -L "$build_dir" \
  -lUIKit \
  "$repo_root/ios/utils/LunarPersistentCache.swift" \
  "$repo_root/scripts/ios-lunar-cache-regression/main.swift" \
  -o "$build_dir/cache-regression"

DYLD_LIBRARY_PATH="$build_dir${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}" \
  "$build_dir/cache-regression"
