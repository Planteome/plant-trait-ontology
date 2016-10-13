## TO editors documentation

These notes are for the EDITORS of the Plant Trait Ontology

The release files are:

 * [to.obo](to.obo)
 * [to.owl](to.owl)
 * [to-basic.obo](to-basic.obo)

These are made using the Makefile (see below)

For more details on ontology management, please see the OBO tutorial:

 * https://github.com/jamesaoverton/obo-tutorial

## Editors' Version

Do you have an ID range in the idranges file (to-idranges.owl),
in this directory). If not, get one from the head curator. 

The editors version is [plant-trait-ontology.obo](plant-trait-ontology.obo)

** DO NOT EDIT to.obo OR to.owl **

to.obo is the release version

## ID Ranges

TODO - these are not set up

These are stored in the file

 * [to-idranges.owl](to-idranges.owl)

** ONLY USE IDs WITHIN YOUR RANGE!! **

## Setting ID ranges in Protege

Please see the guide on obofoundry.org
 
## Git Quick Guide

TODO add instructions here

## Release Manager notes

You should only attempt to make a release AFTER the edit version is
committed and pushed, and the travis build passes.

to release, change into this directory, and type

    make

If this looks good type:

    make prepare_release

This generates derived files such as to.owl and to.obo. The versionIRI
will be added.

Commit and push these files.

    git commit -a

And type a brief description of the release in the editor window

Finally type

    git push origin master

IMMEDIATELY AFTERWARDS (do *not* make further modifications) go here:

 * https://github.com/Planteome/plant-trait-ontology/releases/
 * https://github.com/Planteome/plant-trait-ontology/releases/new

The value of the "Tag version" field MUST be

    vYYYY-MM-DD

The initial lowercase "v" is REQUIRED. The YYYY-MM-DD *must* match
what is in the versionIRI of the derived to.owl (data-version in
to.obo).

Release title should be YYYY-MM-DD, optionally followed by a title (e.g. "january release")

Then click "publish release"

__IMPORTANT__: NO MORE THAN ONE RELEASE PER DAY.

The PURLs are already configured to pull from github. This means that
BOTH ontology purls and versioned ontology purls will resolve to the
correct ontologies. Try it!

 * http://purl.obolibrary.org/obo/to.owl <-- current ontology PURL
 * http://purl.obolibrary.org/obo/to/releases/YYYY-MM-DD.owl <-- change to the release you just made

For questions on this contact Chris Mungall or email obo-admin AT obofoundry.org

# Travis Continuous Integration System

Check the build status here: [![Build Status](https://travis-ci.org/Planteome/to.svg?branch=master)](https://travis-ci.org/Planteome/to)

This replaces Jenkins for this ontology

## General Guidelines

See:
http://wiki.geneontology.org/index.php/Curator_Guide:_General_Conventions
