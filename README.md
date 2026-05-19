# nf-chain


BLAT: close genomes. E.g., alignments must have at least 90% identity

Generate chain files for genome to genome liftovers


- repeat masking...

- splitting, when to do it and at which point?

- Inter-species, generally use lastz

- Intra-species, generally use blat
    - time with single core, yeast genome, no masking, no chunking ~45 mins...

- minimap2 also an option



## A note on terminology

- Liftovers convert genomic coordinates between genome assemblies

- The `source assembly` has the old coordinate system that you no longer want

- The `target assembly` has the new coordinate system you are trying to convert to

- The `chain file` links the source and target coordinates unidirectionally and is used when converting in one direction, i.e., two are required for converting back and forth

- Note that internally, the `source` assembly acts as the alignment reference (i.e., the database), and the `target` will be the query



