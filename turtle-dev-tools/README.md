# Your personal xLights development setup

Your repository: https://github.com/ravenridgelights-turtle/xLights

Work on **turtle-dev**. The official xLights repository supplies updates. All pushes go to your own fork. The configure helper gives the official `upstream` remote an invalid push address, so an ordinary `git push upstream` cannot upload anything there.

## First Windows setup

1. Install **Git for Windows**: https://git-scm.com/downloads/win. Keep the installer option that makes Git available from the command line.
2. Install **Visual Studio 2026 Community**: https://visualstudio.microsoft.com/vs/community/. In its installer, select **Desktop development with C++**, including the Windows SDK. This is the full Visual Studio application. Current xLights uses the **v145** compiler toolset.
3. Install the **Vulkan SDK**: https://vulkan.lunarg.com/sdk/home#windows. Default components are sufficient. Reopen PowerShell and Visual Studio after installation.
4. Open ordinary Windows PowerShell and paste:

   ```powershell
   New-Item -ItemType Directory -Force C:\Dev | Out-Null
   Set-Location C:\Dev
   git clone --filter=blob:none --branch turtle-dev --recurse-submodules https://github.com/ravenridgelights-turtle/xLights.git xLights-Turtle
   ```

5. In File Explorer open `C:\Dev\xLights-Turtle\turtle-dev-tools` and double-click **01-Configure.cmd**. It sets the download-only official remote, prepares submodules, and installs ISPC 1.31.0 under your user account if needed. No administrator window is required.
6. Double-click **03-Build-and-Run.cmd**. The first build downloads xLights' own dependency bundle and compiles the program. Later builds reuse the downloads and compiled files.

Your Debug executable is `C:\Dev\xLights-Turtle\xLights\x64\Debug\xLights.exe`. The helper launches it with a separate test show at `%LOCALAPPDATA%\xLights-Turtle\TestShow`. Copy a show you want to test into that folder. The executable still shares xLights preferences with your installed copy; the separate show folder keeps development edits away from your working show files.

Do not use GitHub's Download ZIP for development. A ZIP has no Git history or populated submodules, so it cannot support this update workflow.

## The repeatable workflow

1. Tell ChatGPT what you want changed and identify `ravenridgelights-turtle/xLights`, branch `turtle-dev`.
2. ChatGPT commits the change to your personal branch, or prepares a feature branch in your fork for testing.
3. Double-click **02-Pull-My-Updates.cmd** on your PC.
4. Double-click **03-Build-and-Run.cmd**.
5. Test the behavior and send back the result, screenshots, or the first build error.

If you also edit code yourself, commit your changes before updating. The pull helper stops when your computer and GitHub have different commits; it will not reset or discard your work. Local backup branches are made before an update that moves your checkout.

## The buttons

| File | Purpose |
|---|---|
| 01-Configure.cmd | One-time Git/ISPC setup and prerequisite check |
| 02-Pull-My-Updates.cmd | Download changes from your GitHub `turtle-dev` branch |
| 03-Build-and-Run.cmd | Compile Debug x64 and open the test show |
| 04-Open-Visual-Studio.cmd | Open the solution for editing and debugging |
| 05-Merge-Official-Updates.cmd | Merge official development updates into your PC checkout on demand |

For normal use, you only need **02** and **03** after setup.

## Automatic official updates

The **Turtle - Sync official xLights** workflow lives on your fork's default `master` branch. Scheduled workflows must be on the default branch, so that branch is reserved for automation. Your code changes belong on `turtle-dev`.

Open https://github.com/ravenridgelights-turtle/xLights/actions. If GitHub shows that workflows are disabled for this fork, click **I understand my workflows, go ahead and enable them**. Then select **Turtle - Sync official xLights**, click **Run workflow**, leave `master` selected, and run it. This also checks the initial Windows build.

After enabling it, the workflow checks official `master` every day at **11:23 UTC**, and can also be run manually. GitHub schedules can be delayed. Public-repository scheduled workflows can be disabled after 60 days without repository activity; re-enable the workflow in Actions if that happens. Checking `master` includes development commits between releases as well as the commits used for official releases.

The workflow:

1. Updates `upstream-master`, your clean mirror of the official source.
2. Tries to merge the latest official commits into a separate candidate based on your existing `turtle-dev` branch.
3. Compiles that exact candidate on Windows using the official toolchain.
4. Updates `turtle-dev` only after the Windows build succeeds and only if nobody changed `turtle-dev` while the build ran.

A conflict or failed build leaves `turtle-dev` unchanged. The Actions log shows the failure; send it to ChatGPT so we can fix the integration. A successful build checks compilation, and your usual testing still checks whether your added features behave correctly. The automation updates GitHub; your PC receives those updates when you run **02-Pull-My-Updates.cmd**.

Successful updates save `backup/turtle-before-sync-*` branches. A failed build keeps its `turtle-sync/candidate-*` branch so it can be inspected. Successful candidate branches are removed. Build artifacts contain the compiled Release folder and remain downloadable from the Actions run for 14 days.

The workflow requests `contents: write` only for the two jobs that update your own fork. It never pushes to the official repository, never force-pushes your development branch, and does not open pull requests against official xLights.

If a run reports a GitHub permission error when an upstream update changes workflow files, add a fine-grained token for **only your personal xLights repository**, with **Contents: Read and write** and **Workflows: Read and write**, as the repository Actions secret `TURTLE_SYNC_TOKEN`. The workflow supports that secret and otherwise uses the built-in GitHub token. Keep the token in GitHub Secrets; do not paste it into a chat or commit it.

## Branches and remotes

| Name | Role |
|---|---|
| turtle-dev | Your personal development branch; use this on your PC |
| upstream-master | Clean official-source mirror maintained by the automation |
| master | Default automation branch; do not merge this branch into turtle-dev |
| archive/pre-turtle-setup-20261012 | Your previous fork state preserved before setup |
| origin | Your personal GitHub fork; uploads and downloads |
| upstream | Official xLights; downloads only after configuration |

You do not need to switch to the official branch to make changes. The automation merges its commits into your personal branch.

## Working inside Visual Studio

Open **04-Open-Visual-Studio.cmd**, choose **Debug** and **x64** in the top toolbar, then right-click the `xLights` project and select **Set as Startup Project**. Build with **Build > Build Solution**. Press **F5** to debug.

For the test show when using F5, set the xLights project's **Properties > Configuration Properties > Debugging > Command Arguments** to `-s "C:\Users\YOUR_WINDOWS_NAME\AppData\Local\xLights-Turtle\TestShow"`, replacing the Windows username. The double-click build helper passes the real path automatically.

Use **Release x64** when measuring rendering speed; Debug builds trade speed for easier debugging. To build Release from PowerShell:

```powershell
Set-Location C:\Dev\xLights-Turtle
powershell -NoProfile -ExecutionPolicy Bypass -File .\turtle-dev-tools\Build-and-Run.ps1 -Configuration Release
```

## Manual official updates

Use **05-Merge-Official-Updates.cmd** when you want the latest official changes locally without waiting for the scheduled workflow. It refuses a dirty checkout, makes a backup branch, merges on your local `turtle-dev`, and aborts the merge if there are conflicts. After a successful merge, build and test, then upload the tested result to your own fork:

```powershell
git push origin turtle-dev
```

To merge the latest published official release instead of development `master`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\turtle-dev-tools\Update-From-Official.ps1 -Source LatestRelease
```

If that release is already included in your branch, the helper does nothing. Switching to release-only updates does not remove newer development commits already merged. Ask ChatGPT to prepare a separate release-based development branch if you later want that policy.

## When asking ChatGPT for a feature

For example:

> In ravenridgelights-turtle/xLights on turtle-dev, add [feature]. Work only in my fork. Describe how I can test it and keep upstream updates working.

For problems, include the branch, a screenshot, and the first actual error line. Small focused commits make later official updates easier to combine. xLights' source guide is `AGENTS.md`, and the official Windows setup reference is https://github.com/xLightsSequencer/xLights/blob/master/README.windows.

Setup baseline: official `master` at `ee3374a3ea24262998d215fe049262cbfd0d7930`, checked October 12, 2026. Windows compilation and GUI behavior must be checked on Windows; the setup itself does not claim a successful local Windows build.
