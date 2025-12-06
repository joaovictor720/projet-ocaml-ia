# --- CONFIG ---
OCAMLC = ocamlc
TEST = dfa_tests

# --- REGLES ---

all: test

dfa.cmo: dfa.mli dfa.ml
	$(OCAMLC) -c dfa.mli
	$(OCAMLC) -c dfa.ml

$(TEST): dfa.cmo dfa_tests.ml
	ocamlfind ocamlc -o $(TEST) -package ounit2 -linkpkg dfa.cmo dfa_tests.ml

test: $(TEST)
	ocamlrun $(TEST)

clean:
	del /f *.cmi *.cmo *.cma $(TEST) 2>nul || true

.PHONY: all test clean
