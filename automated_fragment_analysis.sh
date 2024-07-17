#!/bin/bash

# Check if R is installed
REQUIRED_PKG="r-essentials"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
echo Checking if $REQUIRED_PKG is installed: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  conda install -c r $REQUIRED_PKG
fi

# Check if cmake is installed
REQUIRED_PKG="cmake"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
echo Checking if $REQUIRED_PKG is installed: $PKG_OK
if [ "" = "$PKG_OK" ]; then
  conda install $REQUIRED_PKG
fi

echo "Starting R pipeline"

# Prompt the user for input using Zenity
result=$(zenity --forms --title="Input Data" --text="Enter the details of the experiment" \
    --add-entry="Methylated peak size (bp):" \
    --add-entry="Unmethylated peak size (bp):" \
	--add-entry="Peak calling tollerance (+-bp):" \
	--add-entry="Normalization peak size (bp):" \
	--add-entry="Name of sample to use as reference for statistics:" \
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

# Display the input data (for demonstration)
echo "met_peak: $met_peak"
echo "unmet_peak: $unmet_peak"
echo "peak_tolerance: $peak_tolerance"
echo "scaling_peak: $scaling_peak"
echo "reference_sample: $reference_sample"
echo "Running R script..."

Rscript -e "rmarkdown::render('Fragment_analysis_EG.Rmd', params = list(
  met_peak = $met_peak,
  unmet_peak = $unmet_peak,
  peak_tolerance = $peak_tolerance,
  scaling_peak = $scaling_peak,
  reference_sample = $reference_sample),
  output_file = 'Fragment_analysis_EG_results')"

echo "Done!"
