# Kworkflow treats this script as a plugin for installing a new Kernel or
# module in a target system. It is essential to highlight that this file
# follows an API that can be seen in the "deploy.sh" file, if you make any
# change here, you have to do it inside the install_modules() and
# install_kernel().
#
# Note: We use this script for Debian based distros

# Debian package names
declare -ag required_packages=(
  'rsync'
  'screen'
)

# Debian package manager command
declare -g package_manager_cmd='apt-get install -y'

function generate_debian_temporary_root_file_system()
{
  local name="$1"
  local target="$2"
  local flag="$3"
  local cmd="update-initramfs -c -k"

  cmd+=" $name"

  if [[ "$target" == 'local' ]]; then
    cmd="sudo -E $cmd"
  fi

  if [[ "$target" != 'vm' ]]; then
    # Update initramfs
    cmd_manager "$flag" "$cmd"
  else
    generate_rootfs_with_libguestfs "$flag" "$name"
  fi
}

function generate_rootfs_with_libguestfs()
{
  local flag="$1"
  local name="$2"
  # We assume Debian as a default option
  local mount_root=': mount /dev/sda1 /'
  local mkdir_init=': mkdir-p /etc/initramfs-tools'
  local cmd_init="update-initramfs -c -k $name"

  flag=${flag:-'SILENT'}

  if [[ ! -f "${configurations[qemu_path_image]}" ]]; then
    complain "There is no VM in ${configurations[qemu_path_image]}"
    return 125 # ECANCELED
  fi

  # For executing libguestfs commands we need to umount the vm
  if [[ $(findmnt "${configurations[mount_point]}") ]]; then
    vm_umount
  fi

  cmd="guestfish --rw -a ${configurations[qemu_path_image]} run \
      $mount_root : command '$cmd_init'"

  warning " -> Generating rootfs $name on VM. This can take a few minutes."

  cmd_manager "$flag" 'sleep 0.5s'
  {
    cmd_manager "$flag" "$cmd"
  } 1> /dev/null # No visible stdout but still shows errors

  # TODO: The below line is here for test purpose. We need a better way to
  # do that.
  [[ "$flag" == 'TEST_MODE' ]] && printf '%s\n' "$cmd"

  say 'Done.'

  return 0
}
