## haploAnalysis
Haplotype analysis pipeline for the replicated genetic kidney loci in CHRIS study

- Attaining the total number of variants (Sat, 17:42, 22-Oct-23):
 
```bash
# imputed WES - b37
bcftools index -n /scratch/compgen/data/genetics/CHRIS13K/Imputation/WES/CHRIS13K.WES.imputed.rsq03.vep.vcf.gz
1034420

# lifted imputed WES - b38
bcftools index -n CHRIS13K.WES.imputed.rsq03.vep.hg38.sorted.bgzip.vcf.gz
1033325

# lifted and sorted imputed WES - b38
zcat /scratch/compgen/data/genetics/CHRIS13K/Imputation/WES/CHRIS13K.WES.imputed.rsq03.vep.hg38.zip.vcf.gz | cut -f1-3 | grep -v "#" | wc -l
1033325
```

- activate conda and snakemake environmemnt

```bash
export MAMBA_ROOT_PREFIX=/shared/Software/micromamba
eval "$(micromamba shell hook --shell bash)"
micromamba activate snakemake

# to see the activated environments
micromamba env list
```
## Analysis steps for each locus
- Step 1: defining the window for each locus respect to the recombination rate
- Step 2: extracting variants within the window (or recombination spikes)
- Step 3: taking dosage level of the extracted variants
- Step 4: taking annotations of the extracted variants from vcf using bcftools' vep plugin
- Step 5: taking alleles and their frequency from vcf file
- Step 6: depicting alelle frequencies of the variants
- Step 7: depicting consequences of the variants
- Step 8: depicting frequency of the variants across the genes at the locus
- Step 9: merging the dosage levels and phenotypes
- Step 10: building haplotypes and test their association with the phenotypes
- Step 11: depicting the reconstructed haplotypes (full and varied variants)
- Step 12: visulaizing association results via heatmap plot
- Step 13: reporting the results using Rmarkdown

```bash
rule targets:
	input:
		get_ranges()

def get_ranges(wildcards):
	myfiles = "genotype/{locus}.vcf.gz"

	return(myfiles)

rule two:
	input:
		get_ranges()


direct = directory("genotype/{locus}"),

output:
	odir = directory("genotype/{locus}"),
	ofile = "genotype/{locus}/{locus}.vcf.gz"


# or 
# Determine the {vcf} for all loci
#vcf, = glob_wildcards("genotype/{locus}.vcf.gz")
#dosag, = glob_wildcards("genotype/{locus}_dosage.txt")
#annot, = glob_wildcards("genotype/{locus}_variants.list")

```
- Allele frequency of the extracted variants at each locus was depicted using `01-3_plot_histogram.R` (Thu, 18:42, 26-Oct-23).

- Add haplotype reconstruction script to the pipeline using `03-1_haplotypes_building.R` (Wed, 16:50, 13-Dec-23).

- Draw the workflow diagram (Wed, 13-Dec-23).

```bash
snakemake --dag targets | dot -Tpng > Tag.png
```

- Add visualization of the recnstructed haplotype to the workflow (Wed, 21:30, 13-Dec-23).

- Haplotypes plot were generated in two version, full variants and shrinked variants, using `03-2_plot_haplotypes.R` (Thu, 20:16, 14-Dec-23)

- Variants consequences were visulalized for each locus using `01-4_plot_annotation.R` (Fri, 02:02, 15-Dec-23).

- Working to add heatmap plot to visualize the haplotypes associations results using `03-3_haplotypes_heatmap.R` (Fri, 18:10, 15-Dec-23).

- Meanwhile, I'm going attend at Eurac X-Mass party at NOI techpark (Fri, 18:10, 15-Dec-23).

- Heatmap plots of haplotypes associations with the traits were added to the pipeline using `03-3_haplotypes_heatmap.R`.

- The Rmarkdown report was generated using `04-0_report.Rmd`.

- The Rmarkdown report was automated for the loci using `04-1_report_run.sh` (Sat, 22:16, 16-Dec-23).

```bash
# limit the job run to just one rule (-n for a dry-run)
snakemake -R --until plot_associations -n

```
- The frequency of the variants of each gene at the input locus was depicted using `01-5_plot_genes.R` (Mon, 14:20, 18-Dec-23).

- Trying to run the jobs on clusters using below (Mon, 18:40, 18-dec-23):
```bash
snakemake --latency-wait 60 --use-conda --cluster-config cluster.yaml --cluster "sbatch -p {cluster.partition}  --mem-per-cpu={cluster.mem} -c {cluster.cores}" --jobs 20
```

- Finally ran teh pipeline on clustered computer using slurm (Thu, 19:30, 21-Dec-23).

```bash
# full version
snakemake   --reason --until get_locus --jobs 3  --default-resource mem_gb=8800  --latency-wait 30  --keep-going  --cluster 'sbatch  --partition fast  --cores 3          --mem-per-cpu=8GB --output  output/{rule}.{wildcards}.out  -error   output/{rule}.{wildcards}.err'

# modified
snakemake  --use-conda  --reason --until get_locus --jobs 3  --default-resource mem_gb=8GB  --latency-wait 30  --keep-going  --cluster 'sbatch  -p fast -cpu-per-task {threads} --mem-per-cpu=8'

# short version
snakemake --jobs 3  --reason --until get_dosage --default-resource mem_gb=8192  --latency-wait 10  --keep-going  --cluster 'sbatch  -p fast -c 3 --mem-per-cpu=8GB'
```

- Update the pipeline to have consistant name and wildcards for reporting and performing on cluster (Fri, 19:50, 22-Dec-23).

```bash
sbatch --wrap 'Rscript 03-1_haplotypes_data.R  data/dosage/IGF1R_dosage.txt' -c 2 --mem-per-cpu=16GB -J "03-1_IGF1R.R"
sbatch --wrap 'Rscript 03-2_haplotypes_building.R  data/pheno/IGF1R_haplotypes_data.csv' -c 2 --mem-per-cpu=16GB -J "03-2_IGF1R.R"
sbatch --wrap 'Rscript 03-4_haplotypes_heatmap.R   output/result_associations/IGF1R_haplotypes_association.RDS' -c 2 --mem-per-cpu=16GB -J "03-4_IGF1R.R"
```

- Equalizing number of haplotypes for each trait by means of regulating EM algorithm control parameters (Sun, 23:30, 31-Dec-23).

- Happy New Year 2024!!!

- By setting parameters controling EM algorithm, we ended up with equivalent number of IGF1R locus haplotypes associated with each traits (Mon, 23:55, 01-Jan-23):
`haplo.freq.min = .01; haplo.em.control(n.try = 2, insert.batch.size = 2, max.haps.limit = 4e6, min.posterior = 1e-6)`

- Tuning parameters of EM algorithm did not garranty to have equal no. of haplotypes. So, phenotypes must be imputed before building haplotypes (Tue, 23:55, 02-Jan-23)! 

- Haplotypes plot got fixed! When storing the output of `haplo_plot()` function, the width size is now properly set for both full and shrinked plots (Wed, 23:55, 03-Jan-24).

- Compeleted the haplotype plot and heatmap plot for two other tested loci (Fri, 18:20, 05-Jan-24).

- There are some samples with duplicated AID (called "POOL") and unique sample_id in the proteomics data which are removed when merging with genotypes (Tue, 14:35, 08-Jan-24).

- Association tests of haplotypes with metabolomics and proteomics is added and the subsequent scripts from 03-1 to 03-4 were modified to incorporate the changes (Tue, 19:25, 08-Jan-24).

- Metabolomics and Proteomics association results (heatmap plots) were incorporated in the rmarkdown report (Tue, 19:00, 09-Jan-24).

- Working to render properly the significant association table.


## Pipeline on clustered computers

- Analysis levereged for the seven left loci. These files were added:
    - config/congfiguration.yaml
    - cluster/config.yml
    - workflow/results

- Up to `03-2_haploype_build.R` was performed on the clusters (Wed, 23:50, 27-Mar-24).

- Haplotypes for the rest of the loci are being analyzed on the clusters. In addition, reporting the analyses in Rmarkdown is integrated into the pipeline in a separe rule (for now).

- So, the analysis is approaching to the end and it's time to start writng the paper (Mon, 02:53, 01-Apr-24).

- Once facing with this error:  `snakemake: error: unrecognized arguments: --executor=slurm`, just need to add `--slurm --cluster-config slurm/` to make file `run_pipeline.sh` and rerun it (Wed, 05:00, 03-Mar-24).

- Check if the scripts are executable: `SLURM job submission failed. The error message was sbatch: error: Unable to open file +` -> solution: `chmod 755 <scripy.format>`

- To check the app version, run `snakemake --version -> 7.32.4`

- The haplotype building step took so long (>7 hours with 420 variants) compared to the rest of the loci. To lower variants and haplotypes narrow the window from the right side to the end of PIPKA1B gene. In the end, the pipeline was implemented on the whole 11 loci and the results were integrated into the html report using Rmarkdown. These reports were saved into a `results/report_html` directory and the PI got informed. It is time to compose the manuscript of the pipeline (Sun, 17:05, 07-Apr-24).

- The pipeline should be tested via the latest version of snakemake before the official release to make sure of the flixibility of the pipeline to dynamically deal with the errors pertaining the memory and RAM insufficiency and running time limitation (Sun, 17:05, 07-Apr-24). 

- The RDS files were sorted by the trait names and haplotypes and saved in CSV format (Tue, 23:49, 11-Jun-24).

- Working on supplementary materials to send the draft to PI in the following days (Tue, 23:50, 11-Jun-24).

Dariush
