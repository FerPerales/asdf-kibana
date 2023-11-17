#!/usr/bin/env bash

set -euo pipefail

GH_REPO="https://github.com/elastic/kibana"
TOOL_NAME="kibana"
TOOL_TEST="kibana --help"
MULTIPLE_ARCH_VERSION="7.16.0"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

curl_opts=(-fsSL)

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_github_tags() {
	git ls-remote --tags --refs "$GH_REPO" |
		grep -o 'refs/tags/v\d*\.\d*.\d*$' | cut -d/ -f3- |
		sed 's/^v//' # NOTE: You might want to adapt this sed to remove non-version strings from tags
}

list_all_versions() {
	# TODO: Adapt this. By default we simply list the tag names from GitHub releases.
	# Change this function if kibana has other means of determining installable versions.
	list_github_tags
}

download_release() {
	local version filename url arch operative_system kibana_version
	version="$1"
	filename="$2"
	arch="$(uname -p)"
	operative_system="$(uname -a)"

	if [[ "$operative_system" =~ "Darwin" ]]; then
		if [ "$(version "$version")" -lt "$(version "7.16.0")" ]; then
			if [[ "$arch" == "i386" ]]; then
				kibana_version="${version}-darwin-x86_64"
			else
				kibana_version="${version}-aarch64"
			fi
		else
			echo "Kibana versions prior to $MULTIPLE_ARCH_VERSION do not offer an ARM-specific build. Using x86_64..."
			kibana_version="${version}-darwin-x86_64"
		fi
	else
		fail "asdf-$TOOL_NAME only supports MacOS at the moment"
	fi

	url="https://artifacts.elastic.co/downloads/kibana/kibana-${kibana_version}.tar.gz"

	echo "* Downloading $TOOL_NAME release $version..."
	curl "${curl_opts[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

# From https://github.com/asdf-community/asdf-elasticsearch/blob/3b57cc541b64a09cf0b95543457471fbe803abbb/bin/install#L78
version() {
	echo "$@" | awk -F. '{ printf("%d%03d%03d%03d\n", $1,$2,$3,$4); }'
}


install_version() {
	local install_type="$1"
	local version="$2"
	local install_path="${3%/bin}/bin"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	(
		mkdir -p "$install_path"
		cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

		local tool_cmd
		tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
		chmod +x "$install_path/$tool_cmd"
		test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
