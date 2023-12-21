#!/usr/bin/bash

# take the vcf file as input
locus_vcf=$1

# base name of the locus file
locus_file="$(basename -- $locus_vcf)"

#------------------------#
# removing file format
locus=$(echo $locus_file | sed -e 's/.vcf.gz//g')

# attain the number of exonic variants in the locus
n_SNPs=$(bcftools index -n $locus_vcf)

# briefly describing the process in this script
echo Working on "${n_SNPs}" exonic variants at "${locus}" locus...

#------------------------#
# directories
genotype=data/genotype/${locus}.vcf.gz
dosage=data/dosage/${locus}_dosage.txt
variants=data/annotation/${locus}_variants.list
annotation=data/annotation/${locus}_annotation.txt

#------------------------#
# extract variants in the region after merging
bcftools query -f '[%SAMPLE\t%CHROM\t%POS\t%ID\t%REF\t%ALT\t%AF\t%DS\n]' $genotype -o $dosage
sleep 5

# extract variants alleles and alleles' frequencies 
bcftools query -f '%CHROM\t%POS\t%ID\t%REF\t%ALT\t%AF\n' $genotype -o $variants
sleep 5

# extract variants annotation
bcftools +split-vep  -s worst -f '%CHROM\t%POS\t%ID\t%SYMBOL\t%Gene\t%Consequence\n' $genotype -o $annotation

#------------------------#
# ending message!
echo The dosage levels, characteristics, and annotations of the variants in "${locus}" locus were created.
