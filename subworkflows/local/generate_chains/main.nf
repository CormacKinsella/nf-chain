include { FASTA_TO_TWOBIT } from '../../../modules/local/ucsc/twobit/main'
include { PSL_TO_CHAIN    } from './psl_to_chain'
include { PAF_TO_CHAIN    } from './paf_to_chain'

workflow GENERATE_CHAINS {

    take:
    assemblies
    samplesheet
    aligner
    run_chain_anti_repeat
    psl
    paf

    main:
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

    // Aligner specific workflows
    if ( aligner == 'blat' ) {
        PSL_TO_CHAIN (
            psl,
            twobit_source_modified,
            twobit_target_modified,
            run_chain_anti_repeat,
            aligner
        )
        chain = PSL_TO_CHAIN.out.chain
        stats = PSL_TO_CHAIN.out.stats
    } else if ( aligner == 'minimap2' ) {
        PAF_TO_CHAIN (
            paf,
            twobit_source_modified,
            twobit_target_modified,
            run_chain_anti_repeat,
            aligner
        )
        chain = PAF_TO_CHAIN.out.chain
        stats = PAF_TO_CHAIN.out.stats
    }

    emit:
    chain = chain
    stats = stats

}
