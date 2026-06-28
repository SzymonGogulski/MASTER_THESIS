import os
import re

# Define the target metrics we want to extract
TARGET_METRICS = ["Slice LUTs", "Slice Registers", "F7 Muxes", "F8 Muxes"]


def parse_rpt_file(file_path):
    """Parses a Vivado utilization.rpt file and extracts the 'Used' value

    for specific Site Types.
    """
    data = {metric: "0" for metric in TARGET_METRICS}

    try:
        with open(file_path, "r") as f:
            for line in f:
                # Check if the line contains one of our target metrics
                for metric in TARGET_METRICS:
                    if metric in line and "|" in line:
                        # Split by the pipe character and clean up whitespace
                        parts = [p.strip() for p in line.split("|") if p.strip()]
                        if len(parts) >= 2:
                            # parts[0] is 'Site Type', parts[1] is 'Used'
                            data[metric] = parts[1]
    except Exception as e:
        print(f"Error reading {file_path}: {e}")

    return data


def extract_metadata(file_path):
    """Extracts experimental parameters based on the directory structure."""
    parts = file_path.strip("./").split("/")
    chapter = parts[0]  # e.g., ch3, ch4, ch5

    # Default values in case structure varies
    algo = "-"
    config = "-"
    setting = "-"

    if chapter == "ch5":
        # Structure: ./ch5/[algo]/[config]/utilization.rpt
        algo = parts[1]
        config = parts[2]
        setting = "N/A"
    elif chapter in ["ch3", "ch4"]:
        # ch3 Structure: ./ch3/[config]/utilization/[setting].rpt
        # ch4 Structure: ./ch4/[config]/utilization/[setting].rpt
        config = parts[1]
        setting = parts[3].replace(".rpt", "")
        algo = "N/A"

    return chapter, algo, config, setting


def main():
    results = []

    # Walk through the current directory to find all .rpt files
    for root, dirs, files in os.walk("."):
        for file in files:
            if file.endswith(".rpt"):
                file_path = os.path.join(root, file)
                metrics = parse_rpt_file(file_path)
                ch, algo, config, setting = extract_metadata(file_path)

                results.append((ch, algo, config, setting, metrics))

    # Sort the results logically by Chapter, Algo, Config, then Setting
    results.sort(key=lambda x: (x[0], x[1], x[2], x[3]))

    # Generate LaTeX Table
    print("% ================== LATEX TABLE START ==================")
    print("\\begin{table}[htbp]")
    print("  \\centering")
    print(
        "  \\caption{Compiled Resource Utilization Results across Chapters}"
    )
    print("  \\label{tab:resource_utilization}")
    print("  \\begin{tabular}{llllcccc}")
    print("    \\hline")
    print(
        "    \\textbf{Ch.} & \\textbf{Algo.} & \\textbf{Config.} & \\textbf{Setting} & \\textbf{LUTs} & \\textbf{Registers} & \\textbf{F7 Mux} & \\textbf{F8 Mux} \\\\"
    )
    print("    \\hline")

    for ch, algo, config, setting, metrics in results:
        print(
            f"    {ch} & {algo} & {config} & {setting} & "
            f"{metrics['Slice LUTs']} & {metrics['Slice Registers']} & "
            f"{metrics['F7 Muxes']} & {metrics['F8 Muxes']} \\\\"
        )

    print("    \\hline")
    print("  \\end{tabular}")
    print("\\end{table}")
    print("% =================== LATEX TABLE END ===================")


if __name__ == "__main__":
    main()
