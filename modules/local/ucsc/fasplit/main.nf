process SPLIT_FASTA {

    tag "$meta.id"
    label 'process_low'

    // Note: manually update the package versions, tool does not have --version flag
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-fasplit:482--3e4eb8be02c738ba' :
        'community.wave.seqera.io/library/ucsc-fasplit:482--387359b4c8a6b83e' }"

    input:
    tuple val(meta), path(assembly)
    val length

    output:
    tuple val(meta), path("*.lift"), emit: lift
    tuple val(meta), path("*.fa")  , emit: fasplit_assembly
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('faSplit'), val('482'), topic: versions

    script:
    def args = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    """
    # Run faSplit
    faSplit size -oneFile -lift=${args}.lift ${args2} ${assembly} ${length} ${args}
    """

}
