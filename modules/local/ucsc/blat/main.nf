process BLAT {

    tag "$reference.baseName"
    label 'process_single'

    // Note: manually update the package versions, tool does not have --version flag
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-blat:482--d4d8db1718606b5d' :
        'community.wave.seqera.io/library/ucsc-blat:482--fd8b6a68314e0aca' }"

    input:
    tuple val(meta), path(query), val(meta2), path(reference)
    tuple val(meta3), path(ooc11)

    output:
    tuple val(meta), path("*.psl"), emit: blat_psl
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('blat'), val('482'), topic: versions

    script:
    def args  = task.ext.args ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def args4 = task.ext.args4 ?: ''
    def prefix = reference.baseName
    """
    blat \\
        ${reference} \\
        ${query} \\
        ${args} \\
        ${args2} \\
        ${args3} \\
        ${args4} \\
        -noHead \\
        ${prefix}.psl
    """

}
