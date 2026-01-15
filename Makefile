# ==========================================
#   PROJECT CONFIGURATION
# ==========================================

# --- Directory Structure ---
SRC_DIR  = src
TEST_DIR = tests
BIN_DIR  = bin
OBJ_DIR  = obj
RSLT_DIR = results
GRF_DIR = graphs
GRFDIM_DIR = graphs_dim

# --- Compiler & Flags ---
OCAMLC = ocamlc
FLAGS  = -I $(OBJ_DIR) -g

# --- Run Configuration (Defaults) ---
ALGO ?= rs
CACHE ?= 1
CHECKS ?= 3000

CMD_ARGS = -algo $(ALGO) -n $(CHECKS)
ifeq ($(CACHE),0)
	CMD_ARGS += -no-cache
endif

# ==========================================
#   FILES & OBJECTS
# ==========================================

LIB_MODULES = dfa observationTable lStar targets
LIB_OBJS    = $(addprefix $(OBJ_DIR)/, $(addsuffix .cmo, $(LIB_MODULES)))

TARGET      = $(BIN_DIR)/lstar
TEST_TARGET = $(BIN_DIR)/tests_run

# ==========================================
#   MAIN RULES
# ==========================================

.PHONY: all clean test run interactive run-only help benchmark benchmark-all list-algos list-scenarios

all: $(TARGET) $(TEST_TARGET)

# --- Linking ---

$(TARGET): $(LIB_OBJS) $(OBJ_DIR)/main.cmo
	@mkdir -p $(BIN_DIR)
	$(OCAMLC) $(FLAGS) -o $@ $^

$(TEST_TARGET): $(LIB_OBJS) $(OBJ_DIR)/tests.cmo
	@mkdir -p $(BIN_DIR)
	$(OCAMLC) $(FLAGS) -o $@ $^

# ==========================================
#   COMPILATION RULES
# ==========================================

$(OBJ_DIR)/%.cmi: $(SRC_DIR)/%.mli
	@mkdir -p $(OBJ_DIR)
	$(OCAMLC) $(FLAGS) -c -o $@ $<

$(OBJ_DIR)/%.cmo: $(SRC_DIR)/%.ml
	@mkdir -p $(OBJ_DIR)
	$(OCAMLC) $(FLAGS) -c -o $@ $<

$(OBJ_DIR)/%.cmo: $(TEST_DIR)/%.ml
	@mkdir -p $(OBJ_DIR)
	$(OCAMLC) $(FLAGS) -c -o $@ $<

# ==========================================
#   DEPENDENCIES
# ==========================================

$(OBJ_DIR)/dfa.cmo: $(OBJ_DIR)/dfa.cmi
$(OBJ_DIR)/observationTable.cmo: $(OBJ_DIR)/observationTable.cmi $(OBJ_DIR)/dfa.cmo
$(OBJ_DIR)/lStar.cmo: $(OBJ_DIR)/lStar.cmi $(OBJ_DIR)/observationTable.cmo $(OBJ_DIR)/dfa.cmo
$(OBJ_DIR)/targets.cmo: $(OBJ_DIR)/targets.cmi $(SRC_DIR)/targets.ml
$(OBJ_DIR)/main.cmo: $(OBJ_DIR)/lStar.cmo $(OBJ_DIR)/dfa.cmo $(OBJ_DIR)/targets.cmo
$(OBJ_DIR)/tests.cmo: $(OBJ_DIR)/dfa.cmo

# ==========================================
#   COMMANDS & UTILITIES
# ==========================================

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR) $(RSLT_DIR) $(GRF_DIR) $(GRFDIM_DIR)

test: $(TEST_TARGET)
	@echo "--- Running Test Suite ---"
	@./$(TEST_TARGET)

# Generate graphs recursively in all result subfolders
define generate_graphs
	@echo "--- Generating Graphviz Images $(if $(T),for target: $(T),) ---"
	@find $(RSLT_DIR) -name "*$(T).dot" | while read file; do \
		png="$${file%.dot}.png"; \
		if [ ! -f "$$png" ] || [ "$$file" -nt "$$png" ]; then \
			echo "   [+] Converting $$(basename $$file) in $$(dirname $$file)..."; \
			dot -Tpng "$$file" -o "$$png"; \
		fi; \
	done
endef

# 1. Run Everything (Standard Mode)
run: $(TARGET)
	@mkdir -p $(RSLT_DIR)
	@echo "--- Running All Scenarios [Algo: $(ALGO) | Cache: $(CACHE) | Checks: $(CHECKS)] ---"
	@./$(TARGET) $(CMD_ARGS)
	$(generate_graphs)
	@echo "--- Done. See $(RSLT_DIR)/ ---"

# 2. Run Specific Target
run-only: $(TARGET)
	@mkdir -p $(RSLT_DIR)
	@if [ -z "$(T)" ]; then \
		echo "[!] Error: Specify target T=<name> (e.g., make run-only T=even_ones)"; \
		exit 1; \
	fi
	@echo "--- Running $(T) [Algo: $(ALGO) | Cache: $(CACHE) | Checks: $(CHECKS)] ---"
	@./$(TARGET) -t $(T) $(CMD_ARGS)
	$(generate_graphs)

# 3. Interactive Mode
interactive: $(TARGET)
	@mkdir -p $(RSLT_DIR)
	@./$(TARGET) -i $(CMD_ARGS)

# 4. Single Target Benchmark (Runs 4 configurations for ONE target)
benchmark: $(TARGET)
	@mkdir -p $(RSLT_DIR)
	@if [ -z "$(T)" ]; then echo "[!] Specify T=<tag>"; exit 1; fi
	@echo "\n=== BENCHMARKING TARGET: $(T) ===\n"
	@echo "[1/4] RS + Cache..."
	@./$(TARGET) -t $(T) -algo rs -n $(CHECKS) > /dev/null
	@echo "[2/4] RS + Raw..."
	@./$(TARGET) -t $(T) -algo rs -no-cache -n $(CHECKS) > /dev/null
	@echo "[3/4] Angluin + Cache..."
	@./$(TARGET) -t $(T) -algo angluin -n $(CHECKS) > /dev/null
	@echo "[4/4] Angluin + Raw..."
	@./$(TARGET) -t $(T) -algo angluin -no-cache -n $(CHECKS) > /dev/null
	$(generate_graphs)

# 5. GRAND BENCHMARK: Runs Benchmark for ALL Scenarios
benchmark-all: $(TARGET)
	@mkdir -p $(RSLT_DIR)
	@echo "\n======================================="
	@echo "   RUNNING FULL SUITE BENCHMARK"
	@echo "=======================================\n"
	@# Script mágico: Pega a lista do programa, filtra e itera
	@./$(TARGET) -list | grep "^  [a-z]" | awk '{print $$1}' | while read tag; do \
		$(MAKE) --no-print-directory benchmark T=$$tag CHECKS=$(CHECKS); \
	done
	@echo "\n======================================="
	@echo "   FULL SUITE COMPLETED"
	@echo "   Check $(RSLT_DIR)/ for report folders."
	@echo "======================================="

# Lists
list: list-scenarios

list-scenarios: $(TARGET)
	@echo "\nAvailable Scenarios (Targets):"
	@echo "------------------------------"
	@./$(TARGET) -list | grep "^  "
	@echo "------------------------------"

list-algos:
	@echo "\nAvailable Algorithms:"
	@echo "---------------------"
	@echo "  rs       : Rivest-Schapire (Optimized, Default). Adds columns."
	@echo "  angluin  : Angluin (Standard). Adds rows (prefixes)."
	@echo "---------------------"

# Help
help:
	@echo "Akleenator Build System"
	@echo "======================="
	@echo "  make benchmark-all     : RUN EVERYTHING (All targets x 4 configs)."
	@echo "  make benchmark T=xxx   : Benchmark a single target."
	@echo "  make run               : Run standard tests (Default: RS + Cache)."
	@echo "  make run CHECKS=N      : Set random checks (Default: 3000)."
	@echo "  make run-only T=xxx    : Run specific target."
	@echo "  make list-scenarios    : List all problem definitions."
	@echo "  make list-algos        : List available algorithms."
	@echo "  make interactive       : Be the Oracle."
	@echo "  make clean             : Cleanup."