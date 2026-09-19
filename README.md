# pymap

A fast, lightweight CLI tool featuring a **Rust CLI front-end** wrapper and a **Python execution engine**.

---

## Architecture

* **Rust CLI (`pymap.exe`)**: Handles argument forwarding, rapid startup, and process isolation.
* **Python Engine (`engine/main.py` / `engine.exe`)**: Houses the core application logic. Can be frozen with PyInstaller into a standalone executable (`engine.exe`) so that end users do not need a Python environment installed.

```
pymap [args]
   │
   ├──► 1. Production Mode: looks for 'engine.exe' in same folder as 'pymap.exe'
   └──► 2. Development Mode (fallback): executes 'engine/main.py' via system python
```

---

## Project Structure

```
pymap/
├── Cargo.toml                  # Rust package definition and metadata
├── src/
│   └── main.rs                 # Rust CLI entry point & engine launcher
├── engine/
│   ├── main.py                 # Core Python engine implementation
│   └── requirements.txt        # Engine packaging dependencies
├── docx/
│   └── pymap-windows-install-guide.md # Windows publishing and distribution guide
├── build.ps1                   # Automation script for building release bundles
├── .gitignore
└── README.md
```

---

## Installation (Windows)

Install `pymap` globally using the automated PowerShell installer:

```powershell
irm https://raw.githubusercontent.com/aaaditya15/1/main/install.ps1 | iex
```

This automatically downloads the latest release bundle, installs it to `%LOCALAPPDATA%\Programs\pymap`, and configures your `PATH`.

---

## Development

### 1. Running the Python Engine Directly
You can run and iterate on the engine logic directly with Python 3:
```powershell
python engine/main.py --help
python engine/main.py info
python engine/main.py scan 192.168.1.1 -p 80,443 -v
```

### 2. Running via Rust Wrapper (Once Rust is installed)
When `engine.exe` is not yet compiled, `cargo run` will automatically invoke `engine/main.py` using your system Python:
```powershell
cargo run -- --help
cargo run -- scan 127.0.0.1
```

---

## Building the Windows Release Bundle

To compile both `pymap.exe` and `engine.exe` into a self-contained distribution folder:

```powershell
# Build both the PyInstaller engine and release Rust binary:
.\build.ps1

# Build and generate a redistributable zip archive:
.\build.ps1 -Zip
```

The output files will be assembled in `dist/pymap-win64/` (and `dist/pymap-win64.zip`).

---

## Distribution & Publishing

For complete instructions on publishing `pymap` via GitHub Releases, PowerShell installer scripts, and `winget`, see [pymap-windows-install-guide.md](docx/pymap-windows-install-guide.md).
