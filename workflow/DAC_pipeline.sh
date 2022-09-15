
module load cutadapt
module load pear
module load bowtie
module load samtools
module load bedtools



path=$1
R1=$2
R2=$3
output=$4


## PART I ###########

## Trim adapters
cutadapt -j 32 -b file:TruSeq_and_nextera_adapters.fa -B file:TruSeq_and_nextera_adapters.fa --trim-n -m 50 -o ${output}_R1.trimmed.fastq.gz -p ${output}_R2.trimmed.fastq.gz ${path}/${R1} ${path}/${R2}

## Assemble read pairs ###########
pear -p 0.0001 -f ${output}_R1.trimmed.fastq.gz -r ${output}_R2.trimmed.fastq.gz -o ${output} -j 32

## Compress and delete unused files ###########
gzip -f ${output}.assembled.fastq
rm *discarded* *unassembled*

## Map and discard unnmaped ###########
bowtie2 -p 32 -x hg19 -U ${output}.assembled.fastq.gz -S ${output}.assembled.hg19.bam
samtools view -b -F 260 ${output}.assembled.hg19.bam > ${output}.mapped.hg19.bam
bedtools bamtobed -i ${output}.mapped.hg19.bam > ${output}.mapped.hg19.bed

## Make histogram of fragment lengths ###########
Rscript hist.r ${output}.mapped.hg19.bed ${output}.mapped.hg19.length_hist.csv


## OPTIONAL ###########
# bedtools -a ${output}.mapped.hg19.bed -b intervals_of_interests.bed > ${output}.selected.hg19.bed


## PART II ###########

limit=$5
max_dist=$6

## Find fragment centers (DYADs) and make histogram (Occurrences) ###########
python3 WeigthedDYADposition.py ${output}.selected.hg19.bed ${output}.DYADs
sort -k1,1 -k2n,2 ${output}.DYADs > ${output}.DYADs.sorted
python Uniq_Position.py ${output}.DYADs.sorted ${output}.DYADs.hist

## Compute auto-correlation ###########
python ALU_DAC.py ${output}.DYADs.hist ${limit} ${max_dist} ${output}.DAC.csv




