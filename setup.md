---
title: Setup
---

## Requirements

You will requre 1) all the correct programs, 2) all the listed R packages 3) the dataset and code. Instructions for all these are below.

> ## Setup Checklist
> You can use the following checklist to keep track of your progress. If you have trouble with any step of the process,
> do not hesitate to contact us and we will help you solve it in advance of the workshop. 
>
> 
> **Software & Environment**
> - I have installed the latest version of R and RStudio. Note: Older versions may cause compatibility issues with some packages.
> - I have installed Julia.
> - I have run the setup script from this page, and installed all relevant packages
> 
> **Files & Resources**
> - I have downloaded the correct data files and scripts from the official source. Note: for this workshop, the official source is [here](https://github.com/ocean-tracking-network/2026-OTN-symposium-ecr-workshop)
> - The downloaded files are unzipped and saved in my RStudio instance's current working directory. Note: You can use `getwd()` in the RStudio console to check your current working directory and make sure your files are there. 
>
> 
> **Network & Access**
> - I have connected to the correct Wi-Fi network.
{: .callout}

### Please see the attached document for program instructions: - [Program Install Instructions.docx](/Resources/install_instructions.docx)
-  R version: 4.5.x or newer 
-  RStudio
- Julia 

Once all of the programs are installed, open RStudio and run the below package install scripts. It's best to run it line by line instead of all at once in case there are errors.

<b>Note:</b> When running through the installs, you may encounter a prompt asking you to upgrade dependent packages. Choosing Option `3: None`, works in most situations and will prevent upgrades of packages you weren't explicitly looking to upgrade.

### R Workshop Requirements

```r

# General packages
install.packages('tidyverse') #For data cleaning and arrangement)
install.packages('lubridate') # Lubridate - part of Tidyverse, improves the process of creating date objects
install.packages("viridis") #color scales in this package are easier to read by those with colorblindness, and print well in grey scale.

```

```r
# Patter lesson - install packages for patter

install.packages(c("devtools", "pkgbuild", "rmarkdown"))

# Install the {JuliaCall} package:
install.packages("JuliaCall")
# Use the development version if the CRAN version is unavailable:
devtools::install_github("JuliaInterop/JuliaCall",
                         dependencies = TRUE)
# Run julia_setup() to set up the Julia installation 
# * This includes an installJulia argument if the above Julia installation options fail 
# * Set `JULIA_HOME` if Julia is not found (see `?julia_setup()`)
# * Note this may take several minutes
# * Set `rebuild = TRUE` if you've previously used JuliaCall on an older R version
library(JuliaCall)
julia <- julia_setup()

# Validate the Julia installation:
# * TRUE: `Julia` is working! 
# * FALSE: `Julia` is not working (see below)! 
isTRUE(try(julia_eval('true'), silent = TRUE))

devtools::install_github("edwardlavender/patter", 
                         dependencies = TRUE, 
                         build_vignettes = rmarkdown::pandoc_available())

# Load & attach {patter}:
library(patter)

# Option (A): Connect to `Julia`: 
# * Set `JULIA_HOME` if 'Julia not found'
# * Set `JULIA_PROJ` to use a local Julia project (recommended)
# * Set `JULIA_NUM_THREADS` to exploit multi-threading (recommended)
# * Set `.pkg_update = TRUE` if you've just installed a newer version of `patter`
# * Set `JULIA_PATTER_SOURCE` = "dev" as well if you've installed from the `dev` branch
# * See `julia_connect()` for further guidance
julia <- julia_connect()

julia_validate() #This should return NULL
```

```r
# GAMs lesson - install packages for modelling and plotting.

install.packages("mgcv")
install.packages("gratia")

```


# Dataset and Code

<b>Once the above packages are installed</b>, you can download the datasets and code for this workshop from <b>[this link](https://github.com/ocean-tracking-network/2026-OTN-symposium-ecr-workshop)</b>

1. Select the GREEN "Code" button at the top and choose "Download ZIP"
2. Unzip the folder and move to secure location on your computer (Documents, Desktop etc.)
3. Copy the folder's path and use it to set your working directly in R using `setwd('<path-to-folder>')`.

If you are familiar with Git and Github, feel free to clone this repository as you normally would, by running `git clone https://github.com/ocean-tracking-network/2026-OTN-symposium-ecr-workshop.git` in a terminal program and following from step `3` above.






{% include links.md %}
