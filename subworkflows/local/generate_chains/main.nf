include { FASTA_TO_TWOBIT } from '../../../modules/local/ucsc/twobit/main'
include { AXTCHAIN        } from '../../../modules/local/ucsc/axtchain/main'
include { MERGE_CHAINS    } from '../../../modules/local/ucsc/chainmerge/main'
include { NET_CHAIN       } from '../../../modules/local/ucsc/netchain/main'
include { CHAIN_STATS     } from '../../../modules/local/chain_stats/main'

workflow GENERATE_CHAINS {

    take:
    assemblies
    samplesheet
    aligner
    blat_psl

    main:
    // Chain generation workflow
    if ( aligner in ['blat'] ) {
        // Generate twobit files
        FASTA_TO_TWOBIT (
            assemblies
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

        // Ensure twobit meta objects are updated with the lift task
        samplesheet
            .map { entry -> [ entry.source.id, entry.lift ] }
            .combine(
                twobit.source.map { meta, source_twobit, chrom_sizes -> [ meta.id, meta, source_twobit, chrom_sizes ] },
                by: 0
            )
            .map { _key, lift, source_meta, source_twobit, chrom_sizes ->
                [ source_meta + [lift: lift], source_twobit, chrom_sizes ]
            }
            .set { twobit_source_modified }
        samplesheet
            .map { entry -> [ entry.target.id, entry.lift ] }
            .combine(
                twobit.target.map { meta, target_twobit, chrom_sizes -> [ meta.id, meta, target_twobit, chrom_sizes ] },
                by: 0
            )
            .map { _key, lift, target_meta, target_twobit, chrom_sizes ->
                [ target_meta + [lift: lift], target_twobit, chrom_sizes ]
            }
            .set { twobit_target_modified }

        // Combine BLAT psl with twobit files (we lose self to self pairs here, due to upstream 'align_assemblies' filter)
        blat_psl
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

        // Combine merged chains with source chrom sizes
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
            netchain_in
        )

        // Generate chain stats
        CHAIN_STATS (
            NET_CHAIN.out.chain_stats_in
        )

    }

    emit:
    chain = NET_CHAIN.out.final_chain
    stats = CHAIN_STATS.out.chain_stats

}
