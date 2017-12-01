OBO=http://purl.obolibrary.org/obo
ONT=to
BASE=$(OBO)/$(ONT)
#SRC=plant-trait-ontology.obo.owl
SRC=plant-trait-ontology.obo
RELEASEDIR=.
ROBOT= robot
OWLTOOLS= owltools


all: all_imports $(ONT).owl $(ONT).obo subsets/$(ONT)-basic.obo
test: $(ONT).owl $(ONT).obo
prepare_release: all

$(ONT).owl: $(SRC)
	$(ROBOT)  reason -i $< -r ELK relax reduce -r ELK annotate -V $(BASE)/releases/`date +%Y-%m-%d`/$(ONT).owl -o $@
$(ONT).obo: $(ONT).owl
	$(ROBOT) convert -i $< -f obo -o $(ONT).obo.tmp && grep -v '^owl-axioms:' $(ONT).obo.tmp > $@ && rm $(ONT).obo.tmp

subsets/$(ONT)-basic.obo: $(ONT).owl
	owltools --use-catalog $< --remove-imports-declarations --make-subset-by-properties -f BFO:0000050 --remove-dangling --remove-axioms -t EquivalentClasses --set-ontology-id $(OBO)/subsets/$(ONT)-basic.owl -o -f obo $@.tmp && mv $@.tmp $@

IMPORTS = chebi pato peco po go ncbitaxon ro
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


#######PATTERNS
PATTERNS_EQ_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/eq/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/eq/*.tsv))
PATTERNS_MORPH_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/morphology/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/morphology/*.tsv))
PATTERNS_COMPOSITION_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/composition/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/composition/*.tsv))
PATTERNS_PHENOTYPE_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/phenotype/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/phenotype/*.tsv))
PATTERNS_RATIO_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/ratio/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/ratio/*.tsv))
PATTERNS_RESPONSIVITY_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/responsivity/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/responsivity/*.tsv))
PATTERNS_RESPONSIVITYNOEO_OWL = $(patsubst %.tsv, %_pattern.owl, $(wildcard patterns/responsivityNoEO/*.tsv)) $(patsubst %.tsv, %_pattern.obo, $(wildcard patterns/responsivityNoEO/*.tsv))

all_patterns: $(PATTERNS_RATIO_OWL) $(PATTERNS_PHENOTYPE_OWL) $(PATTERNS_COMPOSITION_OWL) $(PATTERNS_MORPH_OWL) $(PATTERNS_EQ_OWL) $(PATTERNS_RESPONSIVITY_OWL) $(PATTERNS_RESPONSIVITYNOEO_OWL)

patterns/eq/%_pattern.owl: patterns/eq/%.tsv
	patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/eq/$*.tsv -p patterns/eq.yaml -n $@ > $@

patterns/eq/%_pattern.obo: patterns/eq/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

patterns/morphology/%_pattern.owl: patterns/morphology/%.tsv
	patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/morphology/$*.tsv -p patterns/morphology.yaml -n $@ > $@

patterns/morphology/%_pattern.obo: patterns/morphology/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

patterns/responsivity/%_pattern.owl: patterns/responsivity/%.tsv
	patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/responsivity/$*.tsv -p patterns/responsivity.yaml -n $@ > $@

patterns/responsivity/%_pattern.obo: patterns/responsivity/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

patterns/composition/%_pattern.owl: patterns/composition/%.tsv
	patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/composition/$*.tsv -p patterns/composition.yaml -n $@ > $@

patterns/composition/%_pattern.obo: patterns/composition/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

patterns/phenotype/%_pattern.owl: patterns/phenotype/%.tsv
	patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/phenotype/$*.tsv -p patterns/phenotype.yaml -n $@ > $@

patterns/phenotype/%_pattern.obo: patterns/phenotype/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

patterns/ratio/%_pattern.owl: patterns/ratio/%.tsv
	patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/ratio/$*.tsv -p patterns/ratio.yaml -n $@ > $@

patterns/ratio/%_pattern.obo: patterns/ratio/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@

patterns/responsivityNoEO/%_pattern.owl: patterns/responsivityNoEO/%.tsv
	patterns/apply-pattern.py -P patterns/curie_map.yaml -i patterns/responsivityNoEO/$*.tsv -p patterns/responsivityNoEO.yaml -n $@ > $@

patterns/responsivityNoEO/%_pattern.obo: patterns/responsivityNoEO/%_pattern.owl
	$(ROBOT) convert -i $< -f obo -o $@


#merge pattern files
PATTERNS = $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/eq/*.tsv)) 
PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/morphology/*.tsv)) 
PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/responsivity/*.tsv)) 
PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/composition/*.tsv)) 
PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/phenotype/*.tsv)) 
PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/ratio/*.tsv)) 
PATTERNS += $(patsubst %.tsv, --input %_pattern.owl, $(wildcard patterns/responsivityNoEO/*.tsv))

merge:
	$(ROBOT) merge $(PATTERNS) --output patterns/merge_patterns.owl
	$(ROBOT) convert -i patterns/merge_patterns.owl -f obo -o patterns/merge_patterns.obo

#print var function
print-%:
	@echo $* = $($*)