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
    //    tuple val(meta), path("*.fa")  , emit: fasplit_assembly
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('blat'), val('482'), topic: versions

    script:
    def args  = task.ext.args ?: ''
    def prefix = reference.baseName
    """
    blat \\
        ${reference} \\
        ${query} \\
        ${args} \\
        ${prefix}.psl

    """

}
