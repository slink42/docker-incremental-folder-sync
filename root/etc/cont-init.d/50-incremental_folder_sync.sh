#!/bin/bash

# EXTRACTED_FILES_PATH=/mnt/c/Users/stuar/libfiles
# CONFIG_PATH=/mnt/c/Users/stuar/config
# RCLONE_REMOTE=secure_backup_rw
# RCLONE_PATH=plex_library_backup/meta
# MODE=BACKUP/RESTORE


# import restore_from_backup function
source /usr/local/bin/restore_from_backup.sh


# Define the local path where the extracted tar files will be saved using the EXTRACTED_FILES_PATH environment variable:
target_dir=$EXTRACTED_FILES_PATH
config_dir=${CONFIG_PATH:-"/config"}
temp_dir=${TMP_PATH:-"${target_dir}"}
mode=${MODE:-"RESTORE"} #BACKUP/RESTORE

# date and time strings
current_datetime_format="%Y-%m-%d %H%M"
current_datetime=$(date +"${current_datetime_format}")
current_date=$(date +"%Y-%m-%d")
current_time=$(date +"%H%M")

# start of tar files used for backups
tar_filename_start=${TAR_FILENAME_START:-"library_images"}

# min disk space, dont extract if lower that thershold kB (50GB)
min_disk_space=${MIN_DISK_SPACE:-"52428800"}

# Define the rclone remote and file path within the remote tot he folder containing tar files:
rclone_remote=${RCLONE_REMOTE:-"SECURE_BACKUP"}
rclone_path=${RCLONE_PATH:-""}


##########################################################################################################################
##############################################      RESTORE      #########################################################
##########################################################################################################################

if [ "${mode}" = "RESTORE" ]; then
  restore_command="restore_from_backup \"$target_dir\" \"$config_dir\" \"$rclone_remote\" \"$rclone_path\" \"$min_disk_space\" \"$temp_dir\""
  echo $restore_command
  restore_from_backup "$target_dir" "$config_dir" "$rclone_remote" "$rclone_path" "$min_disk_space" "$temp_dir"
  


#   rclone_config=${RCLONE_CONFIG:-""${config_dir}"/rclone.conf"}

# # If rclone config found in custom location, define argument to reference it to include in rclone commands
# if [ -f "$rclone_config" ]; then
#     echo "using rclone config found in path: $rclone_config"
# else
#     rclone_config=$(rclone config file | grep -v "stored at:")
#     echo "using default rclone config path: $rclone_config"
# fi

# # Define the text file were a record of the files that have been porcessed will be maintained
# processed_files_file="${config_dir}/processed_tar_files.txt"

# # If the processed_files_file doesn't exist create an empty one
# [ -d "$config_dir" ] || mkdir "$config_dir"
# [ -f "$processed_files_file" ] || touch "$processed_files_file"

# # Use the rclone command to list the tar files in the remote. You will need to specify the name of the remote, as well as the path to the directory where the tar files are stored.
# tar_files=$(rclone lsf ${rclone_remote}:${rclone_path} --config "${rclone_config}"  --filter "+ *.tar.gz" --filter "+ *.tar" --filter "- *" | while read line; do   echo "${line// /\\ }"; done)

  # [ -d "${target_dir}" ] || (mkdir -p "${target_dir}" && echo "extract directory doesn't exit. Creating folder: ${target_dir}")
  # # Iterate through the list of tar files and select the next one that has not yet been processed. You can use a simple text file to keep track of which tar files have already been processed.
  # echo "$tar_files" | while read line; do
  #     echo ${line}                                                                                                                                                                                                                   echo "$line"
  #   if grep -q "$line" "$processed_files_file"; then
  #     continue
  #   fi

  #   # tar file has not yet been processed, so copy it to the local path
  #   # and extract its contents
  #   tar_file="$line"

  #   # Check how much free disk space there is
  #   disk_avail=$(df -l  "${target_dir}" | grep / | awk  -F' ' '{print $4}')

  #   if [[ $disk_avail -lt $min_disk_space ]]; then
  #     echo "disk free space ($disk_avail) is less than the minimum specified ($min_disk_space bytes). Terminating tar extraction before starting ${tar_file}"
  #     break
  #   fi

  #   echo "Starting ${tar_file}"

  #   # Use rclone to copy and extract the tar file to the local path:
  #   # if rclone cat "${rclone_remote}:${rclone_path}${tar_file}" | pv -s $(echo '{"count":1,"bytes":33966099957}' | sed -r 's/.*"bytes":([^"]+)}.*/\1/') | tar -C "${target_dir}" -xZf -; then
  #   if rclone cat "${rclone_remote}:${rclone_path}${tar_file}" --low-level-retries 50  --config "${rclone_config}" | pv -s $(rclone size --json "${rclone_remote}:${rclone_path}${tar_file}" | sed -r 's/.*"bytes":([^"]+)}.*/\1/') |  gzip -dc | tar -xf - -C "${target_dir}"; then

  #     echo "Successfully completed extracting ${tar_file}"

  #     # Add the tar file to the list of processed files:
  #     echo "$tar_file" >> $processed_files_file
  #   else
  #     echo "Error code returned when extracting from cloud. ${tar_file}"
      
  #     echo "Retrying from with staging tar file locally first."
  #     rclone copy --low-level-retries 50  --config "${rclone_config}" --progress "${rclone_remote}:${rclone_path}${tar_file}" "${target_dir}"

  #     if pv "${target_dir}/${tar_file}" | gzip -dc | tar -xf - -C "${target_dir}"; then
  #       echo "Successfully completed extracting ${tar_file}"
  #       # Add the tar file to the list of processed files:
  #       echo "$tar_file" >> $processed_files_file
  #     else
  #       echo "Error code returned when copying to local path or extracting file contents. ${target_dir}/${tar_file}"
  #       break
  #     fi
  #   fi
  # done
fi


##########################################################################################################################
##############################################      BACKUP      #########################################################
##########################################################################################################################


# if [ "${mode}" = "BACKUP" ]; then

# rclone_config=${RCLONE_CONFIG:-""${config_dir}"/rclone.conf"}

# # If rclone config found in custom location, define argument to reference it to include in rclone commands
# if [ -f "$rclone_config" ]; then
#     echo "using rclone config found in path: $rclone_config"
# else
#     rclone_config=$(rclone config file | grep -v "stored at:")
#     echo "using default rclone config path: $rclone_config"
# fi

# # Define the text file were a record of the files that have been porcessed will be maintained
# processed_files_file="${config_dir}/processed_tar_files.txt"

# # If the processed_files_file doesn't exist create an empty one
# [ -d "$config_dir" ] || mkdir "$config_dir"
# [ -f "$processed_files_file" ] || touch "$processed_files_file"

# # Use the rclone command to list the tar files in the remote. You will need to specify the name of the remote, as well as the path to the directory where the tar files are stored.
# tar_files=$(rclone lsf ${rclone_remote}:${rclone_path} --config "${rclone_config}"  --filter "+ *.tar.gz" --filter "+ *.tar" --filter "- *" | while read line; do   echo "${line// /\\ }"; done)




#   # Iterate through the list of tar files and select the next one that has not yet been processed. You can use a simple text file to keep track of which tar files have already been processed.
#   last_tar_file=$(echo "$tar_files" | sort | tail -n 1)
#   last_tar_date=$(echo $last_tar_file | cut -d "." -f1 | cut -d "_" -f5)
  
#   last_tar_date=${last_tar_date:-"1970-01-01 0000"}
#   new_tar_date=${current_datetime}

#   max_file_mod_time=$(date --date="${new_tar_date}") 
#   min_file_mod_time=$(date --date="${last_tar_date}")

#   new_tar_file_no_ext="${tar_filename_start}_${last_tar_date}_to_${new_tar_date}"

#   file_list_file="${config_dir}/source_files.txt"

#   find "./Metadata" "./Media" -type f  -newermt "${min_file_mod_time}" ! -newermt "${max_file_mod_time}" > "${file_list_file}"
#   echo "$(date) Found $( cat "${file_list_file}" | wc -l) files. Adding to tar ${new_tar_file_no_ext}"

  
#   rm -f "${config_dir}/split_file_list_*"
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
# fi