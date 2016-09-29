#!/bin/bash
set -e

repo='ip4368/node-arm64';

array_4_6='4 argon';
array_6_7='6 latest';

cd $(cd ${0%/*} && pwd -P);

self="$(basename "$BASH_SOURCE")"

versions=( */ )
versions=( "${versions[@]%/}" )
url='https://github.com/ip4368/docker-node'

# sort version numbers with highest first
IFS=$'\n'; versions=( $(echo "${versions[*]}" | sort -r) ); unset IFS

echo "Maintainers: The Node.js Docker Team <${url}> (@nodejs)"
echo "Forked by: ip4368"
echo "Reason: provide arm64 support"
echo "GitRepo: ${url}.git"
echo

# push all version aliases
tag() {
	local original_tag=$1; shift
	local image_hash=$(docker images $repo | grep -m1 "$original_tag " | tr -s ' ' | cut -d' ' -f3)
	echo "Tagging images for $original_tag"
	echo "Selected image: $image_hash"
	local version;
	for version in "$@"
	do
		echo "Tagging $repo:$version with image $image_hash"
		docker tag $image_hash $repo:$version
	done
}

for version in "${versions[@]}"; do
	# Skip "docs" and other non-docker directories
	[ -f "$version/Dockerfile" ] || continue
	
	eval stub=$(echo "$version" | awk -F. '{ print "$array_" $1 "_" $2 }');
	fullVersion="$(grep -m1 'ENV NODE_VERSION ' "$version/Dockerfile" | cut -d' ' -f3)"

	versionAliases=( $fullVersion $version ${stub} )

	tag ${versionAliases[@]}
	echo

	variants=$(echo $version/*/ | xargs -n1 basename)
	for variant in $variants; do
		# Skip non-docker directories
		[ -f "$version/$variant/Dockerfile" ] || continue
		
		slash='/'
		variantAliases=( "${versionAliases[@]/%/-${variant//$slash/-}}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

		tag  ${variantAliases[@]}
		echo
	done
done
