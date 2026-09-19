#!/usr/bin/env python3
"""
pymap engine - Core execution logic for the pymap CLI.
"""

import sys
import argparse
import platform

__version__ = "0.1.0"

def cmd_version(args):
    print(f"pymap version {__version__}")
    print(f"Python: {platform.python_version()} on {platform.system()} {platform.release()}")
    return 0

def cmd_info(args):
    print("=== pymap System Information ===")
    print(f"Version:      {__version__}")
    print(f"Platform:     {platform.platform()}")
    print(f"Architecture: {platform.machine()}")
    print(f"Python Exec:  {sys.executable}")
    return 0

def cmd_scan(args):
    target = args.target
    ports = args.ports or "common ports (1-1024)"
    print(f"[*] Initiating pymap scan on target: {target}")
    print(f"[*] Port specification: {ports}")
    if args.verbose:
        print("[*] Verbose logging enabled.")
    print("[+] Engine ready for scan execution.")
    return 0

def build_parser():
    parser = argparse.ArgumentParser(
        prog="pymap",
        description="pymap: Fast network & service mapping tool with Rust CLI and Python engine."
    )
    parser.add_argument(
        "-V", "--version",
        action="version",
        version=f"pymap {__version__}"
    )

    subparsers = parser.add_subparsers(dest="command", help="Available subcommands")

    # 'version' command
    p_version = subparsers.add_parser("version", help="Show version information")
    p_version.set_defaults(func=cmd_version)

    # 'info' command
    p_info = subparsers.add_parser("info", help="Show engine runtime information")
    p_info.set_defaults(func=cmd_info)

    # 'scan' command
    p_scan = subparsers.add_parser("scan", help="Scan target hosts or ports")
    p_scan.add_argument("target", help="Target IP or hostname to scan")
    p_scan.add_argument("-p", "--ports", help="Ports to scan (e.g. 80,443, 1-1000)")
    p_scan.add_argument("-v", "--verbose", action="store_true", help="Enable verbose output")
    p_scan.set_defaults(func=cmd_scan)

    return parser

def main():
    parser = build_parser()
    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        return 0

    if hasattr(args, "func"):
        return args.func(args)
    return 0

if __name__ == "__main__":
    sys.exit(main() or 0)
