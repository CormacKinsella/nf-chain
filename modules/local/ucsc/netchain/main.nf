process NET_CHAIN {

    tag "${meta.lift}"
    label 'process_single'

    // Note: manually update the package versions, tool does not have --version flag
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-chainnet_ucsc-chainstitchid_ucsc-netchainsubset:482--0e37740b86a7ca04' :
        'community.wave.seqera.io/library/ucsc-chainnet_ucsc-chainstitchid_ucsc-netchainsubset:482--2a99db76a6a05028' }"

    input:
    tuple val(meta), path(input), path(source_sizes), path(target_sizes)

    output:
    tuple val(meta), path("${meta.lift}.chain.gz"), emit: final_chain
    tuple val(meta), path("${meta.lift}.chain.gz"), path(source_sizes), path(target_sizes), emit: chain_stats_in
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('chainnet'), val('482'), topic: versions
    tuple val(task.process), val('netchainsubset'), val('482'), topic: versions
    tuple val(task.process), val('chainstitchid'), val('482'), topic: versions

    script:
    def args   = task.ext.args ?: ''
    """
    mkdir nets liftover_split
    for i in tmp/*.chain; do \\
        chainNet \$i \\
            ${source_sizes} \\
            ${target_sizes} \\
            nets/\${i#tmp/}.net \\
            /dev/null
        netChainSubset \\
            nets/\${i#tmp/}.net \\
            \$i \\
            stdout | \\
        chainStitchId \\
            stdin \\
            liftover_split/\${i#tmp/}
    done

    # Prepare final liftover chain file
    cat liftover_split/*.chain | gzip -c > ${meta.lift}.chain.gz
    """

}
