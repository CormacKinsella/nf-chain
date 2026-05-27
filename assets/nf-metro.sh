# pixi global install -c conda-forge -c bioconda nf-metro

# pixi run nextflow main.nf -profile apptainer,dag,test -params-file tests/params-chain-lift.yml

# nf-metro render --from-nextflow  full.mmd --animate --theme light --no-straight-diamonds --title nf-chain --line-order definition

# Manually edited some names in the SVG
