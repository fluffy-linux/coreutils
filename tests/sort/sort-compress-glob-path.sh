#!/bin/sh
# Test that sort finds --compress-program through wildcard PATH entries.

# Copyright (C) 2026 Free Software Foundation, Inc.

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

. "${srcdir=.}/tests/init.sh"; path_prepend_ ./src
print_ver_ sort

sort_=$(command -v sort) || framework_failure_
seq -w 2000 > exp || framework_failure_
tac exp > in || framework_failure_

mkdir -p pkg/a/bin pkg/b/bin cwd || framework_failure_
cat <<EOF > pkg/b/bin/fzip || framework_failure_
#!$SHELL
tr 41 14
touch "$PWD/ok"
EOF
chmod +x pkg/b/bin/fzip || framework_failure_

# The program is found in the second package through "<prefix>/*/bin".
PATH="$PWD/pkg/*/bin:$PATH" sort -S 1k --compress-program=fzip in > out \
  || fail=1
compare exp out || fail=1
test -f ok || fail=1
rm -f ok

# A leading empty PATH element means the current directory, which has no
# fzip; the wildcard element after it still supplies the program.
(cd cwd && PATH=":$PWD/../pkg/*/bin:$PATH" \
   sort -S 1k --compress-program=fzip ../in > ../out) || fail=1
compare exp out || fail=1
test -f ok || fail=1
rm -f ok

# A PATH element naming a regular file reports "Not a directory" rather
# than "No such file or directory" when nothing is found.
cat <<\EOF > exp-err
sort: could not run compress program 'missing': Not a directory
EOF
PATH="$PWD/pkg/b/bin/fzip" "$sort_" --compress-program=missing -S 1k in \
  > out 2> err || fail=1
compare exp out || fail=1
compare exp-err err || fail=1

Exit $fail
