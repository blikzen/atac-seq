#!/bin/bash
#usage ./script.sh <genome directory> <reads location> <optional: location for swap - has to be local to VM, not a shared / networked directory>
#e.g., if you had one top level directory with everything, you could simply ./script.sh . . . or ./script.sh . .
export export1=$1
threads=$(( $(grep -c ^processor /proc/cpuinfo) * 2 ))
#assuming this is a fresh install, downloads appropriate software, sets swap and indexes genome
#will create 32Gb swap for genome indexing
if [ ! -a "$1"/GenomeIndex ]; then
	sudo sh -c 'echo "deb https://cran.cnr.berkeley.edu/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list'
	sudo apt-get update && sudo apt-get dist-upgrade -y
	sudo apt-get install build-essential git zlib1g-dev libcairo2-dev libxt-dev libx11-dev libncurses5-dev libcurl3 php5-curl r-base-dev bedtools samtools python-numpy cython default-jre ant --force-yes
	cd homer
	unzip homer.v4.8.zip
	perl configureHomer.pl -install
	export PATH=$PATH:"$PWD"/bin
	export homerpath="$PWD"/bin
	cd
	git clone https://github.com/taoliu/MACS
	cd MACS
	sudo python setup_w_cython.py install
	cd bin
	chmod +x *
	sudo cp * /usr/bin
	cd
	git clone https://github.com/aboyle/F-seq
	cd F-seq
	ant
	cd dist~
	tar -xvf fseq.tgz
	cd fseq/bin
	chmod +x fseq
	export fseqpath="$PWD"/fseq
	cd
	wget http://snap.cs.berkeley.edu/downloads/snap-beta.18-linux.tar.gz
	tar -xvf snap-beta.18-linux.tar.gz
	chmod +x snap-aligner
	sudo cp snap-aligner /usr/bin
	cd "$3"
	dd if=/dev/zero of=swapper bs=1G count=32;
	sudo su
	mkswap swapper
	swapon swapper
	su ubuntu
	snap-aligner index "$1"/hg19.fa "$1" -hg19
fi
cd "$2"
#perform alignments
for f in *_1.fastq; do snap-aligner paired "$1" "$f" -t "$threads" -F s -o "$f".bam; done
#mappable non-chrM
find . -name "*.bam" | xargs -n 1 -P "$threads" -iFILES sh -c 'samtools view -B -F 4 FILES | egrep -v "chrM" | samtools view -bt "$export1"/hg19.fa.fai - > FILES.noM.bam' #&& rm -rf FILES\;';
#sort
find . -name "*.noM.bam" | xargs -n 1 -P "$threads" -iFILES sh -c 'samtools sort FILES FILES.sort' # && rm -rf FILES;';
#rmdup
find . -name "*.sort.bam" | xargs -n 1 -P "$threads" -iFILES sh -c 'samtools rmdup FILES FILES.rm.bam' # && rm -rf FILES;';
#convert to bed
find . -name "*.rm.bam" | xargs -n 1 -P "$threads" -iFILES sh -c 'bedtools bamtobed -i FILES > FILES.bed' # && rm -rf FILES;';
#call nuclease accessible areas w/ fseq
find . -name "*.bam.bed" | xargs -n 1 -P "$threads" -iFILES sh -c 'f=FILES; mkdir "$f"_tmp; $fseqpath -of npf -f 0 -o "$f"_tmp "$f" && cat "$f"_tmp/* >> "$f".npf && rm -rf "$f"_tmp;'
find . -name "*.npf*" | xargs -n 1 -P "$threads" -iFILES sh -c 'sort -k7,7nr FILES | head -100000 > FILES.top;'
#homer calls
find . -name "*.bam.bed" | xargs -n 1 -P "$threads" -iFILES sh -c 'f=FILES; makeTagDirectory "$f"_tmp/ $f; findPeaks "$f"_tmp/ -o $f.homer -localSize 50000 -size 150 -minDist 50 -fragLength 0; perl $homerpath/pos2bed.pl -o "$f".homer.bed "$f".homer;'
#macs2 calls
find . -name "*.bam.bed" | xargs -n 1 -P "$threads" -iFILES sh -c 'macs2 callpeak -t FILES -f BED -g hs -n my --nomodel --shift 75 -n FILES;';
#remove blacklisted intervals
find . -name "*.narrowPeak" | xargs -n 1 -P "$threads" -iFILES sh -c 'bedtools intersect -v -a FILES -b "$export1"/consensusBlacklist.bed > FILES.final.bed;';
find . -name "*.top*" | xargs -n 1 -P "$threads" -iFILES sh -c 'bedtools intersect -v -a FILES -b "$export1"/consensusBlacklist.bed > FILES.final.bed;';
find . -name "*.homer.bed" | xargs -n 1 -P "$threads" -iFILES sh -c 'bedtools intersect -v -a FILES -b "$export1"/consensusBlacklist.bed > FILES.final.bed;';
#variety of infographics
Rscript analysis.R
exit 0
