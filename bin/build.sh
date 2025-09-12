#!/usr/bin/env bash

cleanup() {
  rm -f "$TMP_FEED"
  echo "- $TMP_FEED" >&2
}
trap cleanup EXIT

set -euo pipefail

SRC_DIR="src"
BUILD_DIR="build"
TMP_FEED=$(mktemp /tmp/feed-XXXXXXX.yaml)
echo "+ $TMP_FEED" >&2

PYTHON="python3"
GENERATE_FEED="bin/generate_feed.py"

HTML_HEADER="${SRC_DIR}/static/header.html"
HTML_FOOTER="${SRC_DIR}/static/templates/footer.html"
FORMAT_OPTIONS="-s -f markdown -t html"

INDEX_FILE="${BUILD_DIR:=build}/index.html"
STYLE_FILE="${BUILD_DIR}/style.css"
ATOM_FILE="${BUILD_DIR:=build}/atom.xml"

INDEX_TEMPLATE="${SRC_DIR}/static/templates/index.html"
POST_TEMPLATE="${SRC_DIR}/static/templates/post.html"
ATOM_TEMPLATE="${SRC_DIR}/static/templates/atom.xml"

pandoc_md_to_html() {
    local src_md=$1
    local dst_html=$2
    mkdir -p "$(dirname "$dst_html")"
    pandoc ${FORMAT_OPTIONS} --toc \
        --template="${POST_TEMPLATE}" \
        -V "atom-path:../" -V "main-path:../" -V "images-path:../" \
        --css=../style.css --quiet "$src_md" -o "$dst_html" < /dev/null
    echo "${src_md} -> ${dst_html}" >&2
}

generate_index() {
    pandoc ${FORMAT_OPTIONS} --template="${INDEX_TEMPLATE}" \
        -V "atom-path:./" -V "image-path:./" \
        --css=style.css \
        --metadata-file="${TMP_FEED}" --quiet -o "${INDEX_FILE}" < /dev/null
    echo "$INDEX_TEMPLATE -> $INDEX_FILE" >&2
}

generate_atom() {
    "${PYTHON}" "${GENERATE_FEED}" "${TMP_FEED}"
    echo "${GENERATE_FEED} -> ${TMP_FEED}" >&2
    pandoc --metadata-file="${TMP_FEED}" \
        --template="${ATOM_TEMPLATE}" \
        -t html -o "${ATOM_FILE}" < /dev/null
    echo "$ATOM_TEMPLATE -> $ATOM_FILE" >&2
}

copy_style() {
    cp "${SRC_DIR}/static/style.css" "${STYLE_FILE}"
    echo "$SRC_DIR/static/style.css -> $STYLE_FILE" >&2
}

copy_images() {
    mkdir -p "${BUILD_DIR}/images"
    cp "${SRC_DIR}/static/images/"* "${BUILD_DIR}/images/"
    echo "$SRC_DIR/static/images/* -> $BUILD_DIR/images/*" >&2
}

clean() {
    rm -f "${TMP_FEED}"
    rm -f "${BUILD_DIR}"/*.html "${BUILD_DIR}"/*.xml "${TARGET_STYLE_FILE}"
    rm -rf "${BUILD_DIR}/images"
}

while IFS= read -r -d '' md_file; do
    rel_path="${md_file#${SRC_DIR}/}"
    html_path="${BUILD_DIR}/${rel_path%.md}.html"
    pandoc_md_to_html "$md_file" "$html_path"
done < <(find "${SRC_DIR}" -name '*.md' -print0)

copy_style
generate_atom
generate_index
copy_images
