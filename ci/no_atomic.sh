#!/bin/bash

# Update the list of targets that do not support atomic/CAS operations.
#
# Usage:
#    ./ci/no_atomic.sh

set -euo pipefail
IFS=$'\n\t'

cd "$(cd "$(dirname "$0")" && pwd)"/..

file="no_atomic.rs"

{
    echo "// This file is @generated by $(basename "$0")."
    echo "// It is not intended for manual editing."
    echo ""
} >"$file"

echo "const NO_ATOMIC_CAS: &[&str] = &[" >>"$file"
for target in $(rustc --print target-list); do
    res=$(rustc --print target-spec-json -Z unstable-options --target "$target" \
        | jq -r "select(.\"atomic-cas\" == false)")
    [[ -z "$res" ]] || echo "    \"$target\"," >>"$file"
done
echo "];" >>"$file"

# `"max-atomic-width" == 0` means that atomic is not supported at all.
{
    # Only crossbeam-utils actually uses this const.
    echo "#[allow(dead_code)]"
    echo "const NO_ATOMIC: &[&str] = &["
} >>"$file"
for target in $(rustc --print target-list); do
    res=$(rustc --print target-spec-json -Z unstable-options --target "$target" \
        | jq -r "select(.\"max-atomic-width\" == 0)")
    [[ -z "$res" ]] || echo "    \"$target\"," >>"$file"
done
echo "];" >>"$file"
