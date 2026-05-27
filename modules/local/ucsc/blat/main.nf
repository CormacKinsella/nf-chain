process BLAT {

    tag "${meta.lift}.${query.baseName.tokenize('_').last()}"
    label 'process_single'

    // Note: manually update the package versions, tool does not have --version flag
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-blat_ucsc-liftup:482--cf513677f79143e4' :
        'community.wave.seqera.io/library/ucsc-blat_ucsc-liftup:482--595a990204ffd428' }"

    input:
    tuple val(meta), path(target_reference), path(source_lift), path(ooc11), path(query), path(target_lift)

    output:
    tuple val(meta), path("*lifted.psl"), emit: blat_psl
    // Note: manually update the package versions, tool does not have --version flag
    tuple val(task.process), val('blat')  , val('482'), topic: versions
    tuple val(task.process), val('liftup'), val('482'), topic: versions

    script:
    def args   = task.ext.args ?: ''
    def args2  = task.ext.args2 ?: ''
    def args3  = task.ext.args3 ?: ''
    def args4  = task.ext.args4 ?: ''
    def args5  = task.ext.args5 ?: ''
    def args6  = task.ext.args6 ?: ''
    def number = query.baseName.tokenize('_').last()
    """
    blat \\
        ${target_reference} \\
        ${query} \\
        ${args} \\
        ${args2} \\
        ${args3} \\
        ${args4} \\
        ${args5} \\
        ${args6} \\
        -noHead \\
        unlifted.psl

    # First lift source names (coords are already correct), then lift target names/coords
    liftUp \\
        -type=.psl \\
        -nohead \\
        stdout \\
        ${source_lift} \\
        warn \\
        unlifted.psl | \\
    liftUp \\
        -type=.psl \\
        -nohead \\
        -pslQ \\
        ${meta.lift}.${number}.lifted.psl \\
        ${target_lift} \\
        warn \\
        stdin

    rm unlifted.psl
    """

}
