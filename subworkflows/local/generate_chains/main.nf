include { FASTA_TO_TWOBIT } from '../../../modules/local/ucsc/twobit/main'
include { AXTCHAIN        } from '../../../modules/local/ucsc/axtchain/main'

workflow GENERATE_CHAINS {

    take:
    fasta
    aligner
    blat_psl

    main:
    // Generate 2bit files if required
    if ( aligner in ['blat'] ) {
        FASTA_TO_TWOBIT (
            fasta
        )
        twobit_out  = FASTA_TO_TWOBIT.out.twobit
        chrom_sizes = FASTA_TO_TWOBIT.out.chrom_sizes
        // Branch source and reference two bit files into separate channels
        twobit_out
            .branch { meta, assembly ->
                source: meta.role == 'source'
                    return tuple( meta, assembly )
                target: meta.role == 'target'
                    return tuple( meta, assembly )  
            }.set { twobit_in }
    }

    // Chaining workflow

        if ( aligner in ['blat'] ) {
            AXTCHAIN (
                blat_psl,
                twobit_in.source.collect(),
                twobit_in.target.collect()
            )
        }

    //emit:

}