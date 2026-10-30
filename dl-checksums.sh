#!/usr/bin/env sh
set -e
DIR=$(mktemp -d)
trap 'rm -rf "$DIR"' EXIT
GHUSER=DopplerHQ
GHREPO=cli
MIRROR="https://github.com/${GHUSER}/${GHREPO}/releases/download"
APP=doppler

dl() {
    local ver=$1
    local lchecksums=$2
    local os=$3
    local arch=$4
    local archive_type=${5:-tar.gz}
    local platform="${os}_${arch}"
    local file="${APP}_${ver}_${platform}.${archive_type}"
    local url="$MIRROR/$ver/$file"
    local sum
    sum=$(grep -F -- "  $file" "$lchecksums" | awk -v f="$file" '$2 == f {print $1}')
    if ! printf '%s' "$sum" | grep -Eq '^[0-9a-f]{64}$'; then
        echo "no valid sha256 for $file" >&2
        exit 1
    fi
    printf "    # %s\n" "$url"
    printf "    %s: sha256:%s\n" "$platform" "$sum"
}

dl_ver() {
    local ver=$1
    # https://github.com/DopplerHQ/cli/releases/download/3.69.1/checksums.txt
    local url="$MIRROR/$ver/checksums.txt"
    local lchecksums="$DIR/${APP}_${ver}_checksums.txt"
    curl -fsSL --proto '=https' --tlsv1.2 -o "$lchecksums" "$url"

    printf "  # %s\n" $url
    printf "  '%s':\n" $ver

    dl "$ver" "$lchecksums" freebsd amd64
    dl "$ver" "$lchecksums" freebsd arm64
    dl "$ver" "$lchecksums" freebsd armv6
    dl "$ver" "$lchecksums" freebsd armv7
    dl "$ver" "$lchecksums" linux amd64
    dl "$ver" "$lchecksums" linux arm64
    dl "$ver" "$lchecksums" linux armv6
    dl "$ver" "$lchecksums" linux armv7
    dl "$ver" "$lchecksums" linux i386
    dl "$ver" "$lchecksums" macOS amd64
    dl "$ver" "$lchecksums" macOS arm64
    dl "$ver" "$lchecksums" netbsd amd64
    dl "$ver" "$lchecksums" netbsd arm64
    dl "$ver" "$lchecksums" netbsd armv6
    dl "$ver" "$lchecksums" netbsd armv7
    dl "$ver" "$lchecksums" netbsd i386
    dl "$ver" "$lchecksums" openbsd amd64
    dl "$ver" "$lchecksums" openbsd arm64
    dl "$ver" "$lchecksums" openbsd armv6
    dl "$ver" "$lchecksums" openbsd armv7
    dl "$ver" "$lchecksums" openbsd i386
    dl "$ver" "$lchecksums" windows amd64 zip
    dl "$ver" "$lchecksums" windows arm64 zip
    # older releases also shipped these
    for arch in armv6 armv7
    do
        if grep -Fq -- "  ${APP}_${ver}_windows_${arch}.zip" "$lchecksums"
        then
            dl "$ver" "$lchecksums" windows "$arch" zip
        fi
    done
}

dl_ver "${1:-3.77.1}"
