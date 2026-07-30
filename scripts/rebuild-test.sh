#!/bin/bash
#
# Rebuilds the local `test` branch from scratch: origin/master + every active branch.
#
# `test` is a disposable integration polygon for device testing. It is never pushed
# (see .githooks/pre-push), never merged anywhere, and never committed to directly
# (see .githooks/pre-commit). Instead of carrying history, it is thrown away and
# reassembled on every run — which is why a branch that has landed in master simply
# drops out of the set instead of producing conflicts against itself.
#
# Branch selection is opt-out: every local branch holding commits not yet in
# origin/master is merged in. To keep one out:
#
#     git config branch.<name>.notest true
#
# The flag lives in .git/config, so it is local and disappears with the branch.

# -e: stop on the first failing command, -u: unset variable is an error,
# -o pipefail: a failure anywhere in a pipeline fails the pipeline
set -euo pipefail

# Everything lives in main() so bash parses the whole file before running a line of
# it: the checkout below swaps the working tree to a branch that may carry a
# different version of this very script, and bash otherwise keeps reading the file
# as it executes.
main() {

cd "$(git rev-parse --show-toplevel)"

# `checkout -B` carries uncommitted changes across to test, and the merges below
# would then trip over them — this is exactly how stale "Auto stash before merge"
# entries accumulate. Refuse to start instead.
if [ -n "$(git status --porcelain)" ]; then
    echo "error: working tree is dirty, commit or stash before rebuilding" >&2
    exit 1
fi

# rerere replays conflict resolutions recorded during earlier rebuilds. Without it
# every run re-asks the same questions, which defeats the whole approach.
if [ "$(git config --get rerere.enabled || echo false)" != "true" ]; then
    echo "warning: rerere.enabled is not set, every rebuild will re-ask the same conflicts" >&2
    echo "         enable it with: git config --local rerere.enabled true" >&2
fi

git fetch origin

# --no-merged origin/master is the selection rule and the safety net at once: a
# branch whose commits are all in master cannot appear here, so a forgotten branch
# that has since been merged drops out on its own.
branches=""
while read -r branch; do
    # the polygon itself, and master, are never merged into the polygon
    if [ "$branch" = "test" ] || [ "$branch" = "master" ]; then
        continue
    fi

    if [ "$(git config --get "branch.$branch.notest" || echo false)" = "true" ]; then
        echo "skip (notest): $branch"
        continue
    fi

    branches="$branches $branch"
done <<EOF
$(git for-each-ref --format='%(refname:short)' --no-merged origin/master refs/heads)
EOF

echo
if [ -z "$branches" ]; then
    echo "nothing to integrate, test will be plain origin/master"
else
    echo "rebuilding test from origin/master with:"
    # branch names never contain spaces, so plain word splitting is safe here
    for branch in $branches; do
        echo "  $branch"
    done
fi
echo

# --no-track: test is local-only, an upstream would just produce noise about being
# ahead of origin/master and tempt git into pushing it
git checkout -B test --no-track origin/master

for branch in $branches; do
    echo "==> merging $branch"

    # --no-ff keeps every feature a distinct merge commit, so it is obvious on the
    # device build which branches went in
    if ! git merge --no-ff --no-edit "$branch"; then
        echo >&2
        echo "error: conflict merging $branch" >&2
        echo "       resolve it, run 'git commit' to record the resolution in rerere," >&2
        echo "       then re-run this script — the rebuild will replay it automatically" >&2
        exit 1
    fi
done

echo
echo "test rebuilt at $(git rev-parse --short HEAD)"

}

main "$@"
