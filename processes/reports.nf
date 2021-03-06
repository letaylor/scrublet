nextflow.preview.dsl=2

process SC__SCRUBLET__DOUBLET_DETECTION_REPORT {

	container params.sc.scrublet.container
	clusterOptions "-l nodes=1:ppn=2 -l pmem=30gb -l walltime=1:00:00 -A ${params.global.qsubaccount}"
	publishDir "${params.global.outdir}/notebooks/intermediate", mode: 'link', overwrite: true
	maxForks 2

  	input:
		file(ipynb)
		tuple \
			val(sampleId), \
            file(scrubletObjectFile), \
			file(adataWithScrubletInfo), \
			file(adataWithDimRed)

  	output:
    	tuple \
			val(sampleId), \
			file("${sampleId}.SC_Scrublet_doublet_detection_report.ipynb")

  	script:
		"""
		papermill ${ipynb} \
		    --report-mode \
			${sampleId}.SC_Scrublet_doublet_detection_report.ipynb \
			-p SCRUBLET_OBJECT_FILE $scrubletObjectFile \
            -p H5AD_WITH_SCRUBLET_INFO $adataWithScrubletInfo \
            -p H5AD_WITH_DIM_RED $adataWithDimRed \
			-p WORKFLOW_MANIFEST '${params.misc.paramsAsJSON}' \
			-p WORKFLOW_PARAMETERS '${params.misc.paramsAsJSON}'
		"""

}