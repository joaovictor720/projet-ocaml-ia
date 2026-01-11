import os
import re
import matplotlib.pyplot as plt
import numpy as np

# ==========================================
# CONFIGURATION
# ==========================================

RESULTS_DIR = "results"
OUTPUT_DIR = "graphs_dim"

TARGETS = [
    "even_ones", 
    "ends_zero", 
    "double_one", 
    "div_by_5", 
    "div_by_25", 
    "div_by_7",
    "bit_4", 
    "bit_6",
    "len_10",
    "suffix_hard",
    "contains_110"
]
METHODS = {
    "Angluin Raw": "angluin_raw",
    "RS Raw": "rs_raw",
    "Angluin Cached": "angluin_cached",
    "RS Cached": "rs_cached"
}

# Color palette
COLORS = ["#ff9999", "#66b3ff", "#99ff99", "#ffcc99"]

# ==========================================
# DATA EXTRACTION
# ==========================================

def get_table_dimensions(method_folder, target):
    """
    Parses the debug HTML to find the table size (Rows S, Cols E).
    """
    filepath = os.path.join(RESULTS_DIR, method_folder, f"{target}_debug.html")
    
    if not os.path.exists(filepath):
        return 0, 0

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        # Get the last step (final table)
        steps = re.findall(r"<div class='step' id='s\d+'>(.*?)</div>", content, re.DOTALL)
        
        if not steps:
            return 0, 0
            
        last_step = steps[-1]
        
        # Count Columns (E): Count headers <th> minus the top-left corner
        num_cols = last_step.count("<th style='padding: 8px;'>") - 1
        if num_cols < 0: num_cols = 0
        
        # Count Rows (S): Rows in S are bold
        num_rows = last_step.count("font-weight: bold")
        
        return num_rows, num_cols
        
    except Exception as e:
        print(f"[!] Error reading {filepath}: {e}")
        return 0, 0

def plot_dimension_chart(target, dim_type):
    """
    Generates chart for Rows, Cols, or Area.
    """
    values = []
    labels = list(METHODS.keys())
    
    for method_name, folder_name in METHODS.items():
        r, c = get_table_dimensions(folder_name, target)
        
        if dim_type == 'rows':
            values.append(r)
            ylabel = "Number of Rows (S)"
            title = f"Table Vertical Size (Rows S): {target}"
        elif dim_type == 'cols':
            values.append(c)
            ylabel = "Number of Columns (E)"
            title = f"Table Horizontal Size (Columns E): {target}"
        else: # area
            values.append(r * c)
            ylabel = "Total Cells (Rows * Cols)"
            title = f"Estimated Memory Usage (Table Area): {target}"
    
    if sum(values) == 0:
        print(f"[-] Skipped {target} ({dim_type}) - No data found.")
        return

    plt.figure(figsize=(10, 6))
    bars = plt.bar(labels, values, color=COLORS, edgecolor='black', zorder=3)
    
    for bar in bars:
        height = bar.get_height()
        if height > 0:
            plt.text(bar.get_x() + bar.get_width()/2., height + (max(values)*0.01),
                     f'{int(height)}',
                     ha='center', va='bottom', fontsize=10, fontweight='bold')

    plt.title(title, fontsize=14, fontweight='bold')
    plt.ylabel(ylabel, fontsize=12)
    plt.grid(axis='y', linestyle='--', alpha=0.7, zorder=0)
    
    filename = os.path.join(OUTPUT_DIR, f"{target}_dim_{dim_type}.png")
    plt.savefig(filename, dpi=100)
    plt.close()
    print(f"[+] Graph saved: {filename}")

# ==========================================
# MAIN
# ==========================================

if __name__ == "__main__":
    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR)
        
    print("--- Generating Dimension Analysis Graphs ---")
    
    for target in TARGETS:
        plot_dimension_chart(target, 'rows')
        plot_dimension_chart(target, 'cols')
        plot_dimension_chart(target, 'area')
        
    print(f"\n[Done] Check the '{OUTPUT_DIR}' folder.")