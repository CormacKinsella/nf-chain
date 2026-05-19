[![Pixi Badge](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/prefix-dev/pixi/main/assets/badge/v0.json)](https://pixi.sh)
![Nextflow](https://img.shields.io/badge/Nextflow-v26.4.1-brightgreen)

<div align="center"><strong>nf-chain: Generate chain files for genome to genome liftovers</strong></div><br>

## Brief description

`nf-chain` is an accessible Nextflow workflow for generating `chain` files between a source and target assembly, provided either as a local/remote FASTA file, or an NCBI accession.


## Quick start

This quick start assumes users have either `Docker`, `Apptainer`, or `Singularity` already installed.

1. [Install Pixi](https://pixi.sh/latest/installation/): `curl -fsSL https://pixi.sh/install.sh | sh`
2. Clone the Workflow repository: `git clone https://github.com/CormacKinsella/nf-chain.git`
3. Run `cd nf-chain && pixi install`

You can now run the test (two yeast genomes):

`pixi run nextflow main.nf -profile apptainer,test -params-file tests/params.yml`

- Note: to use `singularity` or `docker`, replace `apptainer` with your choice

Or get help with parameters:

`pixi run help`

## A note on terminology

- Liftovers convert genomic coordinates between genome assemblies

- In the liftover sense:
    - The `source assembly` has the old coordinate system that you no longer want
    - The `target assembly` has the new coordinate system you are trying to convert to
    - For inputs or parameters referring to `source` or `target`, users should follow this meaning

- The `chain file` links the `source` and `target` coordinates unidirectionally, i.e., only for converting from `source` to `target`

- Some aligners such as `BLAT` use the term `target` in a different sense, i.e., the `target reference` to be queried during alignment:
    - `BLAT` indexes the `target reference` (our `source` assembly) as non-overlapping 11-mers and keeps it in memory
    - The `query` (our `target` assembly) is broken into small chunks and aligned
    - `nf-chain` handles these tasks under the hood

## Aligner choice

- `BLAT`: very closely related genomes, i.e., 95% or greater identity

- `LASTZ`: inter-species alignments

- `minimap2`: inter-species alignments, repetitive genomes
