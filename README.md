[![Pixi Badge](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/prefix-dev/pixi/main/assets/badge/v0.json)](https://pixi.sh)
![Nextflow](https://img.shields.io/badge/Nextflow-v26.4.1-brightgreen)

<p align="center">
  <img src="assets/nf-chain.svg" alt="nf-chain">
</p>

<div align="center"><strong>nf-chain: Generate chain files and run genome to genome liftovers</strong></div><br>

## Brief description

`nf-chain` is an accessible Nextflow workflow for genome to genome liftovers

- Takes assemblies as NCBI accessions or FASTA files

- Generates `chain` files between _**any number**_ of `source` assemblies and _**one**_ `target` assembly

- Optionally also runs coordinate liftovers on compatible inputs (`bed`/`gff`)

- For coordinate liftovers, users can choose to skip chain generation and instead provide their own chain file, though see the tip below:

> [!TIP]
>- If `nf-chain` builds the `chain` files, users can run any number of liftovers on various `source/target` pairings, i.e.: `CIH_to_R64, & Y12_to_R64, & etc...`
>- However, if providing a `chain` file, users are limited to liftovers on that single `source/target` pairing, i.e.: `CIH_to_R64` (though it still accepts any number of `bed`/`gff` files to lift)

## Quick start

This quick start assumes users have either `Docker`, `Apptainer`, or `Singularity` already installed.

1. [Install Pixi](https://pixi.sh/latest/installation/): `curl -fsSL https://pixi.sh/install.sh | sh`
2. Clone the workflow repository: `git clone https://github.com/CormacKinsella/nf-chain.git`
3. Run `cd nf-chain && pixi install`

You can now run the test (generates chain files for two source yeast assemblies versus the R64 reference genome target, and carries out an example liftover):

`pixi run nextflow main.nf -profile apptainer,test -params-file tests/params-chain-lift.yml`

- Note: to use `singularity` or `docker`, replace `apptainer` with your choice

Get help with parameters:

`pixi run help`

## Input file setup

### Chain generation samplesheet

TODO
### Liftover samplesheet

TODO

### User provided chain file

TODO


## Example run commands

### To run only chain generation

`pixi run nextflow main.nf -profile apptainer --steps 'prepare_inputs,align_assemblies,generate_chains' --input genomes_samplesheet.csv`

### To run only liftover

`pixi run nextflow main.nf -profile apptainer --steps 'liftover' --chain_file Y12_to_R64.chain.gz --liftover_input liftover_samplesheet.csv`

### To run chain generation and liftover

`pixi run nextflow main.nf -profile apptainer --steps 'prepare_inputs,align_assemblies,generate_chains,liftover' --input genomes_samplesheet.csv --liftover_input liftover_samplesheet.csv`

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

## A note on aligner choice

- `BLAT`: very closely related genomes, i.e., 95% or greater identity

- `LASTZ`: inter-species alignments

- `minimap2`: inter-species alignments, repetitive genomes
