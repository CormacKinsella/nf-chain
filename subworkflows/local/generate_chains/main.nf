include { FASTA_TO_TWOBIT } from '../../../modules/local/ucsc/twobit/main'

workflow GENERATE_CHAINS {

    take:
    raw_assemblies
    aligner

    main:
    // If the aligner requires it, generate 2bit files
    if ( aligner in ['blat'] ) {
        FASTA_TO_TWOBIT (
            raw_assemblies
        )
        twobit      = FASTA_TO_TWOBIT.out.twobit
        chrom_sizes = FASTA_TO_TWOBIT.out.chrom_sizes
        // Branch source and reference two bit files into separate channels
        twobit
            .branch { meta, assembly ->
                query: meta.role == 'source'
                    return tuple( meta, assembly )
                reference: meta.role == 'target'
                    return tuple( meta, assembly )  
            }.set { two_bit_input }
    }

    //emit:

}