include { DOWNLOAD_ASSEMBLY } from '../../../modules/local/ncbi-datasets-cli/main'
include { UNZIP_ASSEMBLY    } from '../../../modules/local/unzip/main'

workflow PREPARE_FASTAS {

    take:
    samplesheet

    main:
    // Flatten to unique assemblies & branch on the identifier
    samplesheet
        .flatMap { entry -> [entry.source, entry.target] }
        .unique { meta -> meta.identifier } // 'meta.identifier' is the source of truth for uniqueness rather than sample name
        .set { unique_assemblies }

    // Branch on identifier type
    unique_assemblies
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

    // Prepare assemblies provided as local FASTA files (runs locally, handles both uncompressed and gzipped)
    UNZIP_ASSEMBLY (
        input.fasta
    )

    // TODO
    // After download completes, rejoin all assemblies back to samplesheet lifts by ID
    // e.g., downloaded_assemblies = DOWNLOAD_ACCESSION(input.accession)
    //        all_assemblies = downloaded_assemblies.mix(input.fasta)
    //
    // Then rejoin with the lift-level samplesheet:
    // ch_source_ready = samplesheet
    //     .map { entry -> [entry.source.id, entry] }
    //     .combine(all_assemblies.map { meta, fasta -> [meta.id, fasta] }, by: 0)
    //     .map { id, entry, fasta -> [entry, fasta] }


    // Mix assemblies
    DOWNLOAD_ASSEMBLY.out.assembly
        .mix( UNZIP_ASSEMBLY.out.assembly )
        .set { assemblies }

    emit:
    assemblies = assemblies

}
