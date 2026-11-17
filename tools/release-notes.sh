#!/usr/bin/env bash
set -euo pipefail
awk -v heading="## $1" '$0 == heading { isInside = 1; next } /^## / { isInside = 0 } isInside' CHANGELOGS.md
