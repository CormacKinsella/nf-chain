process PAF2CHAIN {
    tag "${meta.lift}"
    label 'process_low'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/paf2chain_ucsc-chainantirepeat_ucsc-chainscore:acc82edcff804537' :
        'community.wave.seqera.io/library/paf2chain_ucsc-chainantirepeat_ucsc-chainscore:0f4a0297f1daa8d1' }"

    input:
    tuple val(meta), path(paf), path(source_twobit), path(target_twobit)

    output:
    tuple val(meta), path("${meta.lift}.chain")         , emit: chain
    tuple val(meta), path("${meta.lift}.antiRep.chain") , emit: antiRep, optional: true
    tuple val("${task.process}"), val("paf2chain")      , eval("paf2chain --version | sed 's/paf2chain //'"), topic: versions
    // Note: manually update the package versions, tool does not have --version flag
    tuple val("${task.process}"), val("chainscore")     , val('455'), topic: versions
    tuple val("${task.process}"), val("chainAntiRepeat"), val('482'), topic: versions

    script:
    def args   = task.ext.args ?: ''
    """
    paf2chain \\
        --input ${paf} | \\
    chainScore \\
        stdin \\
        ${source_twobit} \\
        ${target_twobit} \\
        ${meta.lift}.chain
    ${args}
    """

}
