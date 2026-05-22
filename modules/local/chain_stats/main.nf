process CHAIN_STATS {

    tag "${meta.lift}"
    label 'process_single'

    // Note: manually update the package versions, tool does not have --version flag
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/htslib:1.23.1--37aad7e2f553142f' :
        'community.wave.seqera.io/library/htslib:1.23.1--45117a0a8dbaa21c' }"

    input:
    tuple val(meta), path(input), path(source_sizes)
    tuple val(meta2), path(target_sizes)

    output:
    tuple val(meta), path("*chain.stats.tsv"), emit: chain_stats
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('chain_stats.sh'), val('1.0'), topic: versions

    script:
    def args   = task.ext.args ?: ''
    """
    chain_stats.sh \\
        ${input} \\
        ${source_sizes} \\
        ${target_sizes}
    """

}
