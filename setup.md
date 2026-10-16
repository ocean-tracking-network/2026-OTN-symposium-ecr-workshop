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

Once all of the programs are installed, open RStudio and run the below package install scripts. It's best to run it line by line instead of all at once in case there are errors.

<b>Note:</b> When running through the installs, you may encounter a prompt asking you to upgrade dependent packages. Choosing Option `3: None`, works in most situations and will prevent upgrades of packages you weren't explicitly looking to upgrade.

### R Workshop Requirements

```r

# Tidyverse (data cleaning and arrangement)
install.packages('tidyverse')

# Lubridate - part of Tidyverse, improves the process of creating date objects
install.packages('lubridate')

# GAMs lesson - install packages for modelling and plotting.
install.packages("mgcv")
install.packages("gratia")

# Viridis - color scales in this package are easier to read by those with colorblindness, and print well in grey scale.
install.packages("viridis")
```


# Dataset and Code

<b>Once the above packages are installed</b>, you can download the datasets and code for this workshop from <b>[this link](https://github.com/ocean-tracking-network/2026-OTN-symposium-ecr-workshop)</b>

1. Select the GREEN "Code" button at the top and choose "Download ZIP"
2. Unzip the folder and move to secure location on your computer (Documents, Desktop etc.)
3. Copy the folder's path and use it to set your working directly in R using `setwd('<path-to-folder>')`.

If you are familiar with Git and Github, feel free to clone this repository as you normally would, by running `git clone https://github.com/ocean-tracking-network/2026-OTN-symposium-ecr-workshop.git` in a terminal program and following from step `3` above.






{% include links.md %}
