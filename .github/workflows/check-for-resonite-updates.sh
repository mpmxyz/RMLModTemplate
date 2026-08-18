#!/usr/bin/env bash

: ${GITHUB_OUTPUT:?}
: ${REPOSITORY_NAME:?}
: ${GITHUB_REPOSITORY_OWNER:?}

echo "Checking for current Resonite version..."
SAFE_VERSION_PATTERN='^[a-zA-Z0-9_\.\-]+$' #SECURITY: prevents interpretation when written into $GITHUB_OUTPUT
if ! RESONITE_VERSION="$( curl -s https://raw.githubusercontent.com/$GITHUB_REPOSITORY_OWNER/ResoniteAssemblies/refs/heads/main/Assemblies/RESONITE_VERSION | head -n 1 | tr -d '\r\n ' )"
then
	echo "Make sure you own a fork of https://github.com/mpmxyz/ResoniteAssemblies!" >&2
	echo "While it would be possible to depend on someone else's fork it can be maintained easily without being dependent on other people's actions." >&2
	exit 1
fi
if [[ ! "$RESONITE_VERSION" =~ $SAFE_VERSION_PATTERN ]]
then
	echo "Invalid Resonite version '$RESONITE_VERSION'!" >&2
	exit 2
fi

echo "Searching for release tags built with Resonite $RESONITE_VERSION..."
MATCHING_RELEASES="$( git ls-remote --tags "https://github.com/$REPOSITORY_NAME" "*-$RESONITE_VERSION" )" || exit 3
if printf %s "$MATCHING_RELEASES" | grep -Fq -- "-$RESONITE_VERSION" && [ -z "$FORCE_RELEASE" ]
then
	printf "Found:\n%s\n" "$MATCHING_RELEASES"
	if printf %s "$MATCHING_RELEASES" | grep -Fqv -- "failed-$RESONITE_VERSION"
	then
	echo "Cancelling release workflow..."
	echo "UP_TO_DATE=true" >> "$GITHUB_OUTPUT"
	else
	echo "No release found, only failures..."
	exit 99 #fails the workflow so no build is attempted (new pushes with bug fixes trigger build-release directly)
	fi
else
	echo "No matching releases found!"
	echo "Continuing with release workflow..."
	echo "RESONITE_VERSION=$RESONITE_VERSION" >> "$GITHUB_OUTPUT"
fi