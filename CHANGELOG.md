# Changelog

## [?] - Unreleased

### minimap2 alignment

- override cpu config for HPC systems

## [2.0] - 2026-06-04

### minimap2

- minimap2 aligner option implemented

- `PAF2CHAIN` module fills the role of `axtChain` in the BLAT workflow. `paf2chain` converts `paf` to chain, `chainScore` reformats & calculates chain scores

- remainder of the chain generation workflow is the same

### Other

- Added general option to run chainAntiRepeat (default true)

- All outputs now include an aligner tag in the name, so that users can run both sequentially and compare their outputs without dealing with nameclashes

- Modularity of relevant subworkflows improved to deal with different tools/formats. e.g., chain_generation subworkflows are now aligner agnostic and instead focus on input format (more future proof if adding `rammap`, or other aligners)

## [1.1] - 2026-06-03

- Added slurm helper script

- Updated README

- Updated schema to allow only implemented and near-term planned aligners

- Removed `chainbridge` (and thus also Dockerfile) - tests at scale showed it can reproducibly introduce errors into chains that break downstream processing

- Added `chainsort` between axt and merge

## [1.0] - 2026-05-27

- Initial full release with BLAT aligner only
