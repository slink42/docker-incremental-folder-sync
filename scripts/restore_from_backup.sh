#!/bin/bash

# Define the function
restore_from_backup() {

  # Set the target directory
  target_dir=$1
  config_dir=$2
  restore_rclone_remote=${3:-"SECURE_BACKUP"}
  restore_rclone_path=${4:-""}
  # min disk space, dont extract if lower that thershold kB (50GB)
  min_disk_space=${5:-"52428800"}
  temp_dir=${6:-$1}
  mode=${7:-"stream extract"}

  # Define the text file were a record of the files that have been porcessed will be maintained
  processed_files_file="${config_dir}/processed_tar_files.txt"

  # If the processed_files_file doesn't exist create an empty one
  [ -d "$config_dir" ] || mkdir "$config_dir"
  [ -f "$processed_files_file" ] || touch "$processed_files_file"

  # check for rclone config in config_dir
  [ -f "${config_dir}/rclone.conf" ] && restore_rclone_config="${config_dir}/rclone.conf" && echo "using config found in config dir: ${restore_rclone_config}" || restore_rclone_config=""
  restore_rclone_config=${restore_rclone_config:-$(rclone config file | grep -v "stored at:")}

  [ -d "${target_dir}" ] || (mkdir -p "${target_dir}" && echo "extract directory doesn't exit. Creating folder: ${target_dir}")

    # Use the rclone command to list the tar files in the remote. You will need to specify the name of the remote, as well as the path to the directory where the tar files are stored.
    tar_files=$(rclone lsf "${restore_rclone_remote}:${restore_rclone_path}" --config "${restore_rclone_config}"  --filter "+ *.tar.gz" --filter "+ *.tar" --filter "- *" | while read line; do   echo "${line// /\\ }"; done)

  echo "$(date) - starting restore_from_backup"
  echo "source: ${restore_rclone_remote}:${restore_rclone_path}"
  echo "target: ${target_dir}"
  echo "config dir: ${config_dir}"

  # Iterate through the list of tar files and select the next one that has not yet been processed. You can use a simple text file to keep track of which tar files have already been processed.
  echo "$tar_files" | while read line; do
    echo "Checking ${line}"
    if grep -q "$line" "$processed_files_file"; then
      continue
    fi

    # tar file has not yet been processed, so copy it to the local path
    # and extract its contents
    tar_file="$line"

    # Check how much free disk space there is
    disk_avail=$(df -l  "${target_dir}" | grep / | awk  -F' ' '{print $4}')

    if [[ $disk_avail -lt $min_disk_space ]]; then
      echo "disk free space ($disk_avail) is less than the minimum specified ($min_disk_space bytes). Terminating tar extraction before starting ${tar_file}"
      exit 1
    fi

    echo "$(date) - Starting ${tar_file}"

    # Use rclone to copy and extract the tar file to the local path:
    # if rclone cat "${restore_rclone_remote}:${restore_rclone_path}${tar_file}" | pv -s $(echo '{"count":1,"bytes":33966099957}' | sed -r 's/.*"bytes":([^"]+)}.*/\1/') | tar -C "${target_dir}" -xZf -; then
    if [ "${mode}" = "stream extract" ] && rclone cat "${restore_rclone_remote}:${restore_rclone_path}/${tar_file}" --low-level-retries 50  --config "${restore_rclone_config}" | pv -s $(rclone size --json "${restore_rclone_remote}:${restore_rclone_path}/${tar_file}" | sed -r 's/.*"bytes":([^"]+)}.*/\1/') |  gzip -dc | tar -xf - -C "${target_dir}"; then

      echo "$(date) - Successfully completed extracting ${tar_file}"

      # Add the tar file to the list of processed files:
      echo "$tar_file" >> $processed_files_file
    else
      if [ "$mode" = "stream extract" ]; then
        echo "$(date) - Error code returned when extracting from cloud. ${tar_file}"
        echo "Retrying from with staging tar file downloaded to local path prior to extraction."
      else
        echo "Skipped steam extract, staging tar file downloading to local path prior to extraction."
      fi
      
      
      rclone copy --low-level-retries 50  --config "${restore_rclone_config}" --progress "${restore_rclone_remote}:${restore_rclone_path}/${tar_file}" "${temp_dir}"

      if pv "${temp_dir}/${tar_file}" | gzip -dc | tar -xf - -C "${target_dir}"; then
        echo "$(date) - Successfully completed extracting ${tar_file}"
        # Add the tar file to the list of processed files:
        echo "$tar_file" >> $processed_files_file
        rm "${temp_dir}/${tar_file}"
      else
        echo "$(date) - Error code returned when copying to local path or extracting file contents. ${temp_dir}/${tar_file}"
        break
      fi
    fi
  done
  echo "$(date) - completed restore_from_backup"
}

# # Set the target directory
# target_dir="/path/to/target/directory"

# # Set the config directory
# config_dir="/path/to/config/directory"

# # Set the rclone source
# rclone_remote="remote_name"
# rclone_path="path/to/source/directory"

# # ptional - Set min disk space, dont extract if lower that thershold kB, defualt value is 52428800 (50GB)
#  min_disk_space="52428800"

# # Optional - Set the temp directory
# temp_dir="/tmp"

# # Call the function
# restore_from_backup "$target_dir" "$config_dir" "$rclone_remote" "$rclone_path" "$min_disk_space" "$temp_dir"