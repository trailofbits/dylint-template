#! /bin/bash

# set -x
set -euo pipefail

if [[ $# -lt 1 || $# -ge 3 ]]; then
    echo "Usage: $(basename $0) CLIPPY_LINT_NAME [NEW_LINT_NAME]" >&2
    exit 1
fi

REV=1a206fc4abae0b57a3f393481367cf3efca23586

CLIPPY_LOWER="$1"
if [[ $# -ge 2 ]]; then
    NEW_LOWER="$2"
else
    NEW_LOWER="$CLIPPY_LOWER"
fi

CLIPPY_UPPER="${CLIPPY_LOWER^^}"
NEW_UPPER="${NEW_LOWER^^}"

camelize() {
    UNDERSCORE=1
    while read -n1 X; do
        if [[ "$X" = '_' ]]; then
            UNDERSCORE=1
        elif [[ -n "$UNDERSCORE" ]]; then
            echo -n "${X^}"
            UNDERSCORE=
        else
            echo -n "$X"
        fi
    done
}

CLIPPY_CAMEL="$(echo -n "$CLIPPY_LOWER" | camelize)"
NEW_CAMEL="$(echo -n "$NEW_LOWER" | camelize)"

CLIPPY_KEBAB="$(echo -n "$CLIPPY_LOWER" | tr '_' '-')"
NEW_KEBAB="$(echo -n "$NEW_LOWER" | tr '_' '-')"

DST="$PWD"

SRC="$(mktemp -d --tmpdir rust-clippy.XXXXXX)"
git clone 'https://github.com/rust-lang/rust-clippy' "$SRC"
cd "$SRC"
git checkout "$REV" --quiet

if [[ ! -f "clippy_lints/src/$CLIPPY_LOWER.rs" ]]; then
    echo "$0: could not find '$CLIPPY_LOWER'"
    exit 1
fi

# Cargo.toml

sed -i "s/\<fill_me_in\>/$NEW_LOWER/g" "$DST/Cargo.toml"

# README.md

(
    echo "# $NEW_LOWER"
    echo
    cat "clippy_lints/src/$CLIPPY_LOWER.rs" |
    sed -n 's,^[[:space:]]*///[[:space:]]*\(.*\)$,\1,;T;p'
) > "$DST/README.md"

# src/lib.rs

sed -i "
    s/\<fill_me_in\>/$NEW_LOWER/g;
    s/\<FILL_ME_IN\>/$NEW_UPPER/g;
    s/\<FillMeIn\>/$NEW_CAMEL/g
" "$DST/src/lib.rs"

# src/fill_me_in.rs

cat "clippy_lints/src/$CLIPPY_LOWER.rs" |
sed "
    s/\<crate::consts\>/clippy_utils::consts/g
    s/\<crate::utils\>/clippy_utils/g
    s/\<declare_clippy_lint\>/declare_lint/g
    s/\<declare_tool_lint\>/declare_lint/g
    s/\<restriction\|pedantic\|style\|complexity\|correctness\|perf\|cargo\|nursery\>/Warn/g
    s/\<$CLIPPY_LOWER\>/$NEW_LOWER/g
    s/\<$CLIPPY_UPPER\>/$NEW_UPPER/g
    s/\<$CLIPPY_CAMEL\>/$NEW_CAMEL/g
" |
cat > "$DST/src/fill_me_in.rs"

mv "$DST/src/fill_me_in.rs" "$DST/src/$NEW_LOWER.rs"

# ui/main.rs

cat "tests/ui/$CLIPPY_LOWER.rs" |
sed "s/\<clippy::$CLIPPY_LOWER\>/$NEW_LOWER/g" |
cat > "$DST/ui/main.rs"

mv "$DST/ui/main.rs" "$DST/ui/$NEW_LOWER.rs"

# ui/main.stderr

cat "tests/ui/$CLIPPY_LOWER.stderr" |
sed "s/\<clippy::$CLIPPY_KEBAB\>/$NEW_KEBAB/g" |
cat > "$DST/ui/main.stderr"

mv "$DST/ui/main.stderr" "$DST/ui/$NEW_LOWER.stderr"
