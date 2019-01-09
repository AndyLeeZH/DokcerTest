echo Enter project name
read project
echo Enter reference name
read reference
echo Enter sample name
read filename
echo Enter reference length
read length
echo -------------------
echo Run SeqPrep
echo -------------------
/home/nextgen/tools/SeqPrep/SeqPrep -f /home/nextgen/$project/$filename\_S1_L001_R1_001.fastq.gz -r /home/nextgen/$project/$filename\_S1_L001_R2_001.fastq.gz -S -1 /home/nextgen/$project/R1_trim.fq.gz -2 /home/nextgen/$project/R2_trim.fq.gz
echo -------------------
echo Run Trimmomatic
echo -------------------
java -jar /home/nextgen/tools/Trimmomatic-0.38/trimmomatic-0.38.jar PE -threads 8 -phred33 R1_trim.fq.gz R2_trim.fq.gz R1_p.fq.gz R1_up.fq.gz R2_p.fq.gz R2_up.fq.gz CROP:149 LEADING:20 TRAILING:20 SLIDINGWINDOW:1:20 MINLEN:25
echo -------------------
echo Run Bowtie2
echo -------------------
bowtie2 -x $reference -1 R1_p.fq.gz -2 R2_p.fq.gz -S align.sam -X 1000 --threads 8 --very-sensitive --no-discordant
samtools view align.sam -o align.bam
samtools sort align.bam -o align_sort.bam
samtools index align_sort.bam
samtools sort align.bam -n -o align_nsort.bam
echo -------------------
echo Run mpileup
echo -------------------
bcftools mpileup -Ou -f $reference.fa align_sort.bam -d 50000 | bcftools call -m -Ob -o calls.bcf
tabix calls.bcf
cat $reference.fa | bcftools consensus calls.bcf > consensus.fa
echo -------------------
echo Map unmapped reads against E. coli, human, PhiX
echo -------------------
samtools view -bh -f 4 -F 8 align.bam > um.bam
samtools view -bh -F 4 -f 8 align.bam > mu.bam
samtools view -bh -f 4 -f 8 align.bam > uu.bam
samtools merge unmapped_round1.bam  um.bam mu.bam uu.bam
samtools sort -n unmapped_round1.bam > unmapped_round1_nsort.bam
samtools fastq unmapped_round1_nsort.bam -1 unmapped_round1_R1.fq.gz -2 unmapped_round1_R2.fq.gz
bowtie2 -x /home/nextgen/genomes/MG1655 -1 unmapped_round1_R1.fq.gz -2 unmapped_round1_R2.fq.gz -S align_round2.sam -X 1000 --threads 8 --very-sensitive
samtools view align_round2.sam -o align_round2.bam
samtools sort align_round2.bam -o align_round2_sort.bam
samtools view -bh -f 4 -f 8 align_round2_sort.bam > unmapped_round2.bam
samtools sort -n unmapped_round2.bam > unmapped_round2_nsort.bam
samtools fastq unmapped_round2_nsort.bam -1 unmapped_round2_R1.fq.gz -2 unmapped_round2_R2.fq.gz
bowtie2 -x /home/nextgen/genomes/human -1 unmapped_round2_R1.fq.gz -2 unmapped_round2_R2.fq.gz -S align_round3.sam -X 1000 --threads 8 --very-sensitive
samtools view align_round3.sam -o align_round3.bam
samtools sort align_round3.bam -o align_round3_sort.bam
samtools view -bh -f 4 -f 8 align_round3_sort.bam > unmapped_round3.bam
samtools sort -n unmapped_round3.bam > unmapped_round3_nsort.bam
samtools fastq unmapped_round3_nsort.bam -1 unmapped_round3_R1.fq.gz -2 unmapped_round3_R2.fq.gz
bowtie2 -x /home/nextgen/genomes/PhiX -1 unmapped_round3_R1.fq.gz -2 unmapped_round3_R2.fq.gz -S align_round4.sam -X 1000 --threads 8 --very-sensitive
samtools view align_round4.sam -o align_round4.bam
samtools sort align_round4.bam -o align_round4_sort.bam
samtools view -bh -f 4 -f 8 align_round4_sort.bam > unmapped_round4.bam
samtools sort -n unmapped_round4.bam > unmapped_round4_nsort.bam
samtools fastq unmapped_round4_nsort.bam -1 unmapped_round4_R1.fq.gz -2 unmapped_round4_R2.fq.gz
echo -------------------
echo Map remaining reads against reference with local, single-end
echo -------------------
bowtie2 -x $reference -1 unmapped_round4_R1.fq.gz -2 unmapped_round4_R2.fq.gz -S align_round5.sam -X 1000 --threads 8 --very-sensitive --local
samtools view align_round5.sam -o align_round5.bam
samtools sort align_round5.bam -o align_round5_sort.bam
samtools index align_round5_sort.bam
samtools view -b -F 2 align_round5_sort.bam > align_round5_discordant.bam 
samtools view -b -f 2 align_round5_sort.bam > align_round5_concordant.bam 
samtools index align_round5_discordant.bam 
samtools index align_round5_concordant.bam 
echo -------------------
echo Run bam-readcount
echo -------------------
bam-readcount -f $reference.fa -w 1 align_sort.bam $Reference:1-$length > align_readcount.txt
bam-readcount -f $reference.fa -w 1 align_round5_discordant.bam $Reference:1-$length > align_readcount_discordant.txt
bam-readcount -f $reference.fa -w 1 align_round5_concordant.bam $Reference:1-$length > align_readcount_concordant.txt
rm uu.bam
rm um.bam
rm mu.bam
rm unmapped_round1_nsort.bam 
rm align_round2.sam
rm align_round2.bam
rm align_round2_sort.bam
rm unmapped_round2_nsort.bam
rm align_round3.sam
rm align_round3.bam
rm align_round3_sort.bam
rm unmapped_round3_nsort.bam
rm align_round4.sam
rm align_round4.bam
rm align_round4_sort.bam
rm unmapped_round4_nsort.bam
rm align_round5.sam
rm align_round5.bam
rm align_round5_sort.bam
rm align_round5_sort.bam.bai
rm unmapped_round1_R1.fq.gz
rm unmapped_round1_R2.fq.gz
rm unmapped_round2_R1.fq.gz
rm unmapped_round2_R2.fq.gz
rm unmapped_round3_R1.fq.gz
rm unmapped_round3_R2.fq.gz
rm unmapped_round4_R1.fq.gz
rm unmapped_round4_R2.fq.gz
rm unmapped_round1.bam
rm unmapped_round2.bam
rm unmapped_round3.bam
rm unmapped_round4.bam



