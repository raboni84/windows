source "virtualbox-iso" "bootstrap" {
  headless             = true
  guest_os_type        = "Windows10_64"
  disk_size            = 524288
  format               = "ovf"
  hard_drive_interface = "sata"
  iso_checksum         = "none"
  iso_interface        = "sata"
  iso_url              = "win10.iso"
  shutdown_command     = "shutdown /s /t 10 /f /d p:4:1 /c Packer_Provisioning_Shutdown"
  guest_additions_mode = "attach"
  output_directory     = "output/bootstrap"
  output_filename      = "../windows10-bootstrap-x86_64"
  floppy_files         = ["Autounattend.xml", "configure.ps1"]
  communicator         = "winrm"
  winrm_username       = "user"
  winrm_password       = "resu"
  winrm_insecure       = true
  vboxmanage           = [["modifyvm", "{{ .Name }}", "--chipset", "ich9", "--cpus", "2", "--memory", "2048", "--graphicscontroller", "vboxsvga", "--accelerate3d", "on", "--accelerate2dvideo", "on", "--vram", "256", "--pae", "on", "--nested-hw-virt", "on", "--paravirtprovider", "kvm", "--hpet", "on", "--hwvirtex", "on", "--largepages", "on", "--boot1", "dvd", "--boot2", "none", "--boot3", "none", "--boot4", "none"]]
  vboxmanage_post      = [["modifyvm", "{{ .Name }}", "--boot1", "disk", "--boot2", "none", "--boot3", "none", "--boot4", "none"]]
  vm_name              = replace(timestamp(), ":", "꞉") # unicode replacement char for colon
}

build {
  sources = ["source.virtualbox-iso.bootstrap"]
}
