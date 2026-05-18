process KMERS_TO_EXCLUDE {

    tag "$meta.id"
    label 'process_single'

    // Note: manually update the package versions, tool does not have --version flag
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-blat:482--d4d8db1718606b5d' :
        'community.wave.seqera.io/library/ucsc-blat:482--fd8b6a68314e0aca' }"

    input:
    tuple val(meta), path(query)
    val repMatch

    output:
    tuple val(meta), path("11.ooc"), emit: ooc11
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('blat'), val('482'), topic: versions

    script:
    def args = task.ext.args ?: ''
    """
    blat ${query} /dev/null /dev/null -makeOoc=11.ooc -tileSize=11 -repMatch=${repMatch}
    """

}
