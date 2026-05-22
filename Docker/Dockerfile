# Pixi environment docker build for axtChain + chainBridge
#
# Resolves the zlib conflict between bioconda::ucsc-axtchain:482 and
# bioconda::ucsc-chainbridge:377 by installing each in their own global environment
#
# ─────────────────────────────────────────────────────────────────────────────────

FROM ghcr.io/prefix-dev/pixi:latest AS build

RUN pixi global install -c conda-forge -c bioconda ucsc-axtchain ucsc-chainbridge

CMD ["bash"]

