include { FASTA_TO_TWOBIT } from '../../../modules/local/ucsc/twobit/main'
include { AXTCHAIN        } from '../../../modules/local/ucsc/axtchain/main'
include { MERGE_CHAINS    } from '../../../modules/local/ucsc/chainmerge/main'
include { NET_CHAIN       } from '../../../modules/local/ucsc/netchain/main'

workflow GENERATE_CHAINS {

    take:
    fasta
    aligner
    blat_psl

    main:
    // Chain generation workflow
    if ( aligner in ['blat'] ) {
        // Generate twobit files
        FASTA_TO_TWOBIT (
            fasta
        )
        // Branch source and reference twobit outputs into separate channels
        FASTA_TO_TWOBIT.out.twobit
            .branch { meta, twobit, chrom_sizes ->
                source: meta.role == 'source'
                    [ meta, twobit, chrom_sizes ]
                target: meta.role == 'target'
                    [ meta, twobit, chrom_sizes ]
            }
            .set { twobit }
        // Ensure source twobit meta object is updated with the lift task for downstream joins (target doesn't require it as there is only one target)
        twobit.source
            .map { meta, twobit, chrom_sizes ->
                [ meta.id, meta, twobit, chrom_sizes ] // Add join key "meta.id"
            }
            .join( blat_psl.map { meta, psl -> [ meta.id, meta, psl ] } ) // Add join key "meta.id" and join
            .map { _key, _old_meta, twobit, chrom_sizes, meta, _psl ->
                [ meta, twobit, chrom_sizes ] // Replace the meta object and return
            }.set { twobit_source_modified }
    }

    // Prepare axtchain input for BLAT
    if ( aligner in ['blat'] ) {
        // Combine BLAT psl with source twobit file
        blat_psl
            .combine(
                twobit_source_modified.map { meta, twobit, chrom_sizes -> [ meta, twobit ] },
                by: 0
            )
            .set { axtchain_in }
    }

    // Chaining workflow
    if ( aligner in ['blat'] ) {
        // Convert from psl to chain & bridge chains
        AXTCHAIN (
            axtchain_in,
            twobit.target
                .map { meta, twobit, _chrom_sizes -> [ meta, twobit ] }
                .collect()
        )
        // For each source/target pair, merge chains
        MERGE_CHAINS (
            AXTCHAIN.out.axtchain
                .groupTuple()
        )
        // Combine merged chains with source chrom sizes
        MERGE_CHAINS.out.merged_chain
            .combine(
                twobit_source_modified.map { meta, _twobit, chrom_sizes -> [ meta, chrom_sizes ] },
                by: 0
            ).set { netchain_in }

        // Construct final liftover chain file
        NET_CHAIN (
            netchain_in,
            twobit.target
                .map { meta, _twobit, chrom_sizes -> [ meta, chrom_sizes ] }
                .collect()
        )
        NET_CHAIN.out.final_chain
            .set { chain }
    }

    emit:
    chain = chain

}
