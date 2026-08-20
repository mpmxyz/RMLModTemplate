#!/usr/bin/env bash

RELEASE_TAG=${RELEASE_TAG:-${1:?Expected: \$RELEASE_TAG or \$1}}
TEMPLATE_FILE=${TEMPLATE_FILE:-rml-mod.json}
TARGET_FILE=${TARGET_FILE:-TODO_TemplateRMLAuthorID/TODO_TemplateModName/info.json}
OVERRIDE_SAME_VERSION=${OVERRIDE_SAME_VERSION:-false}

#hardcoded pattern as it is not customizable but a fixed part of the release logic anyway
PATTERN="v([0-9]\\.[0-9]\\.[0-9])-.*"

if [[ "$RELEASE_TAG" =~ $PATTERN ]]
then
	VERSION="${BASH_REMATCH[1]}"
	echo "$VERSION"

	if [ -r "$TARGET_FILE" ]
	then
		PREVIOUS_MANIFEST="$(jq . "$TARGET_FILE")" || exit 1
	else
		PREVIOUS_MANIFEST='{}'
	fi

	if jq -n --exit-status '$manifest.versions | has($version)' --argjson manifest "$PREVIOUS_MANIFEST" --arg version "$VERSION" >/dev/null
	then
		if [ "$OVERRIDE_SAME_VERSION" = 'true' ]
		then
			echo "WARNING: Version already exists!"
			echo "Overriding..."
		else
			echo "ERROR: Version already exists!" >&2
			exit 99
		fi
	fi

	TEMPLATE="$(jq . "$TEMPLATE_FILE")" || exit 2
	echo "Template: $TEMPLATE"

#	echo "$VERSION_TEMPLATE"
	#Insert Versions
	RAW_VERSION_DESCRIPTION="$(jq -n '$template.versionTemplate | walk(if type == "string" then gsub("%VERSION%"; $version) | gsub("%TAG%"; $tag) else . end)' --arg tag "$RELEASE_TAG" --arg version "$VERSION" --argjson template "$TEMPLATE" )" || exit 3
	echo "Raw version description: $RAW_VERSION_DESCRIPTION"
	
	echo "Extracting URLs..."
	mapfile -d '' URLS < <( jq -n --raw-output0 '$description.artifacts[].url' --argjson description "$RAW_VERSION_DESCRIPTION" ) || exit 4
	
	echo "Computing hashsums..."
	declare -a HASHSUMS
	for URL in "${URLS[@]}"
	do
		echo "Hashing $URL..."
		HASHSUM="$( set -o pipefail ; curl --location --fail "$URL" | sha256sum | grep -m 1 -Eo '^\S+' )" || exit 5
		echo "->$HASHSUM"
		HASHSUMS+=( "$HASHSUM" )
	done
	
	echo "Injecting Hashsums..."
	VERSION_DESCRIPTION="$(jq -n '$description | .artifacts |= (to_entries | map(.value.sha256=$ARGS.positional[.key] | .value) )' --argjson description "$RAW_VERSION_DESCRIPTION" --args "${HASHSUMS[@]}")" || exit 6
	echo "Final version description: $VERSION_DESCRIPTION"
	
	echo "Merging into existing..."
	MERGED_MANIFEST="$( jq -n '$template | del(.versionTemplate) | .versions=$manifest.versions | .versions[$version] = $versionDescription' --argjson template "$TEMPLATE" --argjson manifest "$PREVIOUS_MANIFEST" --arg version "$VERSION" --argjson versionDescription "$VERSION_DESCRIPTION" )" || exit 7

	diff -bu <( printf %s "$PREVIOUS_MANIFEST" ) <( printf %s "$MERGED_MANIFEST")

	mkdir -p "$(dirname "$TARGET_FILE")"
	echo "$MERGED_MANIFEST" > "$TARGET_FILE"
else
	echo "Tag $RELEASE_TAG does not match expected pattern $PATTERN!"
	exit 8
fi
