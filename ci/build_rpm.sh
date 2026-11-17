#!/bin/sh
# Godot -> RPM for Aurora OS, based on the GitVerse reference template.
set -eu
GODOT_RELEASE_URL="https://github.com/savegame/godot/releases/download/4.4.1-auroraos-4"
GODOT_EDITOR_FILE="Godot.linuxbsd.editor.x86_64"
PCK_PRESET_NAME="Linux"
SPEC_FILE="rpm/ru.arinapig.meown.spec"
CACHE_DIR="${CACHE_DIR:-/tmp/godot-aurora-cache}"
if [ "$#" -gt 0 ]; then VERSION="$1"
elif [ -s .version ]; then VERSION="$(cat .version)"
else VERSION="0.1.0"
fi
if [ "$#" -gt 0 ]; then shift; fi
ARCHITECTURES="${*:-aarch64 armv7hl}"
mkdir -p "$CACHE_DIR" build out

# The reference Aurora build currently ships Godot 4.4.1. Meown is Godot 4.7.x.
# Stop instead of silently trying to export a newer project with an older editor.
if grep -q 'config/features=PackedStringArray("4.7"' project.godot; then
    echo "ERROR: Meown targets Godot 4.7.x, while this Aurora template uses Godot 4.4.1." >&2
    echo "Resolve the Aurora-supported engine version before enabling RPM builds." >&2
    exit 2
fi

download_if_missing() {
    file_name="$1"
    if [ ! -s "${CACHE_DIR}/${file_name}" ]; then
        curl -fSL --retry 3 -o "${CACHE_DIR}/${file_name}" "${GODOT_RELEASE_URL}/${file_name}"
    fi
}
echo ">> Package version: ${VERSION}; architectures: ${ARCHITECTURES}"
sed -i "s/^Version:.*/Version: ${VERSION}/" "$SPEC_FILE"
download_if_missing "$GODOT_EDITOR_FILE"
chmod +x "${CACHE_DIR}/${GODOT_EDITOR_FILE}"
"${CACHE_DIR}/${GODOT_EDITOR_FILE}" --headless --editor --path . --quit
"${CACHE_DIR}/${GODOT_EDITOR_FILE}" --headless --path . --export-pack "$PCK_PRESET_NAME" build/game.pck
test -s build/game.pck

PATCHELF_ARCHIVE="patchelf-0.18.0-x86_64.tar.gz"
if [ ! -s "${CACHE_DIR}/${PATCHELF_ARCHIVE}" ]; then
    curl -fSL --retry 3 -o "${CACHE_DIR}/${PATCHELF_ARCHIVE}" "https://github.com/NixOS/patchelf/releases/download/0.18.0/${PATCHELF_ARCHIVE}"
fi
tar -xzf "${CACHE_DIR}/${PATCHELF_ARCHIVE}" -C build ./bin/patchelf
mv build/bin/patchelf build/patchelf
chmod +x build/patchelf

SIGN_KEY="certs/regular_key.pem"
SIGN_CERT="certs/regular_cert.pem"
test -s "$SIGN_KEY"
test -s "$SIGN_CERT"
for architecture in $ARCHITECTURES; do
    case "$architecture" in
        aarch64) template_file="godot.auroraos.template_release.arm64" ;;
        armv7hl) template_file="godot.auroraos.template_release.arm32" ;;
        *) echo "ERROR: unsupported architecture: $architecture" >&2; exit 1 ;;
    esac
    download_if_missing "$template_file"
    cp "${CACHE_DIR}/${template_file}" build/godot-template
    rm -rf RPMS
    apptool build -s "$SPEC_FILE" "--${architecture}" --nosign
    set -- RPMS/*.rpm
    [ -s "$1" ] || { echo "ERROR: apptool did not produce RPM for $architecture" >&2; exit 1; }
    echo "" | apptool sign --key "$SIGN_KEY" --cert "$SIGN_CERT" "$@"
    cp "$@" out/
done
ls -l out/
