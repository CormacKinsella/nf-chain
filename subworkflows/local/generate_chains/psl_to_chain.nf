include { AXTCHAIN        } from '../../../modules/local/ucsc/axtchain/main'
include { MERGE_CHAINS    } from '../../../modules/local/ucsc/chainmerge/main'
include { NET_CHAIN       } from '../../../modules/local/ucsc/netchain/main'
include { CHAIN_STATS     } from '../../../modules/local/chain_stats/main'

workflow PSL_TO_CHAIN {

    take:
    psl
    twobit_source_modified
    twobit_target_modified
    aligner

    main:
    // Combine psl with twobit files (we lose self to self pairs here, due to upstream 'align_assemblies' filter)
    psl
        .map { meta, psl -> [ meta.lift, meta, psl ] }
        .combine(
            twobit_source_modified.map { meta, source_twobit, _chrom_sizes -> [ meta.lift, source_twobit ] },
            by: 0
        )
        .combine(
            twobit_target_modified.map { meta, target_twobit, _chrom_sizes -> [ meta.lift, target_twobit ] },
            by: 0
        )
        .map { _key, meta, psl, source_twobit, target_twobit ->
            [ meta, psl, source_twobit, target_twobit ]
        }
        .set { axtchain_in }
    // Convert from psl to chain & bridge chains
    AXTCHAIN (
        axtchain_in
    )
    // For each source/target pair, merge chains
    MERGE_CHAINS (
        AXTCHAIN.out.axtchain
            .groupTuple()
    )
    // Combine merged chains with source and target chrom sizes
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
