process AXTCHAIN {

    tag "${input.baseName}"
    label 'process_single'

    // Note: manually update the package versions, tool does not have --version flag
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-axtchain:482--3de1a6fe14027cb9' :
        'community.wave.seqera.io/library/ucsc-axtchain:482--655ecc99e8f95302' }"

    input:
    tuple val(meta) , path(input), path(source_twobit)
    tuple val(meta2), path(target_twobit)

    output:
    tuple val(meta), path("*.chain"), emit: axtchain
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('axtchain'), val('482'), topic: versions

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
        ${input.baseName}.chain
    """

}
