# atac-seq
Implementation of ENCODE's ATACseq pipeline including F-seq, HOMER, and MACS2 with visualization of data using R.

Usage: ./encode.atacseq.sh "genome directory" "reads location" "optional: location for swap"

Works fine with relative paths, so if you had only one bottom level directory with everything you need for analysis (i.e., raw reads, reference sequence), you could simply run ./script.sh . . . or ./script.sh . .

Performs alignments with SNAP against hg19 and calls open regions and peaks which are then checked against blacklist

If the snap index isn't found, then the script assumes that the environment is fresh, and deploys all needed software and swap for the analysis.

Please note raw reads, hg19 assembly, or blacklist BED file are not supplied with git repo, and need to be injected into the environment on your end.
