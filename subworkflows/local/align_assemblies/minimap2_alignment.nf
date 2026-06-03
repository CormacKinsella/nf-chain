include { MINIMAP2_INDEX } from '../../../modules/nf-core/minimap2/index/main'

workflow MINIMAP2_ALIGNMENT {

    take:
    source_assembly
    target_assembly

    main:
    // Index the source assembly
    MINIMAP2_INDEX (
        source_assembly
    )
    //emit:

}
