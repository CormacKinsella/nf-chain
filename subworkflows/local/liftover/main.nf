include { UCSC_LIFTOVER as LIFTOVER_BED        } from '../../../modules/nf-core/ucsc/liftover/main'
include { UCSC_LIFTOVER as LIFTOVER_GFF_OR_GTF } from '../../../modules/nf-core/ucsc/liftover/main'

workflow LIFTOVER {

    take:
    chain
    liftover

    main:
    // Combine the chain and liftover files by their lift metadata
    chain
        .map { meta, chain_file ->
            [ meta.lift, meta, chain_file ]
        }
        .combine( liftover
            .map { meta, liftover_file ->
                [ meta.lift, meta, liftover_file ]
            },
            by: 0
        )
        .map { _key, meta_chain, chain_file, meta_lift, liftover_file ->
            [ meta_chain, chain_file, liftover_file, meta_lift.format ]
        }
        .branch { meta, chain_file, liftover_file, format ->
            bed: format == 'bed'
                [ meta, chain_file, liftover_file ]
            gff_or_gtf: format in ['gff', 'gtf']
                [ meta, chain_file, liftover_file ]
        }
        .set { liftover_input }

    // Perform liftovers
    LIFTOVER_BED (
        liftover_input.bed
    )
    LIFTOVER_GFF_OR_GTF (
        liftover_input.gff_or_gtf
    )

    // Mix outputs
    LIFTOVER_BED.out.lifted
        .mix( LIFTOVER_GFF_OR_GTF.out.lifted )
        .set { lifted }
    LIFTOVER_BED.out.unlifted
        .mix( LIFTOVER_GFF_OR_GTF.out.unlifted )
        .set { unlifted }

    emit:
    lifted   = lifted
    unlifted = unlifted

}
