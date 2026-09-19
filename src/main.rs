use std::env;
use std::path::{Path, PathBuf};
use std::process::{self, Command};

fn get_exe_dir() -> Option<PathBuf> {
    env::current_exe().ok().and_then(|p| p.parent().map(|p| p.to_path_buf()))
}

fn find_engine_exe() -> Option<PathBuf> {
    if let Some(dir) = get_exe_dir() {
        let engine_path = dir.join("engine.exe");
        if engine_path.is_file() {
            return Some(engine_path);
        }
    }
    None
}

fn find_engine_py() -> Option<PathBuf> {
    // Check relative to current working directory
    let cwd_py = Path::new("engine").join("main.py");
    if cwd_py.is_file() {
        return Some(cwd_py);
    }

    // Check relative to the executable directory
    if let Some(dir) = get_exe_dir() {
        let exe_rel_py = dir.join("engine").join("main.py");
        if exe_rel_py.is_file() {
            return Some(exe_rel_py);
        }
    }

    None
}

fn main() {
    let args: Vec<String> = env::args().skip(1).collect();

    // 1. Primary path: look for sibling engine.exe (bundled distribution)
    if let Some(engine_exe) = find_engine_exe() {
        let status = Command::new(&engine_exe)
            .args(&args)
            .status();

        match status {
            Ok(exit_status) => {
                process::exit(exit_status.code().unwrap_or(1));
            }
            Err(e) => {
                eprintln!("Error executing {}: {}", engine_exe.display(), e);
                process::exit(1);
            }
        }
    }

    // 2. Fallback path for development: look for engine/main.py and run with python
    if let Some(py_script) = find_engine_py() {
        // Try 'python', then 'py' if needed
        let status = Command::new("python")
            .arg(&py_script)
            .args(&args)
            .status()
            .or_else(|_| {
                Command::new("py")
                    .arg("-3")
                    .arg(&py_script)
                    .args(&args)
                    .status()
            });

        match status {
            Ok(exit_status) => {
                process::exit(exit_status.code().unwrap_or(1));
            }
            Err(e) => {
                eprintln!(
                    "Error executing python script '{}': {}\nEnsure Python 3 is installed and available in PATH.",
                    py_script.display(),
                    e
                );
                process::exit(1);
            }
        }
    }

    // 3. Neither engine executable nor script was found
    eprintln!("Error: pymap engine could not be found.");
    if let Some(dir) = get_exe_dir() {
        eprintln!("Looked for bundled binary: {}", dir.join("engine.exe").display());
    }
    eprintln!("Looked for script: engine/main.py");
    eprintln!("\nMake sure 'engine.exe' is placed alongside 'pymap.exe' or 'engine/main.py' is present.");
    process::exit(1);
}
