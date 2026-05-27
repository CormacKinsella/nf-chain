process AXTCHAIN {

    tag "${input.baseName}"
    label 'process_single'

    // Note: manually update the package versions, tool does not have --version flag
    container "docker://ghcr.io/cormackinsella/pixi-axtchain-chainbridge:latest"

    input:
    tuple val(meta), path(input), path(source_twobit), path(target_twobit)

    output:
    tuple val(meta), path("*.chain"), emit: axtchain
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('axtchain')   , val('482'), topic: versions
    tuple val(task.process), val('chainbridge'), val('377'), topic: versions

    script:
    def args   = task.ext.args ?: ''
    def args2  = task.ext.args2 ?: ''
    def args3  = task.ext.args3 ?: ''
    """
    axtChain \\
        -verbose=0 \\
        ${args} \\
        ${args2} \\
        ${args3} \\
        ${input} \\
        ${source_twobit} \\
        ${target_twobit} \\
        stdout | \\
    chainBridge \\
        ${args2} \\
        stdin \\
        ${source_twobit} \\
        ${target_twobit} \\
        ${input.baseName}.chain
    """

}
