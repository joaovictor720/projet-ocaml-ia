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
FLAGS  = -I $(OBJ_DIR) -g

# ==========================================
#  FILES & OBJECTS
# ==========================================

LIB_MODULES = dfa observationTable lStar targets
LIB_OBJS    = $(addprefix $(OBJ_DIR)/, $(addsuffix .cmo, $(LIB_MODULES)))

TARGET      = $(BIN_DIR)/lstar
TEST_TARGET = $(BIN_DIR)/tests_run

# ==========================================
#  MAIN RULES
# ==========================================

.PHONY: all clean test run interactive run-only help

all: $(TARGET) $(TEST_TARGET)

# --- Linking ---

$(TARGET): $(LIB_OBJS) $(OBJ_DIR)/main.cmo
	@mkdir -p $(BIN_DIR)
	$(OCAMLC) $(FLAGS) -o $@ $^

$(TEST_TARGET): $(LIB_OBJS) $(OBJ_DIR)/tests.cmo
	@mkdir -p $(BIN_DIR)
	$(OCAMLC) $(FLAGS) -o $@ $^

# ==========================================
#  COMPILATION RULES
# ==========================================
# FIX: We ensure the OBJ_DIR exists inside the rule to avoid race conditions

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
#  DEPENDENCIES
# ==========================================

$(OBJ_DIR)/dfa.cmo: $(OBJ_DIR)/dfa.cmi
$(OBJ_DIR)/observationTable.cmo: $(OBJ_DIR)/observationTable.cmi $(OBJ_DIR)/dfa.cmo
$(OBJ_DIR)/lStar.cmo: $(OBJ_DIR)/lStar.cmi $(OBJ_DIR)/observationTable.cmo $(OBJ_DIR)/dfa.cmo
$(OBJ_DIR)/targets.cmo: $(OBJ_DIR)/targets.cmi $(SRC_DIR)/targets.ml
$(OBJ_DIR)/main.cmo: $(OBJ_DIR)/lStar.cmo $(OBJ_DIR)/dfa.cmo $(OBJ_DIR)/targets.cmo
$(OBJ_DIR)/tests.cmo: $(OBJ_DIR)/dfa.cmo

# ==========================================
#  COMMANDS & UTILITIES
# ==========================================

clean:
	rm -rf $(OBJ_DIR) $(BIN_DIR) $(RSLT_DIR)

test: $(TEST_TARGET)
	@echo "--- Running Test Suite ---"
	@./$(TEST_TARGET)

# Helper function to generate PNGs from DOT files
define generate_graphs
	@echo "--- Generating Graphviz Images ---"
	@for file in $(RSLT_DIR)/*.dot; do \
		if [ -e "$$file" ]; then \
			echo "   [+] Converting $$(basename $$file) to PNG..."; \
			dot -Tpng "$$file" -o "$${file%.dot}.png"; \
		fi; \
	done
endef

# 1. Run Everything (Automated)
run: $(TARGET)
	@mkdir -p $(RSLT_DIR)
	@echo "--- Running All Scenarios ---"
	@./$(TARGET)
	$(generate_graphs)
	@echo "--- Done. See $(RSLT_DIR)/ ---"

# 2. Run Interactive Mode
interactive: $(TARGET)
	@mkdir -p $(RSLT_DIR)
	@./$(TARGET) -i
	$(generate_graphs)

# 3. Run Specific Target (Usage: make run-only T=tag_name)
run-only: $(TARGET)
	@mkdir -p $(RSLT_DIR)
	@if [ -z "$(T)" ]; then \
		echo "[!] Error: Please specify a target using T=<name>"; \
		echo "    Example: make run-only T=even_ones"; \
		exit 1; \
	fi
	@./$(TARGET) -t $(T)
	$(generate_graphs)

# 4. List Available Targets
list: $(TARGET)
	@./$(TARGET) -list

# 5. Help Menu
help:
	@echo "Akleenator Build System"
	@echo "======================="
	@echo "  make              : Compile the project."
	@echo "  make run          : Run all automated scenarios."
	@echo "  make run-only T=x : Run specific scenario 'x' (e.g., T=even_ones)."
	@echo "  make interactive  : Run as Human Oracle (manual input)."
	@echo "  make list         : List all available scenarios."
	@echo "  make test         : Run unit tests."
	@echo "  make clean        : Remove build artifacts."