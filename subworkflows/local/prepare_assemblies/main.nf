include { DOWNLOAD_ASSEMBLY } from '../../../modules/local/ncbi-datasets-cli/main'
include { UNZIP_ASSEMBLY    } from '../../../modules/local/unzip/main'
include { FASTA_TO_TWOBIT   } from '../../../modules/local/ucsc/twobit/main'

workflow PREPARE_ASSEMBLIES {

    take:
    samplesheet

    main:

    // Separate local FASTA from accessions to download
    samplesheet
        .branch { meta ->
            accession: meta.type == 'accession'
                return meta
            fasta: meta.type == 'fasta'
                return tuple( meta, file(meta.identifier, checkIfExists: true) )
        }.set { assembly }

    // Get assemblies provided as accessions
    DOWNLOAD_ASSEMBLY (
        assembly.accession
    )

    // Prepare assemblies provided as local FASTA files
    UNZIP_ASSEMBLY (
        assembly.fasta
    )

    // Mix assemblies
    DOWNLOAD_ASSEMBLY.out.assembly
        .mix( UNZIP_ASSEMBLY.out.assembly )
        .set { assemblies }

    // Convert to two bit
    FASTA_TO_TWOBIT (
        assemblies
    )

    emit:
    twobit      = FASTA_TO_TWOBIT.out.twobit
    chrom_sizes = FASTA_TO_TWOBIT.out.chrom_sizes

}
