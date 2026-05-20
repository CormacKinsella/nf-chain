process AXTCHAIN {

    tag "${psl.baseName}"
    label 'process_single'

    // Note: manually update the package versions, tool does not have --version flag
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-axtchain:482--3de1a6fe14027cb9' :
        'community.wave.seqera.io/library/ucsc-axtchain:482--655ecc99e8f95302' }"

    input:
    tuple val(meta) , path(psl)
    tuple val(meta2), path(source_twobit)
    tuple val(meta3), path(target_twobit)

    output:
    //TODO tuple val(meta), path("*lifted.psl"), emit: blat_psl
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('axtchain')  , val('482'), topic: versions

    script:
    def args   = task.ext.args ?: ''
    """
    echo "Running axtChain"
    """

}
