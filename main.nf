
include { PIPELINE_INITIALISATION } from './subworkflows/local/utils_nfcore_nf-chain/main'
include { PREPARE_ASSEMBLIES      } from './subworkflows/local/prepare_assemblies/main'
include { ALIGN_ASSEMBLIES        } from './subworkflows/local/align_assemblies/main'

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
    if ( 'generate_chains' in workflow_steps) {

        PREPARE_ASSEMBLIES (
            samplesheet
        )

        ALIGN_ASSEMBLIES (
            PREPARE_ASSEMBLIES.out.twobit,
            params.aligner
        )

    }

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

}

// Publish outputs
output {
    // Version reporting
    versions {
        path '01_pipeline_info/package_versions'
    }

}
