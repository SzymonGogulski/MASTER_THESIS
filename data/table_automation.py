import sys
import re
from pathlib import Path

def parse_nist_file(filepath):
    """
    Parses a single NIST SP-800-22 result file.
    Returns a list of dictionaries containing test names, proportion values, and pass/fail markers.
    """
    test_list_order = [
        "Frequency", "BlockFrequency", "CumulativeSums", "CumulativeSums", "Runs",
        "LongestRun", "Rank", "FFT", "NonOverlappingTemplate", "OverlappingTemplate",
        "Universal", "ApproximateEntropy", "RandomExcursions", "RandomExcursionsVariant",
        "Serial", "Serial", "LinearComplexity"
    ]

    subtest_keys = ["NonOverlappingTemplate", "RandomExcursions", "RandomExcursionsVariant"]

    results = {name: [] for name in test_list_order}
    subtest_data = {name: {"total": 0, "passed": 0} for name in subtest_keys}
    occurrences = {name: [] for name in ["CumulativeSums", "Serial"]}

    try:
        with open(filepath, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        return None

    parsing = False

    for line in lines:
        if "C1  C2  C3" in line:
            parsing = True
            continue

        if not parsing or "----" in line or not line.strip():
            continue

        parts = line.strip().split()

        if len(parts) < 12:
            continue

        test_name = parts[-1]

        proportion_val = ""
        prop_failed = False

        for i, p in enumerate(parts):
            if "/" in p:
                proportion_val = p

                if i + 1 < len(parts) and parts[i + 1] == "*":
                    prop_failed = True

                break

        if test_name in subtest_keys:
            subtest_data[test_name]["total"] += 1

            if not prop_failed:
                subtest_data[test_name]["passed"] += 1

        elif test_name in occurrences:
            occurrences[test_name].append((proportion_val, prop_failed))

        else:
            if test_name in results:
                results[test_name] = (proportion_val, prop_failed)

    final_list = []

    cum_idx = 0
    ser_idx = 0

    for name in test_list_order:

        if name in subtest_keys:
            if not any(x['name'] == name for x in final_list):
                final_list.append({
                    "name": name,
                    "val": f"{subtest_data[name]['passed']}/{subtest_data[name]['total']}",
                    "marker": "sp"
                })

        elif name == "CumulativeSums":
            if cum_idx < len(occurrences[name]):
                val, fail = occurrences[name][cum_idx]

                final_list.append({
                    "name": name,
                    "val": val,
                    "marker": "*" if fail else ""
                })

                cum_idx += 1

        elif name == "Serial":
            if ser_idx < len(occurrences[name]):
                val, fail = occurrences[name][ser_idx]

                final_list.append({
                    "name": name,
                    "val": val,
                    "marker": "*" if fail else ""
                })

                ser_idx += 1

        else:
            res = results.get(name, ("N/A", False))

            final_list.append({
                "name": name,
                "val": res[0],
                "marker": "*" if res[1] else ""
            })

    return final_list


def generate_latex_table(file_list, labels):

    parsed_data = {}

    for label, path in zip(labels, file_list):

        data = parse_nist_file(path)

        if data:
            parsed_data[label] = data
        else:
            print(f"Error: Could not process {path}")
            return None

    test_names = [row['name'] for row in parsed_data[labels[0]]]

    latex = r"""\begin{table}[h!]
\centering
\caption{NIST Results}
\label{tab:nist_results}
\begin{tabular}{|l|c|l|c|l|c|l|c|l|}
\hline
\textbf{Statistical Test} & """

    latex += " & ".join([
        rf"\multicolumn{{2}}{{c|}}{{\textbf{{{label}}}}}"
        for label in labels
    ])

    latex += r" \\ \hline" + "\n"

    for i in range(len(test_names)):

        row_str = f"{test_names[i]:<23}"

        for label in labels:
            item = parsed_data[label][i]

            row_str += (
                f" & {item['val']:>7} & {item['marker']:<3}"
            )

        row_str += r" \\ \hline"

        latex += row_str + "\n"

    latex += r"""\end{tabular}
\end{table}
"""

    return latex




if __name__ == "__main__":

    # Check argument
    if len(sys.argv) != 2:
        print("Usage:")
        print("python3 script.py <path_to_directory>")
        sys.exit(1)

    # Directory provided by user
    data_dir = Path(sys.argv[1]).expanduser()

    # Validate directory
    if not data_dir.is_dir():
        print(f"Error: {data_dir} is not a valid directory.")
        sys.exit(1)

    # Required processing order
    required_files = [
        "true_true.txt",
        "true_false.txt",
        "false_true.txt",
        "false_false.txt"
    ]

    # Build file paths in exact order
    txt_files = [data_dir / filename for filename in required_files]

    # Verify all files exist
    missing = [str(f.name) for f in txt_files if not f.exists()]

    if missing:
        print("Error: Missing required files:")
        for m in missing:
            print(f"  - {m}")
        sys.exit(1)

    # Labels from filenames without extension
    column_labels = [f.stem for f in txt_files]

    # Convert paths to strings
    target_files = [str(f) for f in txt_files]

    # Generate table
    table_code = generate_latex_table(target_files, column_labels)

    if table_code:
        output_path = data_dir / "table.txt"

        with open(output_path, "w") as out:
            out.write(table_code)

        print(f"Table saved to: {output_path}")