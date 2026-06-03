include { BLAT_ALIGNMENT } from './blat_alignment'

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

    // BLAT specific tasks
    if ( aligner == 'blat' ) {
        BLAT_ALIGNMENT (
            fasta,
            chunk_size,
            extra,
            aggregate_chunk_size,
            exclude_frequent_kmers
        )
        blat_psl = BLAT_ALIGNMENT.out.blat_psl
    }

    emit:
    blat_psl = blat_psl

}
