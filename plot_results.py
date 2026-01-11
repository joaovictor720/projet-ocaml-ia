import os
import re
import matplotlib.pyplot as plt
import numpy as np

# ==========================================
# CONFIGURATION
# ==========================================

# Directory containing the results
RESULTS_DIR = "results"

# Directory where graphs will be saved
OUTPUT_DIR = "graphs"

# List of targets (oracles) to process
TARGETS = [
    "even_ones", 
    "ends_zero", 
    "double_one", 
    "div_by_5", 
    "div_by_25", 
    "div_by_7",
    "div_by_15",
    "bit_4", 
    "bit_6",
    "bit_8",
    "len_10",
    "len_20"
]

# Map display names to folder names
METHODS = {
    "Angluin Raw": "angluin_raw",
    "RS Raw": "rs_raw",
    "Angluin Cached": "angluin_cached",
    "RS Cached": "rs_cached"
}

# Colors for each method
COLORS = ["#ff9999", "#66b3ff", "#99ff99", "#ffcc99"]

# ==========================================
# HELPER FUNCTIONS
# ==========================================

def ensure_dir(directory):
    """Creates the directory if it does not exist."""
    if not os.path.exists(directory):
        os.makedirs(directory)

def get_query_count(method_folder, target):
    """Reads the .log file and extracts the last query number."""
    filepath = os.path.join(RESULTS_DIR, method_folder, f"{target}_queries.log")
    
    if not os.path.exists(filepath):
        return 0

    count = 0
    try:
        with open(filepath, 'r') as f:
            for line in f:
                # Looks for lines like "[Query 123] ..."
                match = re.search(r'\[Query (\d+)\]', line)
                if match:
                    count = int(match.group(1))
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
    
    return count

def plot_target_comparison(target):
    """Generates a bar chart comparing all 4 methods for a single target."""
    counts = []
    method_labels = list(METHODS.keys())
    
    # Gather data
    for method_name, folder_name in METHODS.items():
        val = get_query_count(folder_name, target)
        counts.append(val)
    
    # Skip if no data found for this target
    if sum(counts) == 0:
        print(f"[-] Skipping {target} (No data found)")
        return

    # Plotting
    plt.figure(figsize=(10, 6))
    bars = plt.bar(method_labels, counts, color=COLORS, edgecolor='black', zorder=3)
    
    # Add number labels on top of bars
    for bar in bars:
        height = bar.get_height()
        if height > 0:
            plt.text(bar.get_x() + bar.get_width()/2., height + (max(counts)*0.01),
                     f'{height}',
                     ha='center', va='bottom', fontsize=10, fontweight='bold')

    # Styling
    plt.title(f'Oracle Performance: {target}', fontsize=14, fontweight='bold')
    plt.ylabel('Total Queries', fontsize=12)
    plt.xlabel('Learning Method', fontsize=12)
    plt.grid(axis='y', linestyle='--', alpha=0.7, zorder=0)
    
    # Save file
    filename = os.path.join(OUTPUT_DIR, f"{target}_comparison.png")
    plt.savefig(filename, dpi=100)
    plt.close()
    print(f"[+] Graph saved: {filename}")

# ==========================================
# MAIN EXECUTION
# ==========================================

if __name__ == "__main__":
    print("--- Starting Graph Generation ---")
    ensure_dir(OUTPUT_DIR)
    
    for target in TARGETS:
        plot_target_comparison(target)
        
    print(f"\nDone! Check the '{OUTPUT_DIR}' folder.")