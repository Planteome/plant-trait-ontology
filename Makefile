OBO=http://purl.obolibrary.org/obo
ONT=to
BASE=$(OBO)/$(ONT)
#SRC=plant-trait-ontology.owl
SRC=plant-trait-ontology.obo
RELEASEDIR=.
ROBOT= robot
OWLTOOLS= owltools
DOSDP = dosdp-tools
ROBOT_ENV = ROBOT_JAVA_ARGS=-Xmx8G
ROBOT = $(ROBOT_ENV) robot --catalog catalog-v001.xml


all: all_imports $(ONT).owl $(ONT).obo subsets/$(ONT)-basic.obo
test: $(ONT).owl $(ONT).obo
prepare_release: all

$(ONT).owl: $(SRC)
	$(ROBOT)  reason -e none -i $< -r ELK relax reduce -r ELK annotate -V $(BASE)/releases/`date +%Y-%m-%d`/$(ONT).owl -o $@
$(ONT).obo: $(ONT).owl
	$(ROBOT) convert -i $< -f obo --check false -o $(ONT).obo.tmp && grep -v '^owl-axioms:' $(ONT).obo.tmp > $@ && rm $(ONT).obo.tmp
#$(ONT).owl: $(ONT).json
#	$(ROBOT) convert --check false -f json -o $(ONT).json

subsets/$(ONT)-basic.obo: $(ONT).owl
	owltools --use-catalog $< --remove-imports-declarations --make-subset-by-properties -f BFO:0000050 --remove-dangling --remove-axioms -t EquivalentClasses --set-ontology-id $(OBO)/subsets/$(ONT)-basic.owl -o -f obo $@.tmp && mv $@.tmp $@


IMPORTS = chebi pato peco po go ncbitaxon ro envo

IMPORTS_OWL = $(patsubst %, imports/%_import.owl,$(IMPORTS)) $(patsubst %, imports/%_import.obo,$(IMPORTS))

# Make this target to regenerate ALL
all_imports: $(IMPORTS_OWL)

# Use ROBOT, driven entirely by terms lists NOT from source ontology
imports/%_import.owl: mirror/%.owl imports/%_terms.txt
	$(ROBOT) extract -i $< -T imports/$*_terms.txt --method BOT -O  $(BASE)/$@ -o $@
.PRECIOUS: imports/%_import.owl

imports/%_import.obo: imports/%_import.owl
	$(ROBOT) convert -i $< -f obo --check false -o $@

# clone remote ontology locally, perfoming some excision of relations and annotations
mirror/%.obo: $(SRC) 
	test -d mirror || mkdir mirror &&\
	wget --no-check-certificate $(OBO)/$*.obo -O $@ && touch $@
.PRECIOUS: mirror/%.obo
mirror/%.owl: mirror/%.obo
	$(OWLTOOLS) --no-debug $< --remove-annotation-assertions -l -s -d --remove-dangling-annotations --set-ontology-id $(OBO)/$*.owl  -o $@
.PRECIOUS: mirror/%.owl

release: $(ONT).owl $(ONT).obo


#######PATTERNS
PATTERNS_EQ_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/eq/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/eq/*.tsv))
PATTERNS_MORPH_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/morphology/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/morphology/*.tsv))
PATTERNS_COMPOSITION_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/composition/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/composition/*.tsv))
PATTERNS_PHENOTYPE_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/phenotype/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/phenotype/*.tsv))
PATTERNS_RATIO_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/ratio/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/ratio/*.tsv))
PATTERNS_QUALIFIER_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/qualifier/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/qualifier/*.tsv))
#PATTERNS_RESPONSIVITY_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/responsivity/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/responsivity/*.tsv))
#PATTERNS_RESPONSIVITYNOEO_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/responsivityNoEO/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/responsivityNoEO/*.tsv))

all_patterns: $(PATTERNS_RATIO_OWL) $(PATTERNS_PHENOTYPE_OWL) $(PATTERNS_COMPOSITION_OWL) $(PATTERNS_MORPH_OWL) $(PATTERNS_EQ_OWL) $(PATTERNS_QUALIFIER_OWL) #$(PATTERNS_RESPONSIVITY_OWL) $(PATTERNS_RESPONSIVITYNOEO_OWL)

patterns/eq/%_pattern.owl: patterns/eq/%.tsv
	$(DOSDP) --outfile=$@ --obo-prefixes=true --template=patterns/$*.yaml generate --infile=patterns/eq/$*.tsv
	robot annotate -O "http://purl.obolibrary.org/obo/to/patterns/$*_pattern.owl" -i $@ -o $@
	#patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/eq/$*.tsv -p patterns/eq.yaml -n $@ > $@

patterns/eq/%_pattern.obo: patterns/eq/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

patterns/morphology/%_pattern.owl: patterns/morphology/%.tsv
	$(DOSDP) --outfile=$@ --obo-prefixes=true --template=patterns/$*.yaml generate --infile=patterns/morphology/$*.tsv
	robot annotate -O "http://purl.obolibrary.org/obo/to/patterns/$*_pattern.owl" -i $@ -o $@
	#patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/morphology/$*.tsv -p patterns/morphology.yaml -n $@ > $@

patterns/morphology/%_pattern.obo: patterns/morphology/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

#patterns/responsivity/%_pattern.owl: patterns/responsivity/%.tsv
#	dosdp-tools --outfile=$@ --obo-prefixes=true --template=patterns/$*.yaml generate --infile=patterns/responsivity/$*.tsv
#	robot annotate -O "http://purl.obolibrary.org/obo/to/patterns/$*_pattern.owl" -i $@ -o $@
	#patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/responsivity/$*.tsv -p patterns/responsivity.yaml -n $@ > $@

#patterns/responsivity/%_pattern.obo: patterns/responsivity/%_pattern.owl
#	$(ROBOT) convert -i $< -f obo -o $@

patterns/composition/%_pattern.owl: patterns/composition/%.tsv
	$(DOSDP) --outfile=$@ --obo-prefixes=true --template=patterns/$*.yaml generate --infile=patterns/composition/$*.tsv
	robot annotate -O "http://purl.obolibrary.org/obo/to/patterns/$*_pattern.owl" -i $@ -o $@
	#patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/composition/$*.tsv -p patterns/composition.yaml -n $@ > $@

patterns/composition/%_pattern.obo: patterns/composition/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

patterns/phenotype/%_pattern.owl: patterns/phenotype/%.tsv
	$(DOSDP) --outfile=$@ --obo-prefixes=true --template=patterns/$*.yaml generate --infile=patterns/phenotype/$*.tsv
	robot annotate -O "http://purl.obolibrary.org/obo/to/patterns/$*_pattern.owl" -i $@ -o $@
	#patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/phenotype/$*.tsv -p patterns/phenotype.yaml -n $@ > $@

patterns/phenotype/%_pattern.obo: patterns/phenotype/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

patterns/ratio/%_pattern.owl: patterns/ratio/%.tsv
	$(DOSDP) --outfile=$@ --obo-prefixes=true --template=patterns/$*.yaml generate --infile=patterns/ratio/$*.tsv
	robot annotate -O "http://purl.obolibrary.org/obo/to/patterns/$*_pattern.owl" -i $@ -o $@
	#patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/ratio/$*.tsv -p patterns/ratio.yaml -n $@ > $@

patterns/ratio/%_pattern.obo: patterns/ratio/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

patterns/qualifier/%_pattern.owl: patterns/qualifier/%.tsv
	$(DOSDP) --outfile=$@ --obo-prefixes=true --template=patterns/$*.yaml generate --infile=patterns/qualifier/$*.tsv
	robot annotate -O "http://purl.obolibrary.org/obo/to/patterns/$*_pattern.owl" -i $@ -o $@
	#patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/ratio/$*.tsv -p patterns/ratio.yaml -n $@ > $@

patterns/qualifier/%_pattern.obo: patterns/qualifier/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

#patterns/responsivityNoEO/%_pattern.owl: patterns/responsivityNoEO/%.tsv
#	dosdp-tools --outfile=$@ --obo-prefixes=true --template=patterns/$*.yaml generate --infile=patterns/responsivityNoEO/$*.tsv
#	robot annotate -O "http://purl.obolibrary.org/obo/to/patterns/$*_pattern.owl" -i $@ -o $@
	#patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/responsivityNoEO/$*.tsv -p patterns/responsivityNoEO.yaml -n $@ > $@

#patterns/responsivityNoEO/%_pattern.obo: patterns/responsivityNoEO/%_pattern.owl
#	$(ROBOT) convert -i $< -f obo -o $@


#merge pattern files
PATTERNS = $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/eq/*.tsv)) 
PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/morphology/*.tsv)) 
#PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/responsivity/*.tsv)) 
PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/composition/*.tsv)) 
PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/phenotype/*.tsv)) 
PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/ratio/*.tsv)) 
PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/qualifier/*.tsv)) 
#PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/responsivityNoEO/*.tsv))

merge:
	$(ROBOT) merge --input patterns/empty_pattern.owl $(PATTERNS) --output patterns/merge_patterns.owl
	$(ROBOT) convert -i patterns/merge_patterns.owl -f obo --check false -o patterns/merge_patterns.obo

#print var function
print-%:
	@echo $* = $($*)