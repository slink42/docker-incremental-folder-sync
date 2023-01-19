#!/bin/bash

# import split_files function
source /usr/local/bin/split_files.sh

# Define the function
save_to_backup() {

  # Set the target directory
  source_dir=$1
  config_dir=$2
  restore_rclone_remote=${3:-"SECURE_BACKUP"}
  restore_rclone_path=${4:-""}
  # max file size, save into another tar if total size will exceed the thershold kB (5GB)
  max_file_size=${5:-"5242880"}
  temp_dir=${6:-$1}
  # mode=${7:-"stream extract"}

  # If the config_dir doesn't exist create it
  [ -d "$config_path" ] || mkdir "$config_path"
  file_list_file="${config_dir}/source_files.txt"

  # check for rclone config in config_dir
  ([ -f "${config_dir}/rclone.conf" ] && restore_rclone_config="${config_dir}/rclone.conf" && echo "using config found in cofig dir: ${restore_rclone_config}") || restore_rclone_config=""
  restore_rclone_config=${restore_rclone_config:-$(rclone config file | grep -v "stored at:")}

  [ -d "${target_dir}" ] || (echo "Aborting, source directory doesn't exit: ${source_dir}")

  # Use the rclone command to list the tar files in the remote. You will need to specify the name of the remote, as well as the path to the directory where the tar files are stored.
  tar_files=$(rclone lsf "${restore_rclone_remote}:${restore_rclone_path}" --config "${restore_rclone_config}"  --filter "+ *.tar.gz" --filter "+ *.tar" --filter "- *" | while read line; do   echo "${line// /\\ }"; done)

  echo "$(date) - starting save_to_backup"
  echo "source: ${restore_rclone_remote}:${restore_rclone_path}"
  echo "target: ${source_dir}"

  
  
  # Iterate through the list of tar files and select the next one that has not yet been processed. You can use a simple text file to keep track of which tar files have already been processed.
  last_tar_file=$(echo "$tar_files" | sort | tail -n 1)
  last_tar_date=$(echo $last_tar_file | cut -d "." -f1 | cut -d "_" -f5)
  
  last_tar_date=${last_tar_date:-"1970-01-01 0000"}
  new_tar_date=${current_datetime}

  max_file_mod_time=$(date --date="${new_tar_date}") 
  min_file_mod_time=$(date --date="${last_tar_date}")

  new_tar_file_no_ext="${tar_filename_start}_${last_tar_date}_to_${new_tar_date}"


  find "./Metadata" "./Media" -type f  -newermt "${min_file_mod_time}" ! -newermt "${max_file_mod_time}" > "${file_list_file}"
  echo "$(date) Found $( cat "${file_list_file}" | wc -l) files. Adding to tar ${new_tar_file_no_ext}"

  
  
  # # Set the target directory
# target_dir="/path/to/directory"

# # Set the minimum modification date and maximum total file size
# min_date=1609459200  # January 1, 2021 in Unix timestamp format
# max_date=1640995200  # January 1, 2022 in Unix timestamp format
# max_size=53687091200  # 50GB in bytes

split_file_prefix="group-"
split_file_suffix=".txt"

# Call the function
rm -f "${config_dir}/${split_file_prefix}*${split_file_suffix}"
split_files "$target_dir" "$temp_dir" "$min_date" "$max_date" "$max_size" "$split_file_prefix" "$split_file_suffix"


#   split "${file_list_file}" -a 3 -d -l 100000 "${config_dir}/split_file_list_"

# for split_list_file in $(ls "${config_dir}/split_file_list_*")
# do
#     split_number="${split_list_file##*_}"
#     split_new_tar_file="${new_tar_file_no_ext}_${split_number}.tar.gz"
#     echo "$(date) Adding $( cat "${split_list_file}" | wc -l) files to tar ${split_new_tar_file}"
# #     echo "$(date) Adding $( cat "${split_list_file}" | wc -l) files to tar ${split_new_tar_file}" >> "$LOG_FILE"
#     tar --create -z --file="${split_new_tar_file}" --files-from="${split_list_file}"
#     stat "${split_new_tar_file}"
# #
#     # if  gzip -v -t "${split_new_tar_file}" 2>  /dev/null; then
#     #     echo "tar gzip compression tested ok, moving ${split_new_tar_file} to dir ${TAR_BACKUP_FOLDER}"
# #         mv "$split_new_tar_file" "$TAR_BACKUP_FOLDER/"
# #         echo "$(date) ****** Finished image Libary tar file load ******" >> "$LOG_FILE"
# #         echo "" >> "$LOG_FILE"
# #         echo "files added to tar:" >> "$LOG_FILE"
# #         echo "" >> "$LOG_FILE"
# #         cat "$split_list_file" >> "$LOG_FILE"backup
# #         mv "$LOG_FILE" "$TAR_BACKUP_FOLDER/"
# #         rm "$split_list_file"
#     else
# #         echo "error - tar gzip compression failed when tested: removing ${split_new_tar_file}" >> "$LOG_FILE"
# #         echo "error - tar gzip compression failed when tested, removing ${split_new_tar_file}"
# #
# #         echo "$(date) ****** Finished image Libary tar file rebuild ******"  >> "$LOG_FILE"
# #
# #         rm "$split_new_tar_file"
# #         #break
# #     fi
#   done


  echo "$(date) - completed save_to_backup"
}

# # Set the target directory
# source_dir="/path/to/target/directory"

# # Set the config directory
# config_dir="/path/to/config/directory"

# # Set the rclone source
# rclone_remote="remote_name"
# rclone_path="path/to/source/directory"

#  # Optional - Set max file size, save into another tar if total size will exceed the thershold kB (5GB)
#  max_file_size=${5:-"5242880"}

# # Optional - Set the temp directory
# temp_dir="/tmp"

# # Call the function
# save_to_backup "$source_dir" "$config_dir" "$rclone_remote" "$rclone_path" "$max_file_size" "$temp_dir"