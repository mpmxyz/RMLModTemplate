#!/usr/bin/env bash

cd "$(dirname "$0")" || exit 1

TESTED_SCRIPT="$( realpath ../.github/workflows/compose-mod-manifest-for-tag.sh )"

export RELEASE_TAG=v0.0.0-ManifestTest
export TEMPLATE_FILE=rml-mod.json
export TARGET_FILE=manifest-tested.json
export OVERRIDE_SAME_VERSION=false

FAILED=0

fail() {
	echo "Failed test: $1" >&2
	(( FAILED++ ))
}

test_stdout=/dev/null

pushd "manifest-no-conflict" &&
cp manifest-before.json manifest-tested.json &&
"$TESTED_SCRIPT" >"$test_stdout" && 
diff -bu manifest-tested.json manifest-after.json || fail "Normal merge"
popd

pushd "manifest-no-previous" &&
rm -f manifest-tested.json &&
"$TESTED_SCRIPT" >"$test_stdout" && 
diff -bu manifest-tested.json manifest-after.json || fail "No previous manifest"
popd

pushd "manifest-with-conflict" &&
cp manifest-before.json manifest-tested.json || fail "Setup of 'Failure due to conflict'"
"$TESTED_SCRIPT" >"$test_stdout" && fail "Failure due to conflict"
popd

export OVERRIDE_SAME_VERSION=true
pushd "manifest-with-conflict" &&
cp manifest-before.json manifest-tested.json &&
"$TESTED_SCRIPT" >"$test_stdout" && 
diff -bu manifest-tested.json manifest-after.json || fail "Overriding conflict"
popd

echo "Failed tests: $FAILED"

if [ "$FAILED" -eq 0 ]
then
	rm */manifest-tested.json
fi
exit $FAILED