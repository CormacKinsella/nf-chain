include { PAF2CHAIN    } from '../../../modules/local/paf2chain/main'
include { MERGE_CHAINS } from '../../../modules/local/ucsc/chainmerge/main'
include { NET_CHAIN    } from '../../../modules/local/ucsc/netchain/main'
include { CHAIN_STATS  } from '../../../modules/local/chain_stats/main'

workflow PAF_TO_CHAIN {

    take:
    paf
    twobit_source_modified
    twobit_target_modified
    run_chain_anti_repeat
    aligner

    main:
    // Combine paf with twobit files for chain scoring
    paf
        .map { meta, paf -> [ meta.lift, meta, paf ] }
        .combine(
            twobit_source_modified.map { meta, source_twobit, _chrom_sizes -> [ meta.lift, source_twobit ] },
            by: 0
        )
        .combine(
            twobit_target_modified.map { meta, target_twobit, _chrom_sizes -> [ meta.lift, target_twobit ] },
            by: 0
        )
        .map { _key, meta, paf, source_twobit, target_twobit ->
            [ meta, paf, source_twobit, target_twobit ]
        }
        .set { paf2chain_in }
    // Generate & score chain
    PAF2CHAIN (
        paf2chain_in
    )
    // For minimap2 chain, merge chains gets the input structure expected by NET_CHAIN
    if ( run_chain_anti_repeat ) {
        MERGE_CHAINS (
            PAF2CHAIN.out.antiRep
        )
    } else {
        MERGE_CHAINS (
            PAF2CHAIN.out.chain
        )
    }
    // Combine chain with source and target chrom sizes
    MERGE_CHAINS.out.merged_chain
        .map { meta, chain -> [ meta.lift, meta, chain ] }
        .combine(
            twobit_source_modified.map { meta, _source_twobit, chrom_sizes -> [ meta.lift, chrom_sizes ] },
            by: 0
        )
        .combine(
            twobit_target_modified.map { meta, _target_twobit, chrom_sizes -> [ meta.lift, chrom_sizes ] },
            by: 0
        )
        .map { _key, meta, chain, source_sizes, target_sizes ->
            [ meta, chain, source_sizes, target_sizes ]
        }
        .set { netchain_in }
    // Construct final liftover chain file
    NET_CHAIN (
        netchain_in,
        aligner
    )
    // Chain stats
    CHAIN_STATS (
        NET_CHAIN.out.chain_stats_in
    )

    chain = NET_CHAIN.out.final_chain
    stats = CHAIN_STATS.out.chain_stats

    emit:
    chain = chain
    stats = stats

}
