#!/bin/bash
set -e

repo='ip4368/node-armhf';

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
echo "Reason: provide armhf support"
echo "GitRepo: ${url}.git"
echo

# push all version aliases
push() {
	local version;
	for version in "$@"
	do
		echo "Pushing $repo:$version"
		docker push $repo:$version
	done
}

for version in "${versions[@]}"; do
	# Skip "docs" and other non-docker directories
	[ -f "$version/Dockerfile" ] || continue
	
	eval stub=$(echo "$version" | awk -F. '{ print "$array_" $1 "_" $2 }');
	fullVersion="$(grep -m1 'ENV NODE_VERSION ' "$version/Dockerfile" | cut -d' ' -f3)"

	versionAliases=( $fullVersion $version ${stub} )

	push ${versionAliases[@]}
	echo

	variants=$(echo $version/*/ | xargs -n1 basename)
	for variant in $variants; do
		# Skip non-docker directories
		[ -f "$version/$variant/Dockerfile" ] || continue
		
		slash='/'
		variantAliases=( "${versionAliases[@]/%/-${variant//$slash/-}}" )
		variantAliases=( "${variantAliases[@]//latest-/}" )

		push ${variantAliases[@]}
		echo
	done
done
