include { DOWNLOAD_ASSEMBLY } from '../../../modules/local/ncbi-datasets-cli/main'
include { UNZIP_ASSEMBLY    } from '../../../modules/local/unzip/main'

workflow PREPARE_FASTAS {

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
        }.set { input }

    // Get assemblies provided as accessions
    DOWNLOAD_ASSEMBLY (
        input.accession
    )

    // Prepare assemblies provided as local FASTA files
    UNZIP_ASSEMBLY (
        input.fasta
    )

    // Mix assemblies
    DOWNLOAD_ASSEMBLY.out.assembly
        .mix( UNZIP_ASSEMBLY.out.assembly )
        .set { assemblies }

    emit:
    assemblies = assemblies

}
