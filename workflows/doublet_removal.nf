nextflow.preview.dsl=2

//////////////////////////////////////////////////////
//  Import sub-workflows from the modules:
include SC__SCRUBLET__DOUBLET_DETECTION from "../processes/doublet_detection" params(params)
include SC__SCRUBLET__DOUBLET_DETECTION_REPORT from "../processes/reports" params(params)

//////////////////////////////////////////////////////
//  Import from external modules:
include ANNOTATE_BY_CELL_METADATA from '../../utils/workflows/annotateByCellMetadata.nf' params(params)
include FILTER_BY_CELL_METADATA from '../../utils/workflows/filterByCellMetadata' params(params)
include UTILS__REPORT_TO_HTML from '../../utils/processes/reports.nf' params(params)
include SC__PUBLISH_H5AD from '../../utils/processes/utils.nf' params(params)

workflow DOUBLET_REMOVAL {

    take:
        // Expects (sampleId, adataRaw, adataWithHvgInfo, stashedParams || null, nPrinComps || null)
        data
        // Expects (sampleId, adataWithEmbeddings)
        finalProcessedData

    main:
        SC__SCRUBLET__DOUBLET_DETECTION(
            data
        )

        ANNOTATE_BY_CELL_METADATA(
            data.map {
                it -> tuple(it[0], it[1])
            },
            SC__SCRUBLET__DOUBLET_DETECTION.out.map {
                it -> tuple(it[0], it[1])
            },
            "scrublet"
        )

        FILTER_BY_CELL_METADATA(
            ANNOTATE_BY_CELL_METADATA.out,
            "scrublet"
        )
        SC__PUBLISH_H5AD(
            FILTER_BY_CELL_METADATA.out.map {
                it -> tuple(it[0], it[1], null)
            },
            params.global.project_name + '.Scrublet.doublets_removed'
        )

        SC__SCRUBLET__DOUBLET_DETECTION_REPORT(
            file(workflow.projectDir + params.sc.scrublet.doublet_detection.report_ipynb),
                SC__SCRUBLET__DOUBLET_DETECTION.out.map {
                // Extract the Scrublet object file
                it -> tuple(it[0], it[2])
            }.join(
                // Get the h5ad with Scrublet info
                ANNOTATE_BY_CELL_METADATA.out
            ).join(
                finalProcessedData
            )
        )
        UTILS__REPORT_TO_HTML(
            SC__SCRUBLET__DOUBLET_DETECTION_REPORT.out
        )

    emit:
        data_annotated = ANNOTATE_BY_CELL_METADATA.out
        data_doublets_removed = FILTER_BY_CELL_METADATA.out
        report = SC__SCRUBLET__DOUBLET_DETECTION_REPORT.out

}