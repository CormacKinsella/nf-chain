include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_nf-chain/main'
include { PREPARE_FASTAS          } from './subworkflows/local/prepare_fastas/main'
include { ALIGN_ASSEMBLIES        } from './subworkflows/local/align_assemblies/main'
include { GENERATE_CHAINS         } from './subworkflows/local/generate_chains/main'

workflow {

    main:
    PIPELINE_INITIALISATION (
        params.version,         // boolean: Display version and exit
        params.validate_params, // boolean: Boolean whether to validate parameters against the schema at runtime
        params.monochrome_logs, // boolean: Do not use coloured log outputs
        args,                   //   array: List of positional nextflow CLI args
        params.outdir,          //  string: The output directory where the results will be saved
        params.input,           //  string: Path to input samplesheet
        params.help,            // boolean: Display help message and exit
        params.help_full,       // boolean: Show the full help message
        params.show_hidden      // boolean: Show hidden parameters in the help message
    )
    samplesheet = PIPELINE_INITIALISATION.out.samplesheet

    // Parse requested workflow steps
    workflow_steps = params.steps.tokenize(",")

    // Prepare assemblies
    if ( 'prepare_inputs' in workflow_steps) {
        // Take either accessions or local paths (including .gz) and output uncompressed FASTA
         PREPARE_FASTAS (
            samplesheet
        )
        assemblies = PREPARE_FASTAS.out.assemblies
    }

    // Align assemblies
    if ( 'align_assemblies' in workflow_steps) {
        ALIGN_ASSEMBLIES (
            assemblies,
            params.aligner,
            params.chunk_size,
            params.extra,
            params.aggregate_chunk_size,
            params.exclude_frequent_kmers
        )
        blat_psl = ALIGN_ASSEMBLIES.out.blat_psl
    }

    // Generate chains
    chain = channel.of( [ [], ['Not requested'] ] )
    stats = channel.of( [ [], ['Not requested'] ] )

    if ( 'generate_chains' in workflow_steps) {
        GENERATE_CHAINS (
            assemblies,
            params.aligner,
            blat_psl
        )
        chain = GENERATE_CHAINS.out.chain
        stats = GENERATE_CHAINS.out.stats
    }

    // Perform liftovers
    // if ( 'liftover' in workflow_steps) {
    //     // 'chain' will be the publishing placeholder unless 'generate_chains' ran: in this case overwrite with user input
    //     if ( !('generate_chains' in workflow_steps) ) {
    //         // PREPARE INPUT CHAIN FROM INPUT
    //         chain = channel.fromPath( params.chain_file, checkIfExists: true )
    //     }
    //     // TODO Develop liftover
    //     LIFTOVER (
    //         chain
    //     )
    // }

    // Report package versions
    channel.topic('versions')
        .map { process, tool, version ->
            return [process: process, tool: tool, version: version]
        }
        .unique()
        .collect()
        .map { it -> it.join('\n') }
        .collectFile(name: "${params.trace_timestamp}_package_versions.txt", newLine: true)
        .set { versions }

    // Define publish targets
    publish:
    versions                   = versions
    chains                     = chain.map { _meta, path -> [ path ] }
    stats                      = stats.map { _meta, path -> [ path ] }

}

// Publish outputs
output {
    // Version reporting
    versions {
        path '01_pipeline_info/package_versions'
    }
    // Chain files
    chains {
        path '02_chains'
    }
    // Chain stats
    stats {
        path '03_chain_stats'
    }
}
