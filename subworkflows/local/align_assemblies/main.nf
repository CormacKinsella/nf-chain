include { COMPUTE_SIZES                 } from '../../../modules/local/ucsc/fasize/main'
include { SPLIT_FASTA as PROCESS_SOURCE } from '../../../modules/local/ucsc/fasplit/main'
include { KMERS_TO_EXCLUDE              } from '../../../modules/local/ucsc/exclude_kmers/main'
include { SPLIT_FASTA as PROCESS_TARGET } from '../../../modules/local/ucsc/fasplit/main'
include { SEQKIT_SPLIT2 as SPLIT_TARGET } from '../../../modules/nf-core/seqkit/split2/main'
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
    // Initialise empty channels
    blat_psl = channel.empty()

    // Assembly processing when chunking is required (e.g., BLAT)
    if ( aligner in ['blat'] ) {
        // Branch source and target FASTA files into separate channels
        fasta
            .branch { meta, sequence ->
                source: meta.role == 'source'
                    [ meta, sequence ]
                target: meta.role == 'target'
                    [ meta, sequence ]
            }.set { assembly }

        // Prepare source assemblies
            // Gets the size of the longest source scaffold and the real (non-N) base count of the whole assembly
            COMPUTE_SIZES (
                assembly.source
            )
            // Processes each source assembly without splitting chromosomes and gets lift file
            PROCESS_SOURCE (
                assembly.source
                    .join( COMPUTE_SIZES.out.max_size ) // Split size set to max contig length = just generates lift without split
            )
            // Computes over-used 11-mers in each source (https://genomewiki.ucsc.edu/index.php/DoSameSpeciesLiftOver.pl)
            ooc11 = channel.of( [ [], [] ] ).collect()
            if ( exclude_frequent_kmers ) {
                KMERS_TO_EXCLUDE (
                    assembly.source
                        .join( COMPUTE_SIZES.out.real_size )
                        .map { meta, sequence, size ->
                            def raw     = Math.floor(1024 * (size as Long / 2861349177)) as Integer
                            def rounded = Math.floor(raw / 50) * 50 as Integer
                            rounded == 0 ? [ meta, sequence, raw ] : [ meta, sequence, rounded ]
                        }
                )
                ooc11 = KMERS_TO_EXCLUDE.out.ooc11
            }

        // Prepare the target assembly
            // Chunks target into 5kb segments and gets lift file
            PROCESS_TARGET (
                assembly.target
                    .map { meta, sequence ->
                        [ meta, sequence, chunk_size ]
                    }
            )
            // Aggregates 5kb target chunks into subsets of total size "aggregate_chunk_size"
            def seqs_per_subset = Math.floor(aggregate_chunk_size / (chunk_size + extra)) as Integer
            SPLIT_TARGET (
                PROCESS_TARGET.out.assembly,
                seqs_per_subset
            )

        // BLAT
            // Prepare source and target sides of the input
            PROCESS_SOURCE.out.assembly
                .join( PROCESS_SOURCE.out.lift )
                .join( ooc11 )
                .set { source_side }
            SPLIT_TARGET.out.aggregated_chunks
                .transpose()
                .combine(
                    PROCESS_TARGET.out.lift,
                    by: 0
                )
                .set { target_side }
            // Combine source and target
            source_side
                .combine( target_side )
                // TODO - uncomment this filter
                // .filter { source_meta, _source_fa, _source_lift, _ooc, target_meta, _target_chunk, _target_lift ->
                //     source_meta.id != target_meta.id  // Exclude self-to-self
                // }
                .map { source_meta, source_fa, source_lift, ooc, target_meta, target_chunk, target_lift ->
                    def source_meta2 = source_meta + [ lift: "${source_meta.id}_to_${target_meta.id}" ]
                    def target_meta2 = target_meta + [ lift: "${source_meta.id}_to_${target_meta.id}" ]
                    [ source_meta2, source_fa, source_lift, ooc, target_meta2, target_chunk, target_lift ]
                }
                .set { blat_input }

            // Align and run liftup
            BLAT (
                blat_input
            )
            blat_psl = BLAT.out.blat_psl
    }

    emit:
    blat_psl = blat_psl

}
