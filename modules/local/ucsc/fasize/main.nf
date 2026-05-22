process COMPUTE_SIZES {

    tag "$meta.id"
    label 'process_low'

    // Note: manually update the package versions, tool does not have --version flag
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-fasize:482--010b2d8c8e567db7' :
        'community.wave.seqera.io/library/ucsc-fasize:482--b17e2bc2f92b3fa7' }"

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), env('MAX_SIZE'), emit: max_size
    tuple val(meta), env('REAL_SIZE'), emit: real_size
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('faSize'), val('482'), topic: versions

    script:
    """
    MAX_SIZE=`faSize -tab ${assembly} | awk '\$1=="maxSize" {print \$2}'`
    REAL_SIZE=`faSize -tab ${assembly} | awk '\$1=="realBaseCount" {print \$2}'`
    """

}
