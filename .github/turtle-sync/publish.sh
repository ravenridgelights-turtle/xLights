#!/usr/bin/env bash
set -euo pipefail

expected_repo='ravenridgelights-turtle/xLights'
if [[ "${GITHUB_REPOSITORY:-}" != "$expected_repo" ]]; then
    echo 'This workflow only runs in the personal xLights fork.' >&2
    exit 1
fi
origin_url=$(git config --get remote.origin.url)
if [[ "$origin_url" != "https://github.com/$expected_repo" && "$origin_url" != "https://github.com/$expected_repo.git" ]]; then
    echo 'origin must be the personal fork.' >&2
    exit 1
fi
if [[ ! "$TURTLE_BASE_SHA" =~ ^[0-9a-f]{40}$ || ! "$TURTLE_CANDIDATE_SHA" =~ ^[0-9a-f]{40}$ || ! "$TURTLE_CANDIDATE_BRANCH" =~ ^turtle-sync/candidate-[0-9]+-[0-9]+$ ]]; then
    echo 'Invalid candidate metadata. Refusing to publish.' >&2
    exit 1
fi

git fetch --no-tags origin refs/heads/turtle-dev:refs/remotes/origin/turtle-dev "refs/heads/$TURTLE_CANDIDATE_BRANCH:refs/remotes/origin/$TURTLE_CANDIDATE_BRANCH"
current_sha=$(git rev-parse origin/turtle-dev)
if [[ "$current_sha" != "$TURTLE_BASE_SHA" ]]; then
    echo 'turtle-dev changed while the build ran. Run the workflow again; your newer commits are preserved.' >> "$GITHUB_STEP_SUMMARY"
    exit 1
fi
actual_candidate=$(git rev-parse "origin/$TURTLE_CANDIDATE_BRANCH")
if [[ "$actual_candidate" != "$TURTLE_CANDIDATE_SHA" ]]; then
    echo 'The candidate branch changed after its build. Refusing to publish.' >&2
    exit 1
fi
git merge-base --is-ancestor "$TURTLE_BASE_SHA" "$TURTLE_CANDIDATE_SHA"
backup="backup/turtle-before-sync-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
git push --atomic origin "$TURTLE_BASE_SHA:refs/heads/$backup" "$TURTLE_CANDIDATE_SHA:refs/heads/turtle-dev"
if ! git push origin --delete "$TURTLE_CANDIDATE_BRANCH"; then
    echo '::warning::Update succeeded, but the temporary candidate branch could not be removed.'
fi
echo "Windows build passed. Updated your personal turtle-dev branch and saved $backup. Run 02-Pull-My-Updates.cmd on your PC." >> "$GITHUB_STEP_SUMMARY"
