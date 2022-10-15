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
  guest_additions_mode = "disable"
  output_directory     = "output/bootstrap"
  output_filename      = "../windows10-bootstrap-x86_64"
  floppy_files         = ["Autounattend.xml", "configure.ps1"]
  communicator         = "winrm"
  winrm_username       = "user"
  winrm_password       = "resu"
  winrm_insecure       = true
  vboxmanage           = [["modifyvm", "{{ .Name }}", "--chipset", "ich9", "--cpus", "2", "--memory", "2048", "--graphicscontroller", "vboxsvga", "--accelerate3d", "off", "--accelerate2dvideo", "off", "--vram", "256", "--pae", "on", "--nested-hw-virt", "on", "--paravirtprovider", "kvm", "--hpet", "on", "--hwvirtex", "on", "--largepages", "on", "--boot1", "dvd", "--boot2", "none", "--boot3", "none", "--boot4", "none"], ["storageattach", "{{ .Name }}", "--storagectl", "SATA Controller", "--port", "20", "--device", "0", "--type", "dvddrive", "--medium", "/usr/lib/virtualbox/additions/VBoxGuestAdditions.iso"]]
  vboxmanage_post      = [["modifyvm", "{{ .Name }}", "--memory", "4096", "--boot1", "disk", "--boot2", "none", "--boot3", "none", "--boot4", "none"], ["storageattach", "{{ .Name }}", "--storagectl", "SATA Controller", "--port", "20", "--device", "0", "--type", "dvddrive", "--medium", "none"]]
  vm_name              = replace(timestamp(), ":", "꞉") # unicode replacement char for colon
}

source "virtualbox-ovf" "debuggee" {
  headless             = true
  format               = "ovf"
  shutdown_command     = "shutdown /s /t 10 /f /d p:4:1 /c Packer_Provisioning_Shutdown"
  guest_additions_mode = "disable"
  output_directory     = "output/debuggee"
  output_filename      = "../windows10-debuggee-x86_64"
  source_path          = "output/windows10-bootstrap-x86_64.ovf"
  floppy_files         = ["debuggee.ps1"]
  communicator         = "winrm"
  winrm_username       = "user"
  winrm_password       = "resu"
  winrm_insecure       = true
  vboxmanage_post      = [["modifyvm", "{{ .Name }}", "--cableconnected1", "off", "--cableconnected2", "on"]]
  vm_name              = replace(timestamp(), ":", "꞉") # unicode replacement char for colon
}

source "virtualbox-ovf" "debugger" {
  headless             = true
  format               = "ovf"
  shutdown_command     = "shutdown /s /t 10 /f /d p:4:1 /c Packer_Provisioning_Shutdown"
  guest_additions_mode = "disable"
  output_directory     = "output/debugger"
  output_filename      = "../windows10-debugger-x86_64"
  source_path          = "output/windows10-bootstrap-x86_64.ovf"
  floppy_files         = ["debugger.ps1"]
  communicator         = "winrm"
  winrm_username       = "user"
  winrm_password       = "resu"
  winrm_insecure       = true
  vboxmanage           = [["modifyvm", "{{ .Name }}", "--nic2", "intnet", "--cableconnected2", "off", "--intnet2", "localdomain"], ["storageattach", "{{ .Name }}", "--storagectl", "SATA Controller", "--port", "20", "--device", "0", "--type", "dvddrive", "--medium", "win10sdk.iso"]]
  vboxmanage_post      = [["modifyvm", "{{ .Name }}", "--cableconnected1", "off", "--cableconnected2", "on"], ["storageattach", "{{ .Name }}", "--storagectl", "SATA Controller", "--port", "20", "--device", "0", "--type", "dvddrive", "--medium", "none"]]
  vm_name              = replace(timestamp(), ":", "꞉") # unicode replacement char for colon
}

build {
  sources = ["source.virtualbox-iso.bootstrap", "source.virtualbox-ovf.debuggee", "source.virtualbox-ovf.debugger"]

  provisioner "windows-shell" {
    inline = ["powershell -NoLogo -ExecutionPolicy RemoteSigned -File A:/debuggee.ps1"]
    only   = ["virtualbox-ovf.debuggee"]
  }

  provisioner "windows-shell" {
    inline = ["powershell -NoLogo -ExecutionPolicy RemoteSigned -File A:/debugger.ps1"]
    only   = ["virtualbox-ovf.debugger"]
  }
}
