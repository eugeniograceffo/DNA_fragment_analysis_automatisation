#!/bin/bash

# initial prints
echo "Checking if required packages are installed.."


# Function to check if a package is installed in Debian
debian_package_installed() {
    local pkg_name="$1"
    dpkg-query -W --showformat='${Status}\n' "$pkg_name" 2>/dev/null | grep -o "install ok installed"
}

# Function to check if a package is installed in Conda environment
conda_package_installed() {
    local pkg_name="$1"
    conda list | grep -o "$pkg_name"
}

# Function to install a package via Conda
conda_install_package() {
    local pkg_name="$1"
    conda install "$pkg_name"
}

# Check if R essentials are installed (Debian or Conda)
REQUIRED_PKG="r-essentials"
if ! debian_package_installed "$REQUIRED_PKG" && ! conda_package_installed "$REQUIRED_PKG"; then
    echo "$REQUIRED_PKG is not installed. Installing..."
    conda install -c r r r-essentials
else
    echo "$REQUIRED_PKG is already installed."
fi

# Check if cmake is installed (Debian or Conda)
REQUIRED_PKG="cmake"
if ! debian_package_installed "$REQUIRED_PKG" && ! conda_package_installed "$REQUIRED_PKG"; then
    echo "$REQUIRED_PKG is not installed. Installing..."
    conda_install_package "$REQUIRED_PKG"
else
    echo "$REQUIRED_PKG is already installed."
fi


echo "Starting R pipeline.."

# Prompt the user for input using Zenity
result=$(zenity --forms --title="Input Data" --text="Enter the details of the experiment" \
    --add-entry="Methylated peak size (bp):" \
    --add-entry="Unmethylated peak size (bp):" \
	--add-entry="Peak calling tollerance (+-bp, standard is 5):" \
	--add-entry="Normalization peak size (bp, standard is 200):" \
	--add-entry="Name of sample to use as reference for statistics:" \
	--add-entry="Name of sample to remove from statistical analysis:" \
    --separator="|")

# Check if the user clicked "Cancel" or closed the dialog
if [ $? -eq 1 ]; then
    echo "Pipeline was cancelled by the user."
    exit 1
fi


# Parse the input (assuming '|' as separator)
met_peak=$(echo $result | cut -d '|' -f 1)
unmet_peak=$(echo $result | cut -d '|' -f 2)
peak_tolerance=$(echo $result | cut -d '|' -f 3)
scaling_peak=$(echo $result | cut -d '|' -f 4)
reference_sample=$(echo $result | cut -d '|' -f 5)
sample_to_remove=$(echo $result | cut -d '|' -f 6)


# Check if the users has input at least me and unmet sizes
if [ -z "$met_peak" ] || [ -z "$unmet_peak" ]; then
    echo "The pipeline needs the methylated and unmethylated peak sizes to run. Please re-run the pipeline and input those values"
    exit 1
fi

# Set standard values if user left blanks
if [ -z "$peak_tolerance" ]; then
	peak_tolerance="5"
	echo "Setting standard peak calling tollerance of 5 bp"
fi

if [ -z "$scaling_peak" ]; then
	scaling_peak="200"
	echo "Setting standard ladder peak for normalization as 200 bp"
fi



if [ -z "$sample_to_remove" ]; then
	sample_to_remove="Not_set"
	echo "Using all samples for statistical analysis"
fi

if [ -z "$reference_sample" ]; then
	reference_sample=".all."
	echo "No sample was set as reference for statistical analysis. Comparing all samples against overall mean"
fi



# Display the input data (for demonstration)
echo "met_peak: $met_peak"
echo "unmet_peak: $unmet_peak"
echo "peak_tolerance: $peak_tolerance"
echo "scaling_peak: $scaling_peak"
echo "reference_sample: $reference_sample"
echo "sample_to_remove: $sample_to_remove"
echo "Running R script..."

Rscript -e "rmarkdown::render('Fragment_analysis_EG.Rmd', params = list(
  met_peak = $met_peak,
  unmet_peak = $unmet_peak,
  peak_tolerance = $peak_tolerance,
  scaling_peak = $scaling_peak,
  reference_sample = \"$reference_sample\",
  sample_to_remove = \"$sample_to_remove\"),
  output_file = 'Fragment_analysis_EG_results')"

echo "Pipeline was run successfully!"
