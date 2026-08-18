#!/usr/bin/env bash

TAG=v1.2.3.4-blah

#hardcoded pattern as it is not customizable but a fixed part of the release logic anyway
PATTERN="v([0-9]\\.[0-9]\\.[0-9])\\.[0-9]+-.*"
echo "$PATTERN"
[[ "$TAG" =~ $PATTERN ]]
VERSION="${BASH_REMATCH[1]}"
echo "$VERSION"

#TODO: warn/error when version already exists in manifest (override option)

TEMPLATE="$(jq .versionTemplate rml-mod.json)"
echo "$TEMPLATE"
#TODO: hashsums
VERSION_DESCRIPTION="$(jq 'walk(if type == "string" then gsub("%VERSION%"; $version) | gsub("%TAG%"; $tag) else . end)' --arg tag "$TAG" --arg version "$VERSION" < <( printf %s "$TEMPLATE" ))"
echo "$VERSION_DESCRIPTION"
jq '. | del(.versionTemplate) | .[$version] = $versionDescription' rml-mod.json --arg version "$VERSION" --argjson versionDescription "$VERSION_DESCRIPTION"

