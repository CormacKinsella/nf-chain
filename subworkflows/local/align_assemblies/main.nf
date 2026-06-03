include { BLAT_ALIGNMENT     } from './blat_alignment'
include { MINIMAP2_ALIGNMENT } from './minimap2_alignment'

workflow ALIGN_ASSEMBLIES {

    take:
    aligner
    fasta
    chunk_size
    extra
    aggregate_chunk_size
    exclude_frequent_kmers

    main:
    // Initialise empty channels
    blat_psl = channel.empty()

    // Branch source and target FASTA files into separate channels
    fasta
        .branch { meta, sequence ->
            source: meta.role == 'source'
                [ meta, sequence ]
            target: meta.role == 'target'
                [ meta, sequence ]
        }.set { assembly }

    // Aligner specific workflows
    if ( aligner == 'blat' ) {
        BLAT_ALIGNMENT (
            assembly.source,
            assembly.target,
            chunk_size,
            extra,
            aggregate_chunk_size,
            exclude_frequent_kmers
        )
        blat_psl = BLAT_ALIGNMENT.out.blat_psl
    } else if ( aligner == 'minimap2' ) {
        MINIMAP2_ALIGNMENT (
            assembly.source,
            assembly.target
        )
    }

    emit:
    blat_psl = blat_psl

}
