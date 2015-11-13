
SRC=plant-trait-ontology.obo

all: plant-trait-ontology-reasoned.obo target/to.obo
test: plant-trait-ontology-reasoned.obo

include Makefile-ROBOT

MODS= ro chebi po pato eo go
all_imports: $(patsubst %, imports/%_import.obo, $(MODS))

imports/seed.tsv: $(SRC)
	./util/dump-referenced-ids.pl $(SRC) > $@.tmp && mv $@.tmp $@

imports/%_mirrored.owl:
	wget --no-check-certificate $(OBO)/$*.owl -O $@ && touch $@
.PRECIOUS: imports/%_mirrored.owl

imports/ro_filtered.owl: imports/ro_mirrored.owl
	owltools $< --merge-imports-closure --remove-tbox --remove-annotation-assertions -r -l -d --set-ontology-id $(OBO)/$*.owl -o $@

imports/%_filtered.owl: imports/%_mirrored.owl
	owltools $< --make-subset-by-properties -f BFO:0000050 --extract-mingraph --set-ontology-id $(OBO)/$*.owl -o $@
#	./robot filter -T imports/ro_filter.tsv -i $< -o $@
.PRECIOUS: imports/%_filtered.owl

imports/%_import.owl: imports/%_filtered.owl robot imports/seed.tsv
	./robot extract -m BOT -i $< -T imports/seed.tsv \
	   annotate -O $(OBO)/to/$@ -o $@
.PRECIOUS: imports/%_filtered.owl

imports/%_import.obo: imports/%_import.owl
	./robot convert -i $< -f OBO -o $@

plant-trait-ontology.obo.owl: plant-trait-ontology.obo
	./robot convert -i $<  -o $@

plant-trait-ontology-reasoned.owl: plant-trait-ontology.obo
	./robot reason -i $< -r ELK -o $@
plant-trait-ontology-reasoned.obo: plant-trait-ontology-reasoned.owl
	./robot convert -i $< -f OBO -o $@

reasoner-report.txt: plant-trait-ontology.obo
	owltools --use-catalog $< --run-reasoner -r elk -u > $@.tmp && egrep '(INFERENCE|UNSAT)' $@.tmp > $@

target/to.obo: $(SRC)
	ontology-release-runner --catalog-xml catalog-v001.xml $< --reasoner elk --simple --skip-format owx --outdir target --run-obo-basic-dag-check

subsets/to-basic.obo: target/to.obo
	owltools --use-catalog $< --remove-imports-declarations  --make-subset-by-properties -f // --set-ontology-id $(OBO)/to/subsets/to-basic.owl -o -f obo $@

# REPORTING
# See: https://github.com/Planteome/plant-trait-ontology/issues/302
pato-viol.tsv: $(SRC)
	blip-findall  -i $< -r pato "subclass(X,Y),genus(X,XQ),genus(Y,YQ),\+subclassRT(XQ,YQ)" -select "x(X,Y,XQ,YQ)" -label -no_pred > $@

