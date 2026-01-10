# ==========================================
#  PROJECT CONFIGURATION
# ==========================================

# --- Directory Structure ---
SRC_DIR  = src
TEST_DIR = tests
BIN_DIR  = bin
OBJ_DIR  = obj
RSLT_DIR = results

# --- Compiler & Flags ---
OCAMLC = ocamlc
# Include obj directory for dependencies and enable debug info
FLAGS  = -I $(OBJ_DIR) -g

# ==========================================
#  FILES & OBJECTS
# ==========================================

# Library modules (order matters for linking if side-effects exist, but usually safe here)
# Added 'targets' here so it gets compiled into LIB_OBJS
LIB_MODULES = dfa observationTable lStar targets

# Construct full paths for object files (e.g., obj/dfa.cmo)
LIB_OBJS = $(addprefix $(OBJ_DIR)/, $(addsuffix .cmo, $(LIB_MODULES)))

# Executable paths
TARGET      = $(BIN_DIR)/lstar
TEST_TARGET = $(BIN_DIR)/tests_run

# ==========================================
#  MAIN RULES
# ==========================================

.PHONY: all clean directories test run

all: directories $(TARGET) $(TEST_TARGET)

# Create output directories if they don't exist
directories:
	mkdir -p $(BIN_DIR) $(OBJ_DIR)

# --- Linking ---

# Main Application
$(TARGET): $(LIB_OBJS) $(OBJ_DIR)/main.cmo
	$(OCAMLC) $(FLAGS) -o $@ $^

# Test Suite
$(TEST_TARGET): $(LIB_OBJS) $(OBJ_DIR)/tests.cmo
	$(OCAMLC) $(FLAGS) -o $@ $^

# ==========================================
#  COMPILATION RULES
# ==========================================

# 1. Interfaces (.mli -> .cmi)
$(OBJ_DIR)/%.cmi: $(SRC_DIR)/%.mli
	$(OCAMLC) $(FLAGS) -c -o $@ $<

# 2. Source Implementations (.ml -> .cmo)
$(OBJ_DIR)/%.cmo: $(SRC_DIR)/%.ml
	$(OCAMLC) $(FLAGS) -c -o $@ $<

# 3. Test Implementations (.ml -> .cmo)
$(OBJ_DIR)/%.cmo: $(TEST_DIR)/%.ml
	$(OCAMLC) $(FLAGS) -c -o $@ $<

# ==========================================
#  DEPENDENCIES
# ==========================================
# Explicit compilation order for dependencies

# Core Logic
$(OBJ_DIR)/dfa.cmo: $(OBJ_DIR)/dfa.cmi
$(OBJ_DIR)/observationTable.cmo: $(OBJ_DIR)/observationTable.cmi $(OBJ_DIR)/dfa.cmo
$(OBJ_DIR)/lStar.cmo: $(OBJ_DIR)/lStar.cmi $(OBJ_DIR)/observationTable.cmo $(OBJ_DIR)/dfa.cmo

# Targets (Oracles) - Assuming it has no dependencies on other modules
$(OBJ_DIR)/targets.cmo: $(SRC_DIR)/targets.ml

# Main Entry Point
# Depends on all library modules including targets
$(OBJ_DIR)/main.cmo: $(OBJ_DIR)/lStar.cmo $(OBJ_DIR)/dfa.cmo $(OBJ_DIR)/targets.cmo

# Tests
$(OBJ_DIR)/tests.cmo: $(OBJ_DIR)/dfa.cmo

# ==========================================
#  UTILITY COMMANDS
# ==========================================

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR) $(RSLT_DIR)

# Compile and run the test suite
test: $(TEST_TARGET)
	@echo "--- Running Tests ---"
	@./$(TEST_TARGET)

# Compile, run main, and generate visualizations
run: $(TARGET)
	@mkdir -p $(RSLT_DIR)
	@echo "--- Running Akleenator ---"
	@./$(TARGET) $(ARGS)
	@echo "--- Generating Graphviz Images ---"
	@for file in $(RSLT_DIR)/*.dot; do \
		if [ -e "$$file" ]; then \
			echo "   [+] Converting $$(basename $$file) to PNG..."; \
			dot -Tpng "$$file" -o "$${file%.dot}.png"; \
		fi; \
	done
	@echo "--- Done. Results in $(RSLT_DIR)/ ---"