process DOWNLOAD_ASSEMBLY {

    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ncbi-datasets-cli_unzip:4025a943d8f47c40' :
        'community.wave.seqera.io/library/ncbi-datasets-cli_unzip:13874bef6266a9b3' }"

    input:
    val meta

    output:
    tuple val(meta), path("*_genomic.fna"), emit: assembly
    tuple val("${task.process}"), val('ncbi-datasets-cli'), eval('datasets --version | sed "s/.* //"'), topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args           = task.ext.args ?: ''
    """
    datasets ${args} \\
        ${meta.identifier}

    unzip -q ncbi_dataset.zip

    find ncbi_dataset/data -name "*_genomic.fna" -exec mv {} ./${meta.id}_genomic.fna \\;
    """

}
