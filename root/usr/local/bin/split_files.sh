#!/bin/bash

# Define the function
split_files() {

  # Set the target directory
  target_dir=$1
  temp_dir=$2

  # Set the minimum modification date, maximum modification date and maximum total file size
  min_date=${3:-"1671856158"} #1970-01-01
  max_date=${4:-"1671856158"} #now
  max_size=${5:-"5242880"}
  split_file_prefix==${6:-"group-"}
  split_file_suffix=${7:-".txt"}
  

  # Initialize variables
  file_list=()
  group_size=0
  group_num=1

  # Iterate over the files in the target directory
  for file in "$target_dir"/*; do
    # Get the modification time of the file
    mtime=$(stat -c %Y "$file")

    # Check if the file was modified after the minimum date
    if [ $mtime -gt $min_date ] && [ $mtime -lte $max_date ]; then
      # Get the file size
      size=$(stat -c %s "$file")

      # Check if adding the file to the current group would exceed the maximum size
      if [ $(($group_size + $size)) -gt $max_size ]; then
        # Save the current group to a text file
        printf "%s\n" "${file_list[@]}" > "${temp_dir}/${split_file_prefix}${group_num}${split_file_suffix}"

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
  done

  # Save the final group to a text file
  printf "%s\n" "${file_list[@]}" > "${temp_dir}/${split_file_prefix}${group_num}${split_file_suffix}"
}

# # Set the target directory
# target_dir="/path/to/directory"

# # Set the config directory
# temp_dir="/path/to/temp/directory"

# # Set the minimum modification date and maximum total file size
# min_date=1609459200  # January 1, 2021 in Unix timestamp format
# max_date=1640995200  # January 1, 2022 in Unix timestamp format

#  # Optional - Set max file size, save into another tar if total size will exceed the thershold kB (5GB)
#  max_file_size="5242880"

# split_file_prefix="group-"
# split_file_suffix=".txt"

# # Call the function
# split_files "$target_dir" "$temp_dir" "$min_date" "$max_date" "$max_size" "$split_file_prefix" "$split_file_suffix"