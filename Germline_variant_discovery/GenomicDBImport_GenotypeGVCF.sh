#!/bin/bash
#docker run --rm -dit -v ${PWD}:/gatk/work --name gatk broadinstitute/gatk:4.1.8.1 bash
START=$(date +%s)

while getopts w:b:r:d:i:o: flag
do
    case "${flag}" in
        w) gvcfPath=${OPTARG};;
        b) genomicPath=${OPTARG};;
        r) ref=${OPTARG};;
        d) dbsnp=${OPTARG};;
        i) interval=${OPTARG};;
        o) finalPath=${OPTARG};;

    esac
done

# sample map make
for i in ${gvcfPath}/*.g.vcf
do 
   echo `bcftools query -l $i`;echo $i
done | paste - - > ${gvcfPath}/sample.map

# GenomicDBImport
mkdir -p ${genomicPath}
for i in `seq -f %04g 0 14`
do
    gatk --java-options "-Xmx5G -XX:+UseParallelGC -XX:ParallelGCThreads=5" GenomicsDBImport \
            -R ${ref} \
            --genomicsdb-workspace-path ${genomicPath}/${i} \
            --sample-name-map ${gvcfPath}/sample.map \
            -L ${interval}/${i}-scattered.interval_list \
            --tmp-dir "/gatk/temp" &
done
wait

# GenotypeGVCFs
cd /gatk/work
mkdir -p ${finalPath}
for i in `seq -f %04g 0 14`
do
    if [ ${i} = 1 ]
    then
        echo ${finalPath}/scatter-vcf-${i}.vcf > ${finalPath}/vcf_file.list
    else
        echo ${finalPath}/scatter-vcf-${i}.vcf >> ${finalPath}/vcf_file.list
    fi
    
    #PATH confirm
    gatk --java-options "-Xmx5G -XX:+UseParallelGC -XX:ParallelGCThreads=5" GenotypeGVCFs \
            -R ${ref} \
            -V gendb://germline/genomicDB/${i} \
            -D ${dbsnp} \
            -O ${finalPath}/scatter-vcf-${i}.vcf &
done
wait

# GatherVCF
gatk --java-options "-Xms15G -Xmx15G" GatherVcfs \
            -R ${ref} \
            -I ${finalPath}/vcf_file.list \
            -O ${finalPath}/raw_merged.vcf

# Sort
gatk --java-options "-Xms25G -Xmx25G" SortVcf \
            -I ${finalPath}/raw_merged.vcf \
            -O ${finalPath}/raw_merged.sort.vcf

# Time stemp
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "GenomicDBImport & GenotyepGVCFs $DIFF seconds"

