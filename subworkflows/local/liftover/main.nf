include { UCSC_LIFTOVER } from '../../../modules/nf-core/ucsc/liftover/main'

workflow LIFTOVER {

    take:
    liftover_source
    chain

    main:
    // Perform liftovers
    UCSC_LIFTOVER (
        liftover_source,
        chain
    )

    //emit:

}
