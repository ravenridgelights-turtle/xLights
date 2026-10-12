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

git config user.name 'github-actions[bot]'
git config user.email '41898282+github-actions[bot]@users.noreply.github.com'
git config remote.pushDefault origin
if git remote get-url upstream >/dev/null 2>&1; then
    git remote set-url upstream https://github.com/xLightsSequencer/xLights.git
else
    git remote add upstream https://github.com/xLightsSequencer/xLights.git
fi
git config --replace-all remote.upstream.pushurl https://upstream-read-only.invalid/xLights.git
git fetch --no-tags upstream master
git fetch --no-tags origin refs/heads/turtle-dev:refs/remotes/origin/turtle-dev refs/heads/upstream-master:refs/remotes/origin/upstream-master

upstream_sha=$(git rev-parse upstream/master)
mirror_sha=$(git rev-parse origin/upstream-master)
if ! git merge-base --is-ancestor "$mirror_sha" "$upstream_sha"; then
    echo 'The clean mirror has diverged. Refusing to overwrite it.' >&2
    exit 1
fi
if [[ "$mirror_sha" != "$upstream_sha" ]]; then
    git push origin "$upstream_sha:refs/heads/upstream-master"
fi

git checkout --detach origin/turtle-dev
base_sha=$(git rev-parse HEAD)
printf 'base_sha=%s\nupstream_sha=%s\n' "$base_sha" "$upstream_sha" >> "$GITHUB_OUTPUT"

if git merge-base --is-ancestor "$upstream_sha" HEAD; then
    ready=false
    if [[ "${TURTLE_FORCE_BUILD:-false}" == 'true' ]]; then ready=true; fi
    printf 'changed=false\nready=%s\ncandidate_sha=%s\ncandidate_branch=\n' "$ready" "$base_sha" >> "$GITHUB_OUTPUT"
    echo 'Your development branch already contains the latest official commits.' >> "$GITHUB_STEP_SUMMARY"
    exit 0
fi

if ! git merge --no-edit "$upstream_sha"; then
    echo 'Official updates conflict with your changes. turtle-dev is unchanged.' >> "$GITHUB_STEP_SUMMARY"
    git diff --name-only --diff-filter=U >> "$GITHUB_STEP_SUMMARY"
    if git rev-parse -q --verify MERGE_HEAD >/dev/null; then git merge --abort; fi
    exit 1
fi

candidate_sha=$(git rev-parse HEAD)
candidate_branch="turtle-sync/candidate-${GITHUB_RUN_ID}-${GITHUB_RUN_ATTEMPT}"
git push origin "$candidate_sha:refs/heads/$candidate_branch"
printf 'changed=true\nready=true\ncandidate_sha=%s\ncandidate_branch=%s\n' "$candidate_sha" "$candidate_branch" >> "$GITHUB_OUTPUT"
echo "Prepared $candidate_branch for a Windows build. turtle-dev is unchanged until that build passes." >> "$GITHUB_STEP_SUMMARY"
