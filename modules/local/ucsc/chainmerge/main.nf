process MERGE_CHAINS {

    tag "${meta.lift}"
    label 'process_single'

    // Note: manually update the package versions, tool does not have --version flag
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-chainmergesort_ucsc-chainsplit:482--19faeeaea237cecb' :
        'community.wave.seqera.io/library/ucsc-chainmergesort_ucsc-chainsplit:482--111fa6df46d4f34a' }"

    input:
    tuple val(meta), path(chains)

    output:
    tuple val(meta), path("tmp"), emit: merged_chain
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('chainmergesort'), val('482'), topic: versions
    tuple val(task.process), val('chainsplit'), val('482'), topic: versions

    script:
    def args   = task.ext.args ?: ''
    """
    chainMergeSort *.chain  | \\
        chainSplit ${args} tmp stdin
    """

}
