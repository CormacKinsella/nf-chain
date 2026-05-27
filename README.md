[![Pixi Badge](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/prefix-dev/pixi/main/assets/badge/v0.json)](https://pixi.sh)
![Nextflow](https://img.shields.io/badge/Nextflow-v26.4.1-brightgreen)

<p align="center">
  <img src="assets/nf-chain.svg" alt="nf-chain">
</p>

<div align="center"><strong>nf-chain: generate chain files and run genome to genome liftovers</strong></div><br>

## Brief description

`nf-chain` is an accessible Nextflow workflow for genome to genome liftovers

- If running chain generation, it takes assemblies as NCBI accessions or FASTA files

- It generates `chain` files between _**any number**_ of `source` assemblies and _**any number**_ of `target` assemblies, see tip 1

- Optionally also runs any number of coordinate liftovers on compatible inputs (`bed`/`gff`/`gtf`), though see tip 2 below

- For coordinate liftovers, users can choose to skip chain generation and instead provide their own chain file, though see tip 3 below:

> [!TIP]
>
>**Tip 1**
>- "Many sources to many targets" mode is the default. Users can also run in "one to many" or "many to one" modes to enforce respective validation of their assembly samplesheet
>
>**Tip 2**
>- `gff`/`gtf` liftovers are not recommended, for gene liftovers consider [Liftoff](https://github.com/agshumate/Liftoff)
>
>**Tip_3**
>- If `nf-chain` builds the `chain` files, users can run any number of liftovers for various `source/target` pairings, i.e.: `CIH_to_R64, & Y12_to_R64, & etc...`
>- However, if providing a `chain` file, users are limited to liftovers for that single `source/target` pairing, i.e.: `CIH_to_R64` (though it still accepts any number of `bed` files to lift)

## Quick start

This quick start assumes users have either `Docker`, `Apptainer`, or `Singularity` installed

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

The chain generation samplesheet (`.csv` format) specifies the assemblies and which roles they should serve:


| sample_name | file_role | identifier_type | identifier |
|-------------|-----------|-----------------|-------------------------------------------------|
| R64         | target    | accession       |GCF_000146045.2                                  |
| CIH_HP1     | source    | fasta           |/path/to/CIH.asm01.HP1.nuclear_genome.tidy.fa.gz |
| Y12         | source    | fasta           |/path/to/Y12.asm01.HP0.nuclear_genome.tidy.fa    |

- `sample_name`: assembly name
    - The assembly name does not need to be unique in the default mode (`many_to_many`)
    - In `one_to_many` mode, `nf-chain` enforces uniqueness on the target side
    - In `many_to_one` mode, `nf-chain` enforces uniqueness on the source side

- `file_role`: either `source` or `target`
    - There can be any number of sources and targets in the default mode
    - In `one_to_many` mode, `nf-chain` enforces one source
    - In `many_to_one` mode, `nf-chain` enforces one target

- `identifier_type`: whether the provided identifier is an `accession` or `fasta` path

- `identifier`: the assembly identifier, either an accession or path

### Liftover samplesheet (optional input if running liftover)

The liftover samplesheet (`.csv` format) specifies the files to lift and which chain to use:

| lift           | format | input                               |
|----------------|--------|-------------------------------------|
| Y12_to_R64     | bed    | /path/to/Y12_coords_to_lift.bed     |
| Y12_to_R64     | gff    | /path/to/Y12_gff_to_lift.gff        |
| CIH_HP1_to_R64 | bed    | /path/to/CIH_HP1_coords_to_lift.bed |

- `lift`: the lift key / chain prefix to use during liftover
    - This should be formatted as `source_to_target`, where `source` and `target` match assembly samplesheet `sample_name` entries
    - If a lift is requested that finds no valid pairing, `nf-chain` will output troublshooting information, e.g.:

```
ERROR: The requested liftover(s): 'CIH_HP1_to_hg38' had no match to a valid chain file prefix. Chains that will be generated have the prefixes: CIH_HP1_to_R64, Y12_to_R64
```

- `format`: format of the liftover input file

- `input`: path to the liftover input file

### User provided chain file (optional input if running liftover but not generating chains)

- The chain file should be named with the following structure: `source_to_target.chain` or `source_to_target.chain.gz`, where `source_to_target` matches the lift key in the liftover samplesheet
- If no match is found, `nf-chain` will output troubleshooting information

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

- Thus, if users want to run liftovers in both directions between a pair of assemblies, their assembly samplesheet should have four rows, with each assembly entered as both `source` and `target`, and they should run in the default `many_to_many` mode. In this example, `nf-chain` **will not** generate self to self chains - these pairings are filtered out

- Some aligners such as `BLAT/LASTZ` use the term `target` in a different sense, i.e., the `target reference` to be queried during alignment:
    - For these aligners, `nf-chain` treats the `source` assembly as the `target reference`, and the `target` assembly as the `query`

## A note on aligner choice

- `BLAT`: very closely related genomes, i.e., 95% or greater identity

- `LASTZ`: inter-species alignments

- `minimap2`: inter-species alignments, repetitive genomes
