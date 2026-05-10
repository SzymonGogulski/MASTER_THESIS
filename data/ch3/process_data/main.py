import sys
import re

def parse_nist_file(filepath):
    """
    Parses a single NIST SP-800-22 result file.
    Returns a list of dictionaries containing test names, proportion values, and pass/fail markers.
    """
    # NIST tests in the specific order required for the table
    test_list_order = [
        "Frequency", "BlockFrequency", "CumulativeSums", "CumulativeSums", "Runs", 
        "LongestRun", "Rank", "FFT", "NonOverlappingTemplate", "OverlappingTemplate", 
        "Universal", "ApproximateEntropy", "RandomExcursions", "RandomExcursionsVariant", 
        "Serial", "Serial", "LinearComplexity"
    ]
    
    # Categories that use the "sp" (subtests passed) notation
    subtest_keys = ["NonOverlappingTemplate", "RandomExcursions", "RandomExcursionsVariant"]
    
    # Data structures to store results
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
            
        # The test name is usually the last column
        test_name = parts[-1]
        
        # Identify the proportion string (X/Y) and check for the failure asterisk (*)
        proportion_val = ""
        prop_failed = False
        
        for i, p in enumerate(parts):
            if "/" in p:
                proportion_val = p
                # Check if the next token is an asterisk indicating a proportion failure
                if i + 1 < len(parts) and parts[i+1] == "*":
                    prop_failed = True
                break
        
        # Logic for aggregating subtests
        if test_name in subtest_keys:
            subtest_data[test_name]["total"] += 1
            if not prop_failed:
                subtest_data[test_name]["passed"] += 1
        elif test_name in occurrences:
            occurrences[test_name].append((proportion_val, prop_failed))
        else:
            if test_name in results:
                results[test_name] = (proportion_val, prop_failed)

    # Compile a flat list of results in the correct order
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
                final_list.append({"name": name, "val": val, "marker": "*" if fail else ""})
                cum_idx += 1
        elif name == "Serial":
            if ser_idx < len(occurrences[name]):
                val, fail = occurrences[name][ser_idx]
                final_list.append({"name": name, "val": val, "marker": "*" if fail else ""})
                ser_idx += 1
        else:
            res = results.get(name, ("N/A", False))
            final_list.append({"name": name, "val": res[0], "marker": "*" if res[1] else ""})
                
    return final_list

def generate_latex_table(file_list, labels):
    """
    Combines parsed data from 4 files into a LaTeX table string.
    """
    parsed_data = {}
    for label, path in zip(labels, file_list):
        data = parse_nist_file(path)
        if data:
            parsed_data[label] = data
        else:
            print(f"Error: Could not process {path}")
            return

    test_names = [row['name'] for row in parsed_data[labels[0]]]
    
    latex = r"""\begin{table}[h!]
\centering
\caption{3 RO : 5 - 7 - 9}
\label{tab:nist_results}
\begin{tabular}{|l|c|l|c|l|c|l|c|l|}
\hline
\textbf{Statistical Test} & """
    
    # Header row
    latex += " & ".join([rf"\multicolumn{{2}}{{c|}}{{\textbf{{{label}}}}}" for label in labels]) + r" \\ \hline" + "\n"
    
    # Data rows
    for i in range(len(test_names)):
        row_str = f"{test_names[i]:<23}"
        for label in labels:
            item = parsed_data[label][i]
            val = item['val']
            marker = item['marker']
            row_str += f" & {val:>7} & {marker:<3}"
        row_str += r" \\ \hline"
        latex += row_str + "\n"
        
    latex += r"""\end{tabular}
\begin{flushleft}
\small \textbf{Note:} The minimum pass rate for each statistical test with the exception of the
random excursion (variant) test is approximately = 96 for a
sample size = 100 binary sequences\cite{NIST-SP-800-22}. \\
\small \textbf{Legend:} \textbf{sp} - subtests passed (zaliczone podtesty). \\
\small \textbf{Legend:} \textbf{*} - test niezaliczony.
\end{flushleft}
\end{table}
"""
    return latex

if __name__ == "__main__":
    # Specify the four files in the order they should appear as columns
    target_files = ["data/true_true.txt", "data/true_false.txt", "data/false_true.txt", "data/false_false.txt"]
    column_labels = ["true/true", "true/false", "false/true", "false/false"]
    
    table_code = generate_latex_table(target_files, column_labels)
    if table_code:
        print(table_code)
        with open("nist_table.tex", "w") as out:
            out.write(table_code)
