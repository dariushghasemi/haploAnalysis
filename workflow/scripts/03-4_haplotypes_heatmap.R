#!/usr/bin/Rscript


# The script created on 15/12/2023
# to depic the consequences of the
# variants at each replicated loci.

#----------#
# print time and date
Sys.time()

# date
today.date <- format(Sys.Date(), "%d-%b-%y")

#----------#
# taking variants file as input
args <- commandArgs(trailingOnly = TRUE)

rds_file <- args[1]
out.plt  <- args[2]
out.tbl  <- args[3]
rds_out  <- args[4]

# taking the locus name
locus_name  <- gsub("\\d{2}-\\w{3}-\\d{2}_|_\\w+_haplotypes_association.RDS", "", basename(rds_file))
locus_name

# type of dataset
data_source <- gsub("(\\w+|\\d)_haplotypes_association_with_|.RDS", "", basename(rds_file))
data_source

#------------#
# directories
base.dir <- "/home/dghasemisemeskandeh/projects/haploAnalysis/workflow/results"
#out.plot <- paste0(base.dir, "/plot_heatmaps/", locus_name, "_plot_heatmap_haplotypes_effect_on_", data_source, ".png") #today.date, "_", 
#out.tbl  <- paste0(base.dir, "/significant_result/", locus_name, "_haplotypes_association_with_", data_source, ".csv")

#------------#
# function to install uninstalled required packages
is.installed <- function(package_name){
    is.element(package_name, installed.packages()[,1])
}

# check if package "Haplo.stats" is installed
if (!is.installed("pheatmap")){
   install.packages("pheatmap");
}

#------------#
suppressMessages(library("tidyverse"))
suppressMessages(library("pheatmap"))

#------------#
# Function to generate a unique name for each unique combination of variants
change_haplo_name <- function(df) {
  if (all(df$Haplotype == "Ref.")) {
    # Keep "Ref." if the haplotype is identical across traits
    return("Ref.")
  } else {
  # Exclude trait_name and Haplotype columns
  uniq_haplo <- unique(df[- c(1:2)])

  hash <- apply(uniq_haplo, 1, function(x) paste(x, collapse = "_"))
  # Use a consistent name for each group
  haplo_name <- setNames(paste0("H", seq_along(hash)), hash)

  return(haplo_name)
  }
}

# Function to check if haplotype is identical across traits
is_identical_haplotype <- function(df, haplotype) {
  identical_rows <- df %>%
    filter(Haplotype == haplotype) %>%
    select(-trait_name, -Haplotype) %>%
    summarise_all(~all(. == first(.))) %>%
    unlist()
  
  return(all(identical_rows))
}

#----------#
# saving haplotype name
haplo_dict0 <- readRDS(rds_file) %>% 
  ungroup() %>%
  select(trait_name, haplotype) %>% 
  unnest(haplotype) %>% 
  select(- hap.freq) %>% 
  filter(Haplotype != "Hrare")

variants <- grep("^chr", names(haplo_dict0), value = TRUE)

#----------#
# changing haplotype name
haplo_dict <- haplo_dict0 %>% 
  #group_by(trait_name) %>% #count(trait_name) %>% print(n = Inf)
  #change_haplo_name(.)
  #mutate(haplo = do.call(paste, c(select(., all_of(variants)), sep = "_"))) %>%
  #add_count(haplo, name = "haplo_count") %>%
  #filter(haplo_count == max(haplo_count)) %>% #select(trait_name, Haplotype, haplo_count, haplo) %>% print(n =Inf) 
  group_by(trait_name) %>%
  mutate(
    haplo = change_haplo_name(.),
    haplo = if_else(Haplotype == "Ref.", "Ref.", haplo)
  ) %>%
  ungroup() %>%
  select(trait_name, Haplotype, haplo)

#----------#
# extract results and add harmonized haplo names 
get_results <- function(df) {
  
  df %>%
    select(- haplotype) %>%
    unnest(tidy) %>%
    ungroup() %>%
    mutate(
      associated = ifelse(p.value <= 0.05, "Yes", "No"),
      term = str_replace(
        term, 
        "(?<=\\.)\\d{1,2}(?!\\d)",
        sprintf("%03d", as.numeric(str_extract(term, "(?<=\\.)\\d{1,2}(?!\\d)")))
        	),
      term = str_replace(term, "haplo_genotype.", "H")
      ) %>%
    filter(!str_detect(term, "(Intercept)|PC|Sex|Age|rare")) %>%
    # Uses right_join to ensure using only available haplotypes for all traits
    right_join(haplo_dict, by = c("trait_name" = "trait_name", "term" = "Haplotype"))
}

#----------#
# reshaping results for drawing heatmap
res_to_heat <- function(df){
  
  df %>%
    select(trait_name, haplo, estimate) %>%
    filter(haplo != "Ref.") %>%
    mutate(trait_name = str_replace_all(trait_name, "_", ":")) %>%
    pivot_wider(names_from = trait_name, values_from = estimate)
}

#----------#
# saving tidied results for report
results_heatmap <- readRDS(rds_file) %>% 
  get_results() %>% 
  filter(haplo != "Ref.") %>% 
  select(trait_name, haplo, estimate, std.error, statistic, p.value) %>%
  arrange(haplo, p.value)

saveRDS(results_heatmap, rds_out)

#----------#
# saving nominal significant associations
results_sig <- readRDS(rds_file) %>%
  get_results() %>%
  filter(associated == "Yes") %>%
  select(trait_name, haplo, estimate, std.error, p.value, associated) %>%
  arrange(haplo, p.value)

results_sig

# store results
write.csv(results_sig, file = out.tbl, row.names = FALSE, quote = FALSE)

#----------#
# Reading and manipulating the association results for illustartion
# 01: Blood biomarkers, 02: Proteins, 03: Metabolites

# convert result to wide format
results_wide <- readRDS(rds_file) %>% 
  get_results() %>% 
  res_to_heat()


check_haplo <- nrow(results_wide) > 1
check_haplo

#----------#
# pheatmap
png(out.plt, units = "in", res = 500, width = 19, height = 6) # for traits use width = 12

pheatmap(results_wide[-1],
         #color = hcl.colors(50, "Blue-Red 2"),
         #breaks = seq(-rg, rg, length.out = 100), #rg <- max(abs(results_wide[-1]))
         #color = myColor, 
         #breaks = myBreaks,
         labels_row = results_wide$haplo,
         #display_numbers = results_omics_pval[-1],
         number_color = "gold",
         cluster_cols = check_haplo,
         cluster_rows = check_haplo,
         clustering_method = "ward.D2",
         na_col = "white",
         border_color = NA, 
         #annotation_col = annot_omics,
         #annotation_colors = annot_colors,
         #display_numbers = F,
         fontsize_number = 15,
         fontsize_row = 10,
         fontsize_col = 10,
         angle_col = "270")

dev.off()

#----------#
#sbatch --wrap 'Rscript 03-4_haplotypes_heatmap.R output/result_associations/IGF1R_haplotypes_association.RDS ' -c 2 --mem-per-cpu=32GB -J "03-2_IGF1R.R"