from pathlib import Path
import subprocess
import re
import argparse

parser = argparse.ArgumentParser(
    description="Run ENT tests on .bin files"
)

parser.add_argument(
    "base_dir",
    help="Directory containing .bin files"
)

args = parser.parse_args()

base_dir = Path(args.base_dir).expanduser().resolve()
ent_output_dir = base_dir / "tests_results/ent"
ent_output_dir.mkdir(exist_ok=True)
ent_dir = Path.home() / "tools/ent/src"

# Find all .bin files
bin_files = list(base_dir.glob("*.bin"))

if not bin_files:
    print("No .bin files found.")
    exit(1)

for bin_file in bin_files:
    print(f"ENT processing {bin_file.name}...")
    
    bin_path = str(bin_file.resolve())
    # Run external program
    result = subprocess.run(
        ["./ent", bin_path],
        cwd=ent_dir,
        capture_output=True,
        text=True
    )

    output_text = result.stdout + result.stderr

    # Write to log file
    log_file = ent_output_dir / f"{bin_file.stem}.log"
    log_file.write_text(output_text)
    print(output_text.splitlines()[0])
    print(f"Saved -> {log_file}")
