process FASTA_TO_TWOBIT {

    tag "$meta.id"
    label 'process_low'

    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/ucsc-fatotwobit_ucsc-twobitinfo_ucsc-twobittofa:482--08736bbb2a787bd7' :
        'community.wave.seqera.io/library/ucsc-fatotwobit_ucsc-twobitinfo_ucsc-twobittofa:482--ac930b364d8e29f8' }"

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${meta.id}_genomic.2bit"), emit: twobit
    tuple val(meta), path("${meta.id}_genomic.2bit.chrom.sizes"), emit: chrom_sizes
    // tuple val(task.process), val('htslib'), eval('bgzip --version | head -n 1 | sed "s/.* //"'), topic: versions

    script:
    """
    faToTwoBit ${assembly} ${meta.id}_genomic.2bit
    twoBitInfo ${meta.id}_genomic.2bit stdout | sort -k2rn > ${meta.id}_genomic.2bit.chrom.sizes
    """

}
