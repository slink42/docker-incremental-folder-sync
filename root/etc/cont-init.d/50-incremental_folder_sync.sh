#!/usr/bin/with-contenv bash

# EXTRACTED_FILES_PATH=/mnt/c/Users/stuar/libfiles
# CONFIG_PATH=/mnt/c/Users/stuar/config
# RCLONE_REMOTE=secure_backup_rw
# RCLONE_PATH=plex_library_backup/meta
# MODE=BACKUP/RESTORE


# Define the local path where the extracted tar files will be saved using the EXTRACTED_FILES_PATH environment variable:
source_dir=${SOURCE_FILES_PATH:-"$target_dir"}
target_dir=${EXTRACTED_FILES_PATH:-"$source_dir"}
config_dir=${CONFIG_PATH:-"/config"}
temp_dir=${TMP_PATH:-"${target_dir}"}
mode=${MODE:-"RESTORE"} #BACKUP/RESTORE
source_dir_subfolders=${SOURCE_SUBFOLDERS:-"."} # Space separated list of subfolders in source_dir to include in backup

# date and time strings
current_datetime_format="%Y-%m-%d %H%M"
current_datetime=$(date +"${current_datetime_format}")
current_date=$(date +"%Y-%m-%d")
current_time=$(date +"%H%M")

# start of tar files used for backups
tar_filename_start=${TAR_FILENAME_START:-"library_images"}

# min disk space, dont extract if lower that thershold Kb (50GB)
min_disk_space=${MIN_DISK_SPACE:-"52428800"}


# Define the rclone remote and file path within the remote tot he folder containing tar files:
rclone_remote=${RCLONE_REMOTE:-"SECURE_BACKUP"}
rclone_path=${RCLONE_PATH:-""}


# Define the max nuber of fiels to include for backup tar file, saves remaining into other tar(s) if total file count will exceed the thershold
max_file_type="count"
max_file_size=${MAX_TAR_FILE_FILE_COUNT:-"5000000000"}
if [ -z "$MAX_TAR_FILE_FILE_COUNT" ] && ! [ -z "$MAX_TAR_FILE_SPACE" ]; then
  # Define the max size for backup tar file, saves remaining into other tar(s) if total size will exceed the thershold kB (5GB)
  max_file_size=${MAX_TAR_FILE_SPACE:-"5000000000"}
  max_file_type="bytes"
fi

##########################################################################################################################
##############################################      RESTORE      #########################################################
##########################################################################################################################

if [ "${mode}" = "RESTORE" ]; then
  restore_command="restore_from_backup \"$target_dir\" \"$config_dir\" \"$rclone_remote\" \"$rclone_path\" \"$min_disk_space\" \"$temp_dir\""
  echo $restore_command

  # Create target_dir/config_dir/temp_dir if it doesn't exist yet
  [ -d "${target_dir}" ] || mkdir -p "${target_dir}"
  [ -d "${config_dir}" ] || mkdir -p "${config_dir}"
  [ -d "${temp_dir}" ]   || mkdir -p "${temp_dir}"

  # set required permissions
  chown abc:abc -R \
    "${config_dir}"
  chown abc:abc \
    "${target_dir}" "${temp_dir}" 

  exec s6-setuidgid abc \
    /usr/local/bin/restore_from_backup.sh "$target_dir" "$config_dir" "$rclone_remote" "$rclone_path" "$min_disk_space" "$temp_dir"
  
fi


##########################################################################################################################
##############################################      BACKUP      #########################################################
##########################################################################################################################


if [ "${mode}" = "BACKUP" ]; then
 
  set -m # Enable Job Control
  set -o xtrace # Echo commands run

 # Start a backup thread for each subfolder in source_dir_subfolders
  for folder in $source_dir_subfolders; do
    folder_tar_filename_start="${tar_filename_start}"
    if ! [ ${folder} = "." ]; then
      folder_tar_filename_start="${folder_tar_filename_start}_${folder,,}"
    fi
    echo "starting folder backup: ${folder}"
    /usr/local/bin/save_to_backup.sh "$source_dir" "$config_dir" "$rclone_remote" "$rclone_path" "$temp_dir" "$max_file_size" "$max_file_type" "./${folder}" "${folder_tar_filename_start}" "${log_file}" &
  done

# Wait for backup threads to complete
  echo "waiting for backup to finish"
  # Wait for all parallel jobs to finish
  while [ 1 ]; do fg 2> /dev/null; [ $? == 1 ] && break; done
  echo "backup done"

fi