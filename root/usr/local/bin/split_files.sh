#!/bin/bash

# Define the function
split_files() {

  # Set the target directory
  source_dir=$1
  config_dir=$2

  # Set the minimum modification date, maximum modification date and maximum total file size
  min_date=${3:-"1671856158"} #1970-01-01
  max_date=${4:-"1671856158"} #now
  max_size=${5:-"5242880"}
  split_file_prefix=${6:-'group-'}
  split_file_suffix=${7:-'.txt'}
  

  # Initialize variables
  file_list=()
  group_size=0
  group_num=1

  
  file_list_file="${config_dir}/${split_file_prefix}source_files.txt"
  find "${source_dir}"  -type f  -newermt "${min_file_mod_time}" ! -newermt "${max_file_mod_time}" > "${file_list_file}"
  echo "$(date) Found $( cat "${file_list_file}" | wc -l) files in ${source_dir} for selected date range."

  # Iterate over the files in the target directory
  while read file; do
    # Get the modification time of the file
    mtime=$(stat -c %Y "$file")

    # Check if the file was modified after the minimum date
    if [ $mtime -gt $min_date ] && [ $mtime -le $max_date ]; then
      # Get the file size
      size=$(stat -c %s "$file")

      # Check if adding the file to the current group would exceed the maximum size
      if [ $(($group_size + $size)) -gt $max_size ]; then
        # Save the current group to a text file
        echo "saving file list: ${config_dir}/${split_file_prefix}${group_num}${split_file_suffix}"
        printf "%s\n" "${file_list[@]}" > "${config_dir}/${split_file_prefix}${group_num}${split_file_suffix}"

        # Reset the file list and group size
        file_list=()
        group_size=0

        # Increment the group number
        group_num=$((group_num + 1))
      fi

      # Add the file to the file list and update the group size
      file_list+=("$file")
      group_size=$(($group_size + $size))
    fi
  done < ${file_list_file}

  # Save the final group to a text file
  echo "saving file list: ${config_dir}/${split_file_prefix}${group_num}${split_file_suffix}"
  printf "%s\n" "${file_list[@]}" > "${config_dir}/${split_file_prefix}${group_num}${split_file_suffix}"
}

# # Set the target directory
# target_dir="/path/to/directory"

# # Set the config directory
# config_dir="/path/to/temp/directory"

# # Set the minimum modification date and maximum total file size
# min_date=1609459200  # January 1, 2021 in Unix timestamp format
# max_date=1640995200  # January 1, 2022 in Unix timestamp format

#  # Optional - Set max file size, save into another tar if total size will exceed the thershold kB (5GB)
#  max_file_size="5242880"

# split_file_prefix="group-"
# split_file_suffix=".txt"

# # Call the function
# split_files "$target_dir" "$config_dir" "$min_date" "$max_date" "$max_size" "$split_file_prefix" "$split_file_suffix"