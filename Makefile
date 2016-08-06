OBO=http://purl.obolibrary.org/obo
ONT=to
BASE=$(OBO)/$(ONT)
#SRC=plant-trait-ontology.obo.owl
SRC=plant-trait-ontology.obo
RELEASEDIR=.
ROBOT= robot
OWLTOOLS= owltools


all: all_imports $(ONT).owl $(ONT).obo
test: all
prepare_release: all

$(ONT).owl: $(SRC)
	$(ROBOT)  reason -i $< -r ELK relax reduce -r ELK annotate -V $(BASE)/releases/`date +%Y-%m-%d`/$(ONT).owl -o $@
$(ONT).obo: $(ONT).owl
	$(ROBOT) convert -i $< -f obo -o $(ONT).obo.tmp && mv $(ONT).obo.tmp $@



IMPORTS = chebi pato eo po go
IMPORTS_OWL = $(patsubst %, imports/%_import.owl,$(IMPORTS)) $(patsubst %, imports/%_import.obo,$(IMPORTS))

# Make this target to regenerate ALL
all_imports: $(IMPORTS_OWL)

# Use ROBOT, driven entirely by terms lists NOT from source ontology
imports/%_import.owl: mirror/%.owl imports/%_terms.txt
	$(ROBOT) extract -i $< -T imports/$*_terms.txt --method BOT -O  $(BASE)/$@ -o $@
.PRECIOUS: imports/%_import.owl

imports/%_import.obo: imports/%_import.owl
	$(OWLTOOLS) $(USECAT) $< -o -f obo $@

# clone remote ontology locally, perfoming some excision of relations and annotations
mirror/%.obo: $(SRC) 
	test -d mirror || mkdir mirror &&\
	wget --no-check-certificate $(OBO)/$*.obo -O $@ && touch $@
.PRECIOUS: mirror/%.obo
mirror/%.owl: mirror/%.obo
	$(OWLTOOLS) --no-debug $< --remove-annotation-assertions -l -s -d --remove-dangling-annotations --set-ontology-id $(OBO)/$*.owl  -o $@
.PRECIOUS: mirror/%.owl

release: $(ONT).owl $(ONT).obo
