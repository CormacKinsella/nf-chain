process MINIMAP2_ALIGN {

    tag "${meta.lift}"
    // Note cpus controlled via conf/tool_resources.config
    label 'process_high'

    // Note: the versions here need to match the versions used in nf-core/minimap2/index
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/40/40a39951375e148d401c77e200777053cb628a4095bda598f7d41db08cbbfa4c/data' :
        'community.wave.seqera.io/library/minimap2:2.30--dde6b0c5fbc82ebd' }"

    input:
    tuple val(meta), path(mmi), path(query)

    output:
    tuple val(meta), path("*.paf"), emit: paf
    tuple val("${task.process}"), val("minimap2"), eval("minimap2 --version"), topic: versions, emit: versions_minimap2

    when:
    task.ext.when == null || task.ext.when

    script:
    def args  = task.ext.args ?: ''
    """
    minimap2 \\
        ${args} \\
        -t ${task.cpus} \\
        ${mmi} \\
        ${query} > \\
        ${meta.lift}.paf
    """

}
