process UNZIP_ASSEMBLY {

    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/htslib:1.23.1--37aad7e2f553142f' :
        'community.wave.seqera.io/library/htslib:1.23.1--45117a0a8dbaa21c' }"

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("*_genomic.fna"), emit: assembly
    tuple val(task.process), val('htslib'), eval('bgzip --version | head -n 1 | sed "s/.* //"'), topic: versions

    script:
    """
    # Check file extension
    if [[ ${assembly} == *.gz ]]; then
        bgzip --decompress --threads ${task.cpus} --output ${meta.id}_genomic.fna ${assembly}
    else
        mv ${assembly} ${meta.id}_genomic.fna
    fi
    """

}