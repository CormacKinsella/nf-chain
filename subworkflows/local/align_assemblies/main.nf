include { SPLIT_FASTA as SPLIT_REFERENCE } from '../../../modules/local/ucsc/fasplit/main'
include { SEQKIT_SPLIT2                  } from '../../../modules/nf-core/seqkit/split2/main'
include { COMPUTE_SIZES                  } from '../../../modules/local/ucsc/fasize/main'
include { SPLIT_FASTA as PROCESS_QUERY   } from '../../../modules/local/ucsc/fasplit/main'
include { KMERS_TO_EXCLUDE               } from '../../../modules/local/ucsc/exclude_kmers/main'
include { BLAT                           } from '../../../modules/local/ucsc/blat/main'

// TODO: minimap2
// TODO: lastz

workflow ALIGN_ASSEMBLIES {

    take:
    fasta_assemblies
    aligner
    chunk_size
    extra
    aggregate_chunk_size
    exclude_frequent_kmers

    main:
    // BLAT
    if ( aligner in ['blat'] ) {
        // Branch source and reference FASTA files into separate channels
        fasta_assemblies
            .branch { meta, assembly ->
                query: meta.role == 'source'
                    return tuple( meta, assembly )
                reference: meta.role == 'target'
                    return tuple( meta, assembly )
            }.set { whole_genome }

        // Chunk reference into 5kb segments and get lift file
        SPLIT_REFERENCE (
            whole_genome.reference,
            chunk_size
        )

        // Aggregate 5kb reference chunks into subsets of total size "aggregate_chunk_size"
        def subsets = Math.floor(aggregate_chunk_size / (chunk_size + extra)) as Integer
        SEQKIT_SPLIT2 (
            SPLIT_REFERENCE.out.fasplit_assembly,
            subsets
        )

        // Get size of longest query sequence & real base count of whole genome
        COMPUTE_SIZES (
            whole_genome.query
        )

        // TODO:
        PROCESS_QUERY (
            whole_genome.query,
            COMPUTE_SIZES.out.max_size.map { _meta, size -> size } // Set to largest contig, therefore will not split the genome
        )

        // Compute over-used 11-mers in the query (https://genomewiki.ucsc.edu/index.php/DoSameSpeciesLiftOver.pl)
        ooc11 = channel.of( [ [], [] ] ).collect()
        if ( exclude_frequent_kmers ) {
            repMatch = COMPUTE_SIZES.out.real_size.map { _meta, size ->
                def raw     = Math.floor(1024 * (size as Long / 2861349177)) as Integer
                def rounded = Math.floor(raw / 50) * 50 as Integer
                rounded == 0 ? raw : rounded
            }
            KMERS_TO_EXCLUDE (
                whole_genome.query,
                repMatch
            )
            ooc11 = KMERS_TO_EXCLUDE.out.ooc11.collect()
        }

        // BLAT
        blat_input = PROCESS_QUERY.out.fasplit_assembly
            .combine(SEQKIT_SPLIT2.out.aggregated_chunks.transpose() )
        BLAT (
            blat_input,
            ooc11
        )


//SEQKIT_SPLIT2.out.aggregated_chunks.transpose().view()
//        SEQKIT_SPLIT2.out.aggregated_chunks.view()
        // Align query to reference chunks with BLAT
        // BLAT (
        //     PROCESS_QUERY.out.fasplit_assembly
        // )


    }







    //         if ( aligner == "blat" ) {
    //             BLAT (
    //                 align_input.query,
    //                 align_input.reference
    //             )
    //         } // else if ( aligner == "lastz" ) {
    //             //LASTZ (
    //             //    twobit
    //             //)
    //         //}

    //emit:

}
