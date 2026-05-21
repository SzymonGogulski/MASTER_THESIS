from pathlib import Path
import subprocess
import re
import argparse

parser = argparse.ArgumentParser(
    description="Run NIST-SP-800-90B tests on .bin files"
)

parser.add_argument(
    "base_dir",
    help="Directory containing .bin files"
)

args = parser.parse_args()

base_dir = Path(args.base_dir).expanduser().resolve()
nist90_output_dir = base_dir / "tests_results/nist90"
nist90_output_dir.mkdir(exist_ok=True)
nist90_dir = Path.home() / "tools/SP800-90B_EntropyAssessment/cpp"

# Find all .bin files
bin_files = list(base_dir.glob("*.bin"))

if not bin_files:
    print("No .bin files found.")
    exit(1)

for bin_file in bin_files:
    print(f"NIST90 processing {bin_file.name}...")
    
    bin_path = str(bin_file.resolve())
    # Run external program
    result = subprocess.run(
            ["./ea_non_iid", bin_path, "8"],
        cwd=nist90_dir,
        capture_output=True,
        text=True
    )

    output_text = result.stdout + result.stderr

    # Write to log file
    log_file = nist90_output_dir / f"{bin_file.stem}.log"
    log_file.write_text(output_text)
    print(output_text.splitlines()[0])
    print(f"Saved -> {log_file}")
