#!/bin/sh
# Copyright (c) 2024 Tomi Leppänen
#
# SPDX-License-Identifier: MIT

ORIG="$1"
NEW="$2"

if [ -z "$ORIG" ] || [ -z "$NEW" ]
then
    echo >&2 "Please specify both original and new data file"
    exit 1
fi

if ! awk '
function check()
{
    if (keys["iso:"] == 0) {
        print line": iso missing"
        issue=1
    }
    if (keys["name:"] == 0) {
        print line": name missing"
        issue=1
    }
    if (keys["capital:"] == 0) {
        print line": capital missing"
        issue=1
    }
    if (keys["region:"] == 0) {
        print line": region missing"
        issue=1
    }
}

BEGIN {
    issue=0
    line=-1
}

/^-$/ {
    if (line >= 0)
        check()
    line=NR
    keys["name:"]=0
    keys["alt:"]=0
    keys["capital:"]=0
    keys["region:"]=0
    keys["iso:"]=0
    keys["other:"]=0
    next
}

/^\s{8}\w+: "[^"]+"$/ {
    if (! $1 in array) {
        print NR": "$1" was not expected"
        issue=1
    }
    keys[$1]++
    if (keys[$1] > 1) {
        print NR": "$1" cannot be specified more than once per country"
        issue=1
    }
    next
}

/^\s{8}\w+: \["[^\]]+"\]$/ {
    if (! $1 in array) {
        print NR": "$1" was not expected"
        issue=1
    }
    keys[$1]++
    if (keys[$1] > 1) {
        print NR": "$1" cannot be specified more than once per country"
        issue=1
    }
    next
}

/^[^#]/ {
    print NR": INVALID LINE:"$0""
    issue=2
    exit 2
}

END {
    if (issue != 2) {
        check()
    }
    exit issue
}
' "$NEW" >&2
then
    exit 2
fi

if ! diff -s <(grep -E '^-$' "$ORIG") <(grep -E '^-$' "$NEW") > /dev/null
then
    echo >&2 "Files have different number of countries"
    exit 3
fi

if ! diff <(grep -E '^\s+iso: "\w{3}"$' "$ORIG") <(grep -E '^\s+iso: "\w{3}"$' "$NEW")
then
    echo >&2 "Bad iso codes or differing order"
    exit 4
fi

if ! diff <(sed -n '/^\s\+capital:/s/"[^"]\+"/""/gp' "$ORIG") <(sed -n '/^\s\+capital:/s/"[^"]\+"/""/gp' "$NEW")
then
    echo >&2 "Differing number of capitals"
    exit 5
fi

if grep -En '^\s+capital: .*;' "$NEW"
then
    echo >&2 "Capital name cannot contain ';'"
    exit 6
fi

if [ $(grep -E '^\s+region: ' "$ORIG" | sort -u | wc -l) != $(grep -E '^\s+region: ' "$NEW" | sort -u | wc -l) ]
then
    echo >&2 "Differing number of regions"
    exit 7
fi
