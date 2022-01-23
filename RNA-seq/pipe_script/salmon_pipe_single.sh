#!/bin/bash
# command line variable 
while getopts i:o:x:t:g: flag
do
    case "${flag}" in
        i) dir=${OPTARG};;
        o) outdir=${OPTARG};;
        x) indexdir=${OPTARG};;
        t) thread=${OPTARG};;
        g) type=${OPTARG};;
    esac
done


# find & unique
file_list=$(find ${dir} -maxdepth 1 -type f -exec basename "{}" \; | cut -d'_' -f1 | sort -u)
echo $file_list

for file_name in $file_list
do
    echo $file_name
    if [ ${type} = "fastq" ];then
        salmon quant -p ${thread} -l A -i ${indexdir} -o ${outdir}/${file_name} --validateMappings -r ${dir}/${file_name}_R1_trimmed.fq.gz
    elif [ ${type} = "fq" ];then
        salmon quant -p ${thread} -l A -i ${indexdir} -o ${outdir}/${file_name} --validateMappings -r ${dir}/${file_name}_R1.${type}.gz
    else
        salmon quant -p ${thread} -l A -i ${indexdir} -o ${outdir}/${file_name} --validateMappings -r ${dir}/${file_name}_R1_trimmed.fq.gz
    fi
done