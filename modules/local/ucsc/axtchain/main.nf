process AXTCHAIN {

    tag "${input.baseName}"
    label 'process_single'

    // Note: manually update the package versions, tool does not have --version flag
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-axtchain_ucsc-chainantirepeat_ucsc-chainsort:482--f85baf227245c0b5' :
        'community.wave.seqera.io/library/ucsc-axtchain_ucsc-chainantirepeat_ucsc-chainsort:482--70e7e2a6dbfa1a7c' }"

    input:
    tuple val(meta), path(input), path(source_twobit), path(target_twobit)

    output:
    tuple val(meta), path("${input.baseName}.chain")           , emit: axtchain
    tuple val(meta), path("${input.baseName}.antiRep.chain")   , emit: antiRep, optional: true
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('axtchain') , val('482')      , topic: versions
    tuple val(task.process), val('chainsort'), val('482')      , topic: versions
    tuple val(task.process), val('chainantirepeat'), val('482'), topic: versions

    script:
    def args   = task.ext.args ?: ''
    def args2  = task.ext.args2 ?: ''
    def args3  = task.ext.args3 ?: ''
    def args4  = task.ext.args4 ?: ''
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
    chainSort \\
        stdin \\
        ${input.baseName}.chain
    ${args4}
    """

}
