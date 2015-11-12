include Makefile-ROBOT

SRC=plant-trait-ontology.obo

imports/seed.tsv: $(SRC)
	./util/dump-referenced-ids.pl $(SRC) > $@.tmp && mv $@.tmp $@

imports/%_mirrored.owl:
	wget --no-check-certificate $(OBO)/$*.owl -O $@ && touch $@
.PRECIOUS: imports/%_mirrored.owl

imports/%_filtered.owl: imports/%_mirrored.owl
	./robot filter -T imports/ro_filter.tsv -i $< -o $@
.PRECIOUS: imports/%_filtered.owl

imports/%_import.owl: imports/%_filtered.owl robot imports/seed.tsv
	./robot extract -m BOT -i $< -T imports/seed.tsv \
	   annotate -O $(OBO)/to/$@ -o $@
.PRECIOUS: imports/%_filtered.owl

imports/%_import.obo: imports/%_import.owl
	./robot convert -i $< -f OBO -o $@

plant-trait-ontology-reasoned.owl: plant-trait-ontology.obo
	robot reason -i $< -r ELK -o $@
plant-trait-ontology-reasoned.obo: plant-trait-ontology-reasoned.owl
	./robot convert -i $< -f OBO -o $@

reasoner-report.txt: plant-trait-ontology.obo
	owltools --use-catalog $< --run-reasoner -r elk -u > $@.tmp && egrep '(INFERENCE|UNSAT)' $@.tmp > $@
