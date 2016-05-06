# atac-seq
Implementation of ENCODE's ATACseq pipeline with visualization of data using R's ChIPseeker package.

Performs alignments with SNAP against hg19 and calls open regions and peaks. 

If the snap index isn't found, then the script assumes that the environment is fresh, and deploys all needed software for the analysis.

Please note that the sample reads, nor the assembly or blacklist BED file are not supplied and need to be injected into the environment on your end.
