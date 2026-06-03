include { PAF2CHAIN   } from '../../../modules/local/paf2chain/main'
include { CHAIN_STATS } from '../../../modules/local/chain_stats/main'

workflow PAF_TO_CHAIN {

    take:
    paf
    twobit_source_modified
    twobit_target_modified
    aligner

    main:
    // Generate chain
    PAF2CHAIN (
        paf,
        aligner
    )
    // Generate input for chain stats
    PAF2CHAIN.out.chain
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
        .set { chain_stats_in }
    // Chain stats
    CHAIN_STATS (
        chain_stats_in
    )

    chain = PAF2CHAIN.out.chain
    stats = CHAIN_STATS.out.chain_stats

    emit:
    chain = chain
    stats = stats

}
