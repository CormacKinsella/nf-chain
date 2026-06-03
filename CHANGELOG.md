# Changelog


## [1.1] - 2026-06-03

- Added slurm helper script

- Updated README

- Updated schema to allow only implemented and near-term planned aligners

- Removed `chainbridge` (and thus also Dockerfile) - tests at scale showed it can reproducibly introduce errors into chains that break downstream processing

- Added `chainsort` between axt and merge

## [1.0] - 2026-05-27

- Initial full release with BLAT aligner only
