include { DOWNLOAD_ASSEMBLY } from '../../../modules/local/ncbi-datasets-cli/main'
include { UNZIP_ASSEMBLY    } from '../../../modules/local/unzip/main'

workflow PREPARE_FASTAS {

    take:
    samplesheet

    main:
    // Flatten to unique assemblies & branch on the identifier
    samplesheet
        .flatMap { entry -> [entry.source, entry.target] }
        .unique { meta -> "${meta.identifier}_${meta.role}" } // 'meta.identifier' is source of truth for uniqueness, but get duplicate if assembly serves both roles at least once (self -> self will not be run however)
        .set { unique_identifiers }

    // Branch on identifier type
    unique_identifiers
        .branch { meta ->
            accession: meta.type == 'accession'
                return meta
            fasta: meta.type == 'fasta'
                return [ meta, file(meta.identifier, checkIfExists: true) ]
        }.set { input }

    // Get assemblies provided as accessions
    DOWNLOAD_ASSEMBLY (
        input.accession
    )

    // Prepare assemblies provided as local FASTA files (runs locally, handles both uncompressed and gzipped)
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
