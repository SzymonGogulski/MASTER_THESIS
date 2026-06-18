from pathlib import Path
import subprocess
import shutil
import argparse

parser = argparse.ArgumentParser(
    description="Run NIST SP800-22 tests on .bin files"
)

parser.add_argument(
    "base_dir",
    help="Directory containing .bin files"
)

args = parser.parse_args()

base_dir = Path(args.base_dir).expanduser().resolve()
nist_out_dir = base_dir / "tests_results" / "nist22"
nist_out_dir.mkdir(parents=True, exist_ok=True)
nist_dir = Path.home() / "tools/SP800-22_StatisticalTestSuite"

# Find all .bin files
bin_files = list(base_dir.glob("*.bin"))

if not bin_files:
    print("No .bin files found.")
    exit(1)

for bin_file in bin_files:
    # 1. Define the expected target file path first
    target_file = nist_out_dir / f"{bin_file.stem}.txt"

    # 2. Skip processing if the output file already exists
    if target_file.exists():
        print(f"Skipping {bin_file.name} (Results already exist at {target_file.name})")
        continue

    print(f"\nRunning NIST SP800-22 on {bin_file.name}")

    bin_path = str(bin_file.resolve())
    # Inputs expected by the program
    inputs = "\n".join([
        "0",
        bin_path,
        "1",
        "0",
        "100",
        "1",
        ""
    ])

    # Run interactive process
    process = subprocess.Popen(
        ["./assess", "1000000"],
        cwd=nist_dir,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True
    )

    stdout, stderr = process.communicate(inputs)

    if process.returncode != 0:
        print(f"Warning: {bin_file.name} returned code {process.returncode}")

    # Path to generated report
    report_path = nist_dir / "experiments" / "AlgorithmTesting" / "finalAnalysisReport.txt"

    if not report_path.exists():
        print(f"ERROR: Report not found for {bin_file.name}")
        continue

    # Copy report to output directory
    shutil.copy(report_path, target_file)

    print(f"Saved -> {target_file}")
