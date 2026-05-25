process UCSC_LIFTOVER {
    tag "${meta.lift}.${liftover}"
    label 'process_single'

    // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ucsc-liftover:482--h0b57e2e_0' :
        'quay.io/biocontainers/ucsc-liftover:482--h0b57e2e_0' }"

    input:
    tuple val(meta), path(chain), path(liftover)

    output:
    tuple val(meta), path("*.lifted.*")  , emit: lifted
    tuple val(meta), path("*.unlifted.*"), emit: unlifted
    // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions
    tuple val("${task.process}"), val('liftover'), val('482'), topic: versions, emit: versions_ucsc

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def name = liftover.name.replaceAll(/\.gz$/, '')
    """
    liftOver \\
        ${args} \\
        ${liftover} \\
        ${chain} \\
        ${meta.lift}.lifted.${name} \\
        ${meta.lift}.unlifted.${name}

    gzip ${meta.lift}.*lifted.${name}
    """

}
