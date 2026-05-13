include { BLAT } from '../../../modules/nf-core/blat/main'

workflow ALIGN_ASSEMBLIES {

    take:
    twobit
    aligner

    main:

    // Separate query from target assemblies
    twobit
        .branch { meta, assembly ->
            query: meta.role == 'source'
                return tuple( meta, assembly )
            reference: meta.role == 'target'
                return tuple( meta, assembly )  
        }.set { align_input }


        if ( aligner == "blat" ) {
            BLAT (
                align_input.query,
                align_input.reference
            )
        } // else if ( aligner == "lastz" ) {
            //LASTZ (
            //    twobit
            //)
        //}


}
