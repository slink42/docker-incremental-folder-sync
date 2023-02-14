#!/bin/bash

source /usr/local/bin/log_functions.sh
split_log_tag="INC_FOLDER_SPLIT"

# Define the function
function split_files() {

  # Set the target directory
  split_source_dir=$1
  config_dir=$2

  # Set the minimum modification date, maximum modification date and maximum total file size
  current_datetime_format="%Y-%m-%d %H%M"
  current_datetime=$(date +"${current_datetime_format}")
  min_file_mod_time=${3:-"0001-01-01"} #0001-01-01
  max_file_mod_time=${4:-"${current_datetime}"} #now
  split_mode=${5:-"bytes_avg"} #count/bytes/bytes_avg
  # count - (fast) - max_size = number of files in each split
  # bytes_avg - (less fast) - max_size is used as average batch size instead. The number of files to include in each split is estimate so that on average each batch contains max_size bytes of files
  # bytes - (very slow) - max_size is used as hard limit for fiels to include in each batch
  max_size=${6:-"5000000000"} #5GB in bytes is used with split_mode bytes_avg/bytes
  split_file_prefix=${7:-'group'}
  split_file_suffix=${8:-'.splitfilelist'}

  # Initialize variables
  file_list=()
  group_size=0
  group_num=1

  # Populate list file with all files meeting criteria
  logf "${split_log_tag}" "min file timestamp: $min_file_mod_time max file timestamp: $max_file_mod_time"
  file_list_file="${config_dir}/${split_file_prefix}.filelist"
  find "${split_source_dir}"  -type f  -newermt "${min_file_mod_time}" ! -newermt "${max_file_mod_time}" > "${file_list_file}"
  total_files=$(cat "${file_list_file}" | wc -l)
  logf "${split_log_tag}" "Found ${total_files} files in ${split_source_dir} for selected date range. Saved list to: ${file_list_file}"

  # Split file list file into smaller batches of file list files
  if [ "$split_mode" = "bytes" ]; then
      # Iterate over the files in the target directory
      while read file; do
        # Get the file size
        size=$(stat -c %s "$file")

        # Check if adding the file to the current group would exceed the maximum size
        if [ $(($group_size + $size)) -gt $max_size ]; then
          
          # Save the current group to a text file
          split_file_name="${config_dir}/${split_file_prefix}_${group_num}${split_file_suffix}"
          printf "%s\n" "${file_list[@]}" > "${split_file_name}"
          logf "${split_log_tag}" "Split $( cat "${split_file_name}" | wc -l) files into file list file: ${split_file_name}"

          # Reset the file list and group size
          file_list=()
          group_size=0

          # Increment the group number
          group_num=$((group_num + 1))
          split_file_name="${config_dir}/${split_file_prefix}_${group_num}${split_file_suffix}"
        fi

        # Add the file to the file list and update the group size
        file_list+=("$file")
        group_size=$(($group_size + $size))
        # logf "${split_log_tag}" "split group: $group_num - size: $group_size / $max_size - added: $(head -c 100 <<<${file})"
      done < ${file_list_file}

      # Save the final group to a text file
      split_file_name="${config_dir}/${split_file_prefix}_${group_num}${split_file_suffix}"
      printf "%s\n" "${file_list[@]}" > "${split_file_name}"
      logf "${split_log_tag}" "Split $( cat "${split_file_name}" | wc -l) files into file list file: ${split_file_name}"

    else
      if [ "$split_mode" = "bytes_avg" ]; thenS
        #calculate the max count using average file size 
        total_size=$(du -d 0 "${split_source_dir}")
        avg_file_size=$(($total_size / $total_files))
        max_count=$(($max_size / $avg_file_size))
        # remove decimal places
        max_count=$(echo "${max_count%.*}")
      else
        max_count=$(echo "${max_size}")
      fi

      # split file list into batches of max_count files. 
      # Split file list files will match the format:
      #  ${config_dir}/${tar_filename_start}_${split_file_suffix}_${split_suffix}
      # where split_suffix is a 6 character string starting from aaaaaaa
      split_file_name="${config_dir}/${tar_filename_start}_${split_file_suffix}_"
      logf "${split_log_tag}" "Spliting ${total_files} files into batches of size ${max_count} to split file starting from ${split_file_name}aaaaaaa"
      split "${file_list_file}" -a 7 -d -l ${max_count} "${split_file_name}"
    fi
 logf "${split_log_tag}" "Split files done"
}

# # Set the target directory
# target_dir="/path/to/directory"

# # Set the config directory
# config_dir="/path/to/temp/directory"

# # Set the minimum modification date and maximum total file size
# min_file_mod_time=1609459200  # January 1, 2021 in Unix timestamp format
# max_file_mod_time=1640995200  # January 1, 2022 in Unix timestamp format

#  # Optional - Set max file size, save into another tar if total size will exceed the thershold kB (5GB)
# max_file_type="bytes_avg"
# max_file_size="5242880"
#

# split_file_prefix="group-"
# split_file_suffix=".txt"

# # Call the function
# split_files "$source_dir" "$config_dir" "$min_file_mod_time" "$max_file_mod_time" "$max_file_type" "$max_size" "$split_file_prefix" "$split_file_suffix"
