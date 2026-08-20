#!/usr/bin/env bash

cd "$(basename "$0")" || exit 1

RELEASE_TAG=v0.0.0-ManifestTest
TEMPLATE_FILE=rml-mod.json
TARGET_FILE=manifest-tested.json
OVERRIDE_SAME_VERSION=false

FAILED=0

fail() {
	echo "Failed test: $1" >&2
	(( FAILED++ ))
}

pushd "manifest-no-conflict" &&
cp manifest-before.json manifest-tested.json &&
../.github/workflows/compose-mod-manifest-for-tag.sh && 
diff -u manifest-tested.json manifest-after.json || fail "Normal merge"
popd

pushd "manifest-no-previous" &&
cp manifest-before.json manifest-tested.json &&
../.github/workflows/compose-mod-manifest-for-tag.sh && 
diff -u manifest-tested.json manifest-after.json || fail "No previous manifest"
popd

pushd "manifest-with-conflict" &&
cp manifest-before.json manifest-tested.json || fail "Setup of 'Failure due to conflict'"
../.github/workflows/compose-mod-manifest-for-tag.sh && fail "Failure due to conflict"
popd

OVERRIDE_SAME_VERSION=true
pushd "manifest-with-conflict" &&
cp manifest-before.json manifest-tested.json &&
../.github/workflows/compose-mod-manifest-for-tag.sh && 
diff -u manifest-tested.json manifest-after.json || fail "Overriding conflict"
popd

echo "Failed tests: $FAILED"
exit $FAILED