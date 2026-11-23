#!/bin/sh
# Test env and timeout command lookup through wildcard PATH entries.

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
print_ver_ env timeout

env_=$(command -v env) || framework_failure_
timeout_=$(command -v timeout) || framework_failure_

mkdir -p pkg/a/bin pkg/b/bin || framework_failure_
printf '#!%s\nexit 0\n' "$SHELL" > pkg/b/bin/fluffy-probe || framework_failure_
chmod +x pkg/b/bin/fluffy-probe || framework_failure_

# env runs a program found through "<prefix>/*/bin".
PATH="$PWD/pkg/*/bin" "$env_" fluffy-probe || fail=1

# timeout does too, with a leading empty (current directory) element.
PATH=":$PWD/pkg/*/bin" "$timeout_" 10 fluffy-probe || fail=1

# A PATH element naming a regular file gives ENOTDIR, so env exits 126
# (found but not runnable) rather than 127 (not found).
returns_ 126 env PATH="$PWD/pkg/b/bin/fluffy-probe" \
  "$env_" no-such-command 2> /dev/null || fail=1

Exit $fail
