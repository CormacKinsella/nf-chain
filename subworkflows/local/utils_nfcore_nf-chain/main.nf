// Initialise the nbisweden/grave pipeline
include { UTILS_NEXTFLOW_PIPELINE   } from '../../nf-core/utils_nextflow_pipeline'
include { UTILS_NFSCHEMA_PLUGIN     } from '../../nf-core/utils_nfschema_plugin'
include { paramsSummaryMap          } from 'plugin/nf-schema'
include { samplesheetToList         } from 'plugin/nf-schema'
include { paramsHelp                } from 'plugin/nf-schema'

workflow PIPELINE_INITIALISATION {

    take:
    version           // boolean: Display version and exit
    validate_params   // boolean: Boolean whether to validate parameters against the schema at runtime
    monochrome_logs   // boolean: Do not use coloured log outputs
    nextflow_cli_args //   array: List of positional nextflow CLI args
    outdir            //  string: The output directory where the results will be saved
    input             //  string: Path to input samplesheet
    help              // boolean: Display help message and exit
    help_full         // boolean: Show the full help message
    show_hidden       // boolean: Show hidden parameters in the help message

    main:
    // Print version and exit if requested. Print pipeline parameters to JSON file.
    UTILS_NEXTFLOW_PIPELINE (
        version,
        true,
        outdir,
        workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1
    )

    // Validate parameters and generate help message to stdout

    // ~~~ DO NOT EDIT WHITESPACE BELOW ~~~
    before_text = """
    \033[0;92mcormackinsella/nf-chain ${workflow.manifest.version}\033[0m

    """
    after_text = """
    Log issues and questions at: \033[0;92m${workflow.manifest.homePage}/issues\033[0m
    """
    command = "pixi run nextflow main.nf -profile apptainer,test -params-file tests/params.yml"
    // ~~~ END OF FIXED WHITESPACE ~~~

    UTILS_NFSCHEMA_PLUGIN (
        workflow,
        validate_params,
        null,
        help,
        help_full,
        show_hidden,
        before_text,
        after_text,
        command
    )

    // Custom validation for pipeline parameters (see function below)
    validateInputParameters()

    // Create channel from input samplesheet provided with params.input
    ch_samplesheet = channel.empty()

    if ( params.input ) {
        def uniqueRoles = new HashSet<String>() // Initialise empty set for detecting duplicate roles
        ch_samplesheet = channel.fromPath(params.input, checkIfExists: true)
            .splitCsv(header: true, skip: 0)
            .map { row ->
                // Populate metadata
                def meta = [
                    id: row.sample_name,
                    role: row.file_role.toLowerCase(),
                    type: row.identifier_type.toLowerCase(),
                    identifier: row.identifier
                ]
                // Check that the roles assigned are valid
                if (!['target', 'source'].contains(meta.role)) {
                    error ("ERROR: Samplesheet has an invalid file role: '${meta.role}'. Please only supply 'target, 'source' (not case sensitive).")
                }
                // Check for duplicate roles
                def key = "${meta.role}"
                if (!uniqueRoles.add(key)) {
                    error ("Error: there cannot be be more than one target or source assembly. Found a duplicate entry for file role: '${meta.role}' in the samplesheet.")
                }
                // Check that the identifier types are valid
                if (!['accession', 'fasta'].contains(meta.type)) {
                    error ("ERROR: Samplesheet has an invalid identifier type: '${meta.type}'. Please only supply 'accession' or 'fasta' (not case sensitive).")
                }
                return meta
            }
    }

    emit:
    samplesheet = ch_samplesheet

}

// Define pipeline parameter validation function
def validateInputParameters() {

    // Define valid workflow steps
    def permitted_steps = [
        'prepare_inputs',
        'align_assemblies',
        'generate_chains'
    ]

    // Parse requested steps, check, and report if requested steps are valid
    def requested_steps = params.steps.tokenize(",")
    def invalid_steps = requested_steps.findAll { step -> !(step in permitted_steps) }
    if ( invalid_steps ) {
        error "ERROR: Unrecognised workflow step(s) provided:\n - Permitted steps are: ${permitted_steps}\n - Invalid step(s): ${invalid_steps.join(', ')}"
    }

    // Define step dependencies
    def step_dependencies = [
        'prepare_inputs': [],
        'align_assemblies': ['prepare_inputs'],
        'generate_chains': ['prepare_inputs', 'align_assemblies']
    ]

    // Check and report if step dependencies are met
    def missing_dependencies = []
    requested_steps.each { step ->
        def required_deps = step_dependencies[step]
        def missing = required_deps.findAll { dep -> !(dep in requested_steps) }
        if ( missing ) {
            missing_dependencies << "Step '${step}' is missing required dependencies: ${missing.join(', ')}"
        }
    }
    if ( missing_dependencies ) {
        error "ERROR: An invalid combination of steps was requested.\n - You requested steps: ${requested_steps.join(', ')}\n - ${missing_dependencies.join('\n  - ')}\n"
    }

    // Enforce input for prepare_inputs step if requested
    if ( 'prepare_inputs' in requested_steps && !params.input ) {
        error "ERROR: Input preparation was requested but no input samplesheet was provided with '--input'"
    }
    // Enforce aligner choice for align_assemblies step if requested
    if ( 'align_assemblies' in requested_steps && !params.aligner ) {
        error "ERROR: Alignment was requested but no aligner was specified with '--aligner'"
    }
}
