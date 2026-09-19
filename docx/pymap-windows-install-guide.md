# Publishing `pymap` for Global Installation — Windows Only

Scoped to getting `pymap` installable as a global command on Windows. No macOS/Linux packaging here.

---

## 0. Before You Publish — Prep

- [ ] `cargo build --release --target x86_64-pc-windows-msvc` succeeds and produces `pymap.exe`
- [ ] Fill out `Cargo.toml` metadata (name, version, description, license, repository) — needed even for a Windows-only release if you ever push to crates.io
- [ ] Decide how the Python engine ships — this determines whether `pymap.exe` alone is enough or whether you need a bundle:
  - [ ] **Option A (recommended for Windows):** Freeze `engine/main.py` with PyInstaller into `engine.exe` using `pyinstaller --onefile`. Ship it next to `pymap.exe`; have the Rust CLI look for `engine.exe` relative to its own path via `std::env::current_exe()`. No Python install required on the user's machine.
  - [ ] **Option B:** Require Python 3 on the user's `PATH` and ship `engine/` as source. Simpler to build, worse install experience.

---

## 1. Build the Windows Release Bundle

- [ ] Add the MSVC target if not already installed: `rustup target add x86_64-pc-windows-msvc`
- [ ] `cargo build --release --target x86_64-pc-windows-msvc`
- [ ] If using Option A, run PyInstaller on Windows (or via a Windows CI runner — PyInstaller builds aren't cross-platform) to produce `engine.exe`
- [ ] Collect into one folder: `pymap.exe`, `engine.exe` (if applicable), `README.md`, `LICENSE`
- [ ] Zip it: `pymap-vX.Y.Z-win64.zip`

---

## 2. GitHub Releases (primary distribution path)

- [ ] Tag the release: `git tag v0.1.0 && git push --tags`
- [ ] Set up a GitHub Actions workflow with a `windows-latest` runner that builds the release target and PyInstaller engine on tag push, then uploads `pymap-vX.Y.Z-win64.zip` as a release asset — this way you don't have to build locally every time
- [ ] Publish the GitHub Release with that zip attached
- [ ] Document manual install in the README: download zip → extract → add the folder to `PATH`

---

## 3. Add to PATH Automatically (PowerShell install script)

- [ ] Write `install.ps1` that downloads the latest release zip, extracts it to e.g. `%LOCALAPPDATA%\pymap`, and adds that folder to the user's `PATH` (via `setx PATH` or the registry `Environment` key — `setx` is simplest but truncates long PATH values, so prefer editing the registry key directly for a real installer)
- [ ] Let users run:
  ```powershell
  irm https://raw.githubusercontent.com/<you>/pymap/main/install.ps1 | iex
  ```
- [ ] Have the script print a "restart your terminal" reminder — PATH changes don't apply to already-open shells

---

## 4. Winget (Windows Package Manager) — best long-term option

- [ ] Fork `microsoft/winget-pkgs`
- [ ] Use the `wingetcreate` tool to generate a manifest from your GitHub Release zip/installer URL: `wingetcreate new https://github.com/<you>/pymap/releases/download/v0.1.0/pymap-v0.1.0-win64.zip`
- [ ] This produces three YAML files (version, installer, locale) under `manifests/<you>/pymap/0.1.0/`
- [ ] Submit as a PR to `microsoft/winget-pkgs`; Microsoft's automated validation checks the installer (silent install behavior, hash match) before a human reviews it
- [ ] Once merged, anyone can run:
  ```powershell
  winget install pymap
  ```
- [ ] Note: winget prefers an actual installer (MSI/EXE with silent-install flags) over a bare zip — if you want a clean winget listing, consider wrapping the release in a simple installer (e.g. via `cargo-wix` to produce an MSI) rather than shipping a raw zip

---

## 5. Optional: MSI Installer via `cargo-wix`

- [ ] `cargo install cargo-wix`
- [ ] `cargo wix init` in the project root — generates a WiX Toolset config (`wix/main.wxs`)
- [ ] Edit the config to also stage `engine.exe` into the install directory and add the install dir to `PATH` via the WiX `PATH` extension
- [ ] `cargo wix` builds `pymap-X.Y.Z-x86_64.msi`
- [ ] Attach this MSI to the GitHub Release alongside (or instead of) the raw zip — this is the file winget/§4 wants

---

## 6. Versioning and Repeat Releases

- [ ] SemVer bump in `Cargo.toml` → tag → CI builds Windows artifacts → GitHub Release → update the winget manifest (`wingetcreate update`) → re-submit PR to `winget-pkgs`
- [ ] Keep `CHANGELOG.md` updated per release

---

## Suggested Order

1. §0–1 (build + engine bundling decision) → 2. §2 (GitHub Releases, so there's something to point at) → 3. §5 (wrap as MSI) → 4. §4 (winget submission) → 5. §3 (PowerShell script as a fallback for anyone who doesn't want winget) → 6. §6 (lock in the repeat process)
