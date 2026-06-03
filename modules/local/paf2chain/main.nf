process PAF2CHAIN {
    tag "${meta.lift}"
    label 'process_low'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/paf2chain:0.1.1--7b27d97c7ba215e8' :
        'community.wave.seqera.io/library/paf2chain:0.1.1--4b1187b6b8ac56bf' }"

    input:
    tuple val(meta), path(paf)
    val(aligner)

    output:
    tuple val(meta), path("*.chain.gz"), emit: chain
    tuple val("${task.process}"), val("paf2chain"), eval("paf2chain --version | sed 's/paf2chain //'"), topic: versions

    script:
    """
    paf2chain \\
        --input ${paf} > \\
        ${meta.lift}.${aligner}.chain
    gzip ${meta.lift}.${aligner}.chain
    """

}
