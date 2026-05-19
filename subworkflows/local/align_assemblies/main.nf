include { COMPUTE_SIZES                 } from '../../../modules/local/ucsc/fasize/main'
include { SPLIT_FASTA as PROCESS_SOURCE } from '../../../modules/local/ucsc/fasplit/main'
include { KMERS_TO_EXCLUDE              } from '../../../modules/local/ucsc/exclude_kmers/main'
include { SPLIT_FASTA as PROCESS_TARGET } from '../../../modules/local/ucsc/fasplit/main'
include { SEQKIT_SPLIT2                 } from '../../../modules/nf-core/seqkit/split2/main'
include { BLAT                          } from '../../../modules/local/ucsc/blat/main'

workflow ALIGN_ASSEMBLIES {

    take:
    fasta
    aligner
    chunk_size
    extra
    aggregate_chunk_size
    exclude_frequent_kmers

    main:
    // Assembly processing when chunking is required (e.g., BLAT)
    if ( aligner in ['blat'] ) {
        // Branch source and target FASTA files into separate channels
        fasta
            .branch { meta, assembly ->
                source: meta.role == 'source'
                    return tuple( meta, assembly )
                target: meta.role == 'target'
                    return tuple( meta, assembly )
            }.set { assembly }

        // Prepare source assembly
            // Gets the size of the longest source scaffold and the real (non-N) base count of the whole assembly
            COMPUTE_SIZES (
                assembly.source
            )
            // Processes the source assembly without splitting
            PROCESS_SOURCE (
                assembly.source,
                COMPUTE_SIZES.out.max_size.map { _meta, size -> size } // Val set to longest contig = genome not split
            )
            // Computes over-used 11-mers in the source (https://genomewiki.ucsc.edu/index.php/DoSameSpeciesLiftOver.pl)
            ooc11 = channel.of( [ [], [] ] ).collect()
            if ( exclude_frequent_kmers ) {
                repMatch = COMPUTE_SIZES.out.real_size.map { _meta, size ->
                    def raw     = Math.floor(1024 * (size as Long / 2861349177)) as Integer
                    def rounded = Math.floor(raw / 50) * 50 as Integer
                    rounded == 0 ? raw : rounded
                }
                KMERS_TO_EXCLUDE (
                    assembly.source,
                    repMatch
                )
                ooc11 = KMERS_TO_EXCLUDE.out.ooc11.collect()
            }

        // Prepare target assembly
            // Chunks target into 5kb segments, and gets lift file
            PROCESS_TARGET (
                assembly.target,
                chunk_size
            )
            // Aggregates 5kb target chunks into subsets of total size "aggregate_chunk_size"
            def seqs_per_subset = Math.floor(aggregate_chunk_size / (chunk_size + extra)) as Integer
            SEQKIT_SPLIT2 (
                PROCESS_TARGET.out.assembly,
                seqs_per_subset
            )

        // BLAT
            // Prepare BLAT input channel
            PROCESS_SOURCE.out.assembly
                .combine(
                    SEQKIT_SPLIT2.out.aggregated_chunks
                        .transpose()
                )
                .set { blat_input }
            // Align
            BLAT (
                blat_input,
                ooc11
            )

    }

    //emit:

}
