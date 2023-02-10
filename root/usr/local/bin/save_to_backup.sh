#!/bin/bash

# import split_files function
source /usr/local/bin/split_files.sh


# Define the function
function save_to_backup() {

  # Set the target directory
  source_dir=$1
  config_dir=$2
  rclone_remote=${3:-"SECURE_BACKUP"}
  rclone_path=${4:-""}

  temp_dir=${5:-"$1/backup"}
  
  # max_file_type=count
  # save into another tar if total file ocunt will exceed the threshold of max_file_size files
  #
  #
  # max_file_type=bytes
  # save into another tar if total size will exceed the threshold of max_file_size bytes. Waring, this is VERY SLOw compared to count.
  max_file_type=${7:-"count"} # count/bytes
  max_file_size=${6:-"1000000"} # 1000000 files
  if [ ${max_file_type} == "bytes" ]; then
    max_file_size=${6:-"5000000000"} # 5GB
  fi

  # relative subfolder to path to include in backup
  path_filter=${8:-"."}

  # start of tar files used for library images backup
  tar_filename_start=${9:-"backup"}
  split_file_suffix=".txt"

  # date and time strings
  current_datetime_format="%Y-%m-%d %H%M"
  current_datetime=$(date +"${current_datetime_format}")
  current_date=$(date +"%Y-%m-%d")
  current_time=$(date +"%H%M")

  log_file=${10:-"${config_dir}/save_to_backup_${current_datetime}.log"}
  log_file_base=$(basename "${log_file}")
  log_file_base=$(echo "${log_file_base%.*}")

  # If the temp_dir doesn't exist create it
  [ -d "$temp_dir" ] || mkdir "$temp_dir"

  # If the config_dir doesn't exist create it
  [ -d "$config_dir" ] || mkdir "$config_dir"

  file_list_file="${config_dir}/source_files.txt"

  # check for rclone config in config_dir
  ([ -f "${config_dir}/rclone.conf" ] && restore_rclone_config="${config_dir}/rclone.conf" && echo "using config found in config dir: ${restore_rclone_config}") || restore_rclone_config=""
  restore_rclone_config=${restore_rclone_config:-$(rclone config file | grep -v "stored at:" | grep ".conf")}
  [ -f "${restore_rclone_config}" ] && \
    (echo "Configuration file doesn't exist, but rclone will use this path: /config/rclone.conf") && \
    restore_rclone_config="/config/rclone.conf"

  [ -d "${source_dir}" ] || (echo "Aborting, source directory doesn't exit: ${source_dir}")

  # Make sure tar target dir exists by creating it
  rclone mkdir "${rclone_remote}:${rclone_path}"

  # Use the rclone command to list the tar files in the remote. You will need to specify the name of the remote, as well as the path to the directory where the tar files are stored.
  tar_files=$(rclone lsf "${rclone_remote}:${rclone_path}" --config "${restore_rclone_config}"  --filter "+ *.tar.gz" --filter "+ *.tar" --filter "- *" | while read line; do   echo "${line// /\\ }"; done)

  echo "$(date) - starting save_to_backup"
  echo "source: ${rclone_remote}:${rclone_path}"
  echo "target: ${source_dir}"

  # Iterate through the list of tar files and select the next one that has not yet been processed. You can use a simple text file to keep track of which tar files have already been processed.
  last_tar_file=$(echo "$tar_files" | sort | tail -n 1)
  last_tar_date=$(echo $last_tar_file | cut -d "." -f1 | cut -d "_" -f5)
 
  last_tar_date=${last_tar_date:-"1970-01-01 0000"}
  new_tar_date=${current_datetime}

  max_file_mod_time=$(date --date="${new_tar_date}") 
  min_file_mod_time=$(date --date="${last_tar_date}")

  new_tar_file_no_ext="${tar_filename_start}_${last_tar_date}_to_${new_tar_date}"
  echo "$(date) New tar files name prefix ${new_tar_file_no_ext}"
  
  cd "${source_dir}"

  # find "./Metadata" "./Media" -type f  -newermt "${min_file_mod_time}" ! -newermt "${max_file_mod_time}" > "${file_list_file}"
  # echo "$(date) Found $( cat "${file_list_file}" | wc -l) files. Adding to tar ${new_tar_file_no_ext}"

  # # Set the target directory
  # source_dir="/path/to/directory"

  # # Set the minimum modification date and maximum total file size
  # min_date=1609459200  # January 1, 2021 in Unix timestamp format
  # max_date=1640995200  # January 1, 2022 in Unix timestamp format
  # max_size=53687091200  # 50GB in bytes

  

  ## TODO
  # for subfolder in $(ls "${source_dir}"); do

  # Call the function
  rm ${config_dir}/${tar_filename_start}*${split_file_suffix}* 2>/dev/null
  
  if [ "${max_file_type}" == "bytes" ]; then
    split_files "${path_filter}" "${config_dir}" "${min_date}" "${max_date}" "${max_size}" "${tar_filename_start}" "${split_file_suffix}"
  else
    split "${file_list_file}" -a 3 -d -l ${max_file_size} "${config_dir}/${tar_filename_start}_${split_file_suffix}_"
  fi

  for split_list_file in $(ls ${config_dir}/${tar_filename_start}_*${split_file_suffix}*)
  do
      split_number="${split_list_file##*_}"
      
      # remove file extension if there is one
      split_number=$(echo "${split_number%.*}")

      split_new_tar_file="${new_tar_file_no_ext}_${split_number}.tar.gz"

      echo "$(date) Adding $( cat "${split_list_file}" | wc -l) files to tar ${split_new_tar_file}"
      echo "$(date) Adding $( cat "${split_list_file}" | wc -l) files to tar ${split_new_tar_file}" >> "${log_file}"

      tar --create -z --file="${split_new_tar_file}" --files-from="${split_list_file}"

      stat "${split_new_tar_file}"
      stat "${split_new_tar_file}" >> "${log_file}"

      if  gzip -v -t "${split_new_tar_file}" 2>  /dev/null; then
          echo "tar gzip compression tested ok, moving ${split_new_tar_file} to dir ${temp_dir}"
          # Move tar file to tmp dir for syncing to rclone remote
          mv "${split_new_tar_file}" "${temp_dir}/"
          # Save file list as log
          mv "${split_list_file}" "${temp_dir}/${log_file_base}_split_${split_number}.done"
      else
          echo "error - tar gzip compression failed when tested: removing ${split_new_tar_file}" >> "${log_file}"
          echo "error - tar gzip compression failed when tested, removing ${split_new_tar_file}"

          # Save file list as log
          mv "${split_list_file}" "${temp_dir}/${log_file_base}_split_${split_number}.failed"

          #break
      fi
      echo "$(date) ****** Finished image Libary tar file rebuild for ${split_new_tar_file} ******"  >> "${log_file}"
      echo "" >> "${log_file}"
      echo "" >> "${log_file}"
    done


    echo "$(date) ****** Syncing backup tar files to rclone remote: "${rclone_remote}:${rclone_path}" ******"
    echo "$(date) ****** Syncing backup tar files to rclone remote: "${rclone_remote}:${rclone_path}" ******"  >> "${log_file}"

    rclone sync "${temp_dir}" "${rclone_remote}:${rclone_path}" \
      --config "${restore_rclone_config}" \
      --progress \
      --filter "+ ${new_tar_file_no_ext}_*.tar.gz" \
      --filter "- *"

  echo "$(date) - completed save_to_backup"
  echo "$(date) - completed save_to_backup" >> "${log_file}"
  
  mv "${log_file}" "${temp_dir}/"
}

# # Set the target directory
# source_dir="/path/to/target/directory"
source_dir="$1"

# # Set the config directory
# config_dir="/path/to/config/directory"
config_dir"$2"

# # Set the rclone source
# rclone_remote="remote_name"
# rclone_path="path/to/source/directory"
rclone_remote="$3"
rclone_path="$4"

#  # Optional - Set max file size, save into another tar if total size will exceed the thershold kB (5GB)
#  max_file_size=${5:-"5242880"}
max_file_size="$5"

# # Optional - Set the temp directory
# temp_dir="/tmp"
temp_dir="$6"

source_dir="$1"
config_dir="$2"
rclone_remote="$3"
rclone_path="$4"
temp_dir="$5"
max_file_size="$6"
max_file_type="$7"
path_filter="$8"
tar_filename_start="$9"
log_file="${10}"

# Call the function
save_to_backup "${source_dir}" "${config_dir}" "${rclone_remote}" "${rclone_path}" "${temp_dir}" "${max_file_size}" "${max_file_type}" "${path_filter}" "${tar_filename_start}" "${log_file}"
