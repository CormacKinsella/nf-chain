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
    chain             // Channel: Placeholder channel

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
    command = "pixi run nextflow main.nf -profile apptainer,test -params-file tests/params-chain-lift.yml"
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

    // Parse requested workflow steps
    workflow_steps = params.steps.tokenize(",")

    // Prepare liftover inputs
    liftover = channel.empty()
    if ( 'liftover' in workflow_steps) {
        // Parse the liftover input CSV
        channel.fromPath(params.liftover_input, checkIfExists: true)
            .splitCsv(header: true, skip: 0)
            .map { row ->
                def meta = [
                    lift: row.lift,
                    format: row.format.toLowerCase()
                ]
                // Check that the formats are accepted
                if (!['bed', 'gff', 'gtf'].contains(meta.format)) {
                    error ("ERROR: Liftover samplesheet has an invalid format type: '${meta.format}'. Please only supply 'bed', 'gff', or 'gtf' (not case sensitive).")
                }
                return [ meta, [file(row.input)] ]
            }
            .set { liftover }
        // If liftover but no 'generate_chains', get user input chain
        if ( !('generate_chains' in workflow_steps) ) {
            // Get the user provided chain file
            channel.fromPath( params.chain_file, checkIfExists: true )
                .map { path ->
                    def prefix = path.name.replaceAll(/\.(chain\.gz|chain)$/, '')
                    [ [ lift: prefix ], path ]
                }
                .set { chain }
            // Confirm that there is a valid mapping of lift keys
            def liftover_keys = liftover.map { meta, _inputs -> meta.lift }.unique().collect().map { keys -> [keys] }
            def chain_keys    = chain.map { meta, _path -> meta.lift }.unique().collect().map { keys -> [keys] }
            liftover_keys
                .combine( chain_keys )
                .subscribe { requested_key, valid_key ->
                    def invalid = requested_key - valid_key
                    if ( invalid ) {
                        error "ERROR:The requested liftover(s): '${invalid.join(', ')}' had no match to a chain file prefix. Found chain file prefix: '${valid_key.join(', ')}'"
                    }
                }
        }
    }

    // Create samplesheet channel if generating chains + if running generation alongside liftover, check inputs are valid
    ch_samplesheet = channel.empty()
    if ('prepare_inputs' in workflow_steps || 'generate_chains' in workflow_steps) {
        // Parse samplesheet into metadata, collect all entries, validate minimums, then re-emit
        channel.fromPath(params.input, checkIfExists: true)
            .splitCsv(header: true, skip: 0)
            .map { row ->
                def meta = [
                    id: row.sample_name,
                    role: row.file_role.toLowerCase(),
                    type: row.identifier_type.toLowerCase(),
                    identifier: row.identifier
                ]
                // Check that the roles assigned are valid
                if (!['target', 'source'].contains(meta.role)) {
                    error("ERROR: Samplesheet has an invalid file role: '${meta.role}'. Please only supply 'target' or 'source' (not case sensitive).")
                }
                // Check that the identifier types are valid
                if (!['accession', 'fasta'].contains(meta.type)) {
                    error("ERROR: Samplesheet has an invalid identifier type: '${meta.type}'. Please only supply 'accession' or 'fasta' (not case sensitive).")
                }
                return meta
            }
            .collect()
            .flatMap { entries ->
                // Validate at least one source and one target exist
                def targets = entries.findAll { it.role == 'target' }
                def sources = entries.findAll { it.role == 'source' }
                if (targets.size() == 0) {
                    error("ERROR: Samplesheet must contain at least one 'target' assembly. Found none.")
                }
                if (sources.size() == 0) {
                    error("ERROR: Samplesheet must contain at least one 'source' assembly. Found none.")
                }
                // Mode-based validation
                if (params.mode == 'many_to_one') {
                    if (targets.size() > 1) {
                        error("ERROR: In '${params.mode}' mode there can only be one target assembly. Found ${targets.size()}.")
                    }
                    def sourceDupes = sources.collect { it.id }.groupBy { it }.findAll { k, v -> v.size() > 1 }.keySet()
                    if (sourceDupes) {
                        error("ERROR: In '${params.mode}' mode there should not be duplicate source assemblies. Found duplicates: '${sourceDupes.join(', ')}'.")
                    }
                } else if (params.mode == 'one_to_many') {
                    if (sources.size() > 1) {
                        error("ERROR: In '${params.mode}' mode there can only be one source assembly. Found ${sources.size()}.")
                    }
                    def targetDupes = targets.collect { it.id }.groupBy { it }.findAll { k, v -> v.size() > 1 }.keySet()
                    if (targetDupes) {
                        error("ERROR: In '${params.mode}' mode there should not be duplicate target assemblies. Found duplicates: '${targetDupes.join(', ')}'.")
                    }
                } // else 'many_to_many': no validation
                // Compute source × target cross-product and emit one entry per lift
                def lifts = []
                sources.each { source_meta ->
                    targets.each { target_meta ->
                        lifts << [
                            lift:   "${source_meta.id}_to_${target_meta.id}",
                            source: source_meta,
                            target: target_meta
                        ]
                    }
                }
                return lifts
            }
            .set { ch_samplesheet }

        // If running liftover, validate that requested lift keys match what we'll generate
        if ('liftover' in workflow_steps) {
            def valid_lift_keys = ch_samplesheet
                .map { meta -> meta.lift }
                .unique()
                .collect()
                .map { keys -> [keys] }
            def liftover_keys = liftover
                .map { meta, _inputs -> meta.lift }
                .unique()
                .collect()
                .map { keys -> [keys] }
            liftover_keys
                .combine(valid_lift_keys)
                .subscribe { lift_key, valid_key ->
                    def invalid = lift_key - valid_key
                    if (invalid) {
                        error("ERROR: The requested liftover(s): '${invalid.join(', ')}' had no match to a valid chain file prefix. Chains that will be generated have the prefixes: ${valid_key.join(', ')}")
                    }
                }
        }
    }

    emit:
    liftover    = liftover
    chain       = chain
    samplesheet = ch_samplesheet

}

// Define pipeline parameter validation function
def validateInputParameters() {

    // Define valid workflow steps
    def permitted_steps = [
        'prepare_inputs',
        'align_assemblies',
        'generate_chains',
        'liftover'
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
        'generate_chains': ['align_assemblies'],
        'liftover': params.chain_file ? [] : ['generate_chains']
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
        def hints = []
        if ( 'liftover' in requested_steps && !params.chain_file ) {
            hints << "HINT: 'liftover' requires upstream chain generation unless a pre-computed chain file is provided via --chain_file"
        }
        def hint_text = hints ? "\n - ${hints.join('\n - ')}" : ""
        error "ERROR: An invalid combination of steps was requested.\n - You requested steps: ${requested_steps.join(', ')}\n - ${missing_dependencies.join('\n - ')}${hint_text}\n"
    }
    // Enforce input for prepare_inputs step if requested
    if ( 'prepare_inputs' in requested_steps && !params.input ) {
        error "ERROR: Input preparation was requested but no input samplesheet was provided with '--input'"
    }
    // Enforce aligner choice for align_assemblies step if requested
    if ( 'align_assemblies' in requested_steps && !params.aligner ) {
        error "ERROR: Alignment was requested but no aligner was specified with '--aligner'"
    }
    // If running liftover, enforce input
    if ( 'liftover' in requested_steps && !params.liftover_input ) {
        error "ERROR: Liftover was requested but no input was provided with '--liftover_input'"
    }
}
