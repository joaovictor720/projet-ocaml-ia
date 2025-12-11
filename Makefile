# Nom de l'exécutable final
EXEC = test_dfa

# Compilateur OCaml avec ocamlfind
OCAMLC = ocamlfind ocamlc
OCAMLOPT = ocamlfind ocamlopt

# Packages nécessaires
PKGS = -package ounit2 -linkpkg

# Fichiers sources
SOURCES = dfa.mli dfa.ml dfa_tests.ml

all: $(EXEC)

# Compilation bytecode
$(EXEC): $(SOURCES)
        $(OCAMLC) $(PKGS) -o $(EXEC) $(SOURCES)

# Exécution des tests
run: $(EXEC)
        ./$(EXEC)

# Nettoyage des fichiers générés
clean:
        rm -f *.cm* *.o $(EXEC)

# Nettoyage total
distclean: clean
        rm -f *~
