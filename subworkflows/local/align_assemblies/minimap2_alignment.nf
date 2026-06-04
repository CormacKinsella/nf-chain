include { MINIMAP2_INDEX } from '../../../modules/nf-core/minimap2/index/main'
include { MINIMAP2_ALIGN } from '../../../modules/local/minimap2/align/main'

workflow MINIMAP2_ALIGNMENT {

    take:
    source_assembly
    target_assembly

    main:
    // Index the source assembly
    MINIMAP2_INDEX (
        source_assembly
    )
    // Combine and eliminate self to self
    MINIMAP2_INDEX.out.index
        .combine( target_assembly )
        .filter { source_meta, _source_mmi, target_meta, _target_fa ->
            def retained = source_meta.id != target_meta.id // Exclude self-to-self
            if ( !retained ) {
                log.warn "Excluding self-to-self alignment for ${source_meta.id} to ${target_meta.id}"
            }
            return retained
        }
        .map { source_meta, source_mmi, target_meta, target_fa ->
            def meta_new = source_meta + [ lift: "${source_meta.id}_to_${target_meta.id}" ]
            [ meta_new, source_mmi, target_fa ]
        }
        .set { minimap2_input }
    // Align
    MINIMAP2_ALIGN (
        minimap2_input
    )

    emit:
    paf = MINIMAP2_ALIGN.out.paf

}
