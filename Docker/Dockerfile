# Pixi environment docker build for axtChain + chainBridge
#
# Resolves the zlib conflict between bioconda::ucsc-axtchain:482 and
# bioconda::ucsc-chainbridge:377 by installing each in their own global environment
#
# ─────────────────────────────────────────────────────────────────────────────────

FROM ghcr.io/prefix-dev/pixi:latest

ENV PIXI_HOME=/opt/pixi

RUN pixi global install -c conda-forge -c bioconda ucsc-axtchain ucsc-chainbridge

ENV PATH="/opt/pixi/bin:${PATH}"

CMD ["bash"]
