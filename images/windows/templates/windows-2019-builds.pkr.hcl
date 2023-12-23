packer {
  required_plugins {
    docker = {
      version = ">= 0.0.7"
      source  = "github.com/hashicorp/docker"
    }
  }
}

source "docker" "windowsltsc" {
  image  = "mcr.microsoft.com/dotnet/framework/runtime:4.8-20231114-windowsservercore-ltsc2019"
  commit = true
  windows_container = true
}

variable "agent_tools_directory" {
  type    = string
  default = "C:\\hostedtoolcache\\windows"
}

variable "helper_script_folder" {
  type    = string
  default = "C:\\Program Files\\WindowsPowerShell\\Modules\\"
}

variable "imagedata_file" {
  type    = string
  default = "C:\\imagedata.json"
}

variable "image_folder" {
  type    = string
  default = "C:\\image"
}

variable "image_os" {
  type    = string
  default = "win19"
}

variable "image_version" {
  type    = string
  default = "dev"
}

build {
  name = "Build"
  sources = [
    "source.docker.windowsltsc"
  ]

  provisioner "powershell" {
    inline = ["New-Item -Path ${var.image_folder} -ItemType Directory -Force"]
  }

  provisioner "file" {
    destination = "${var.image_folder}\\"
    sources     = ["${path.root}/../assets", "${path.root}/../scripts", "${path.root}/../toolsets"]
  }

  provisioner "powershell" {
    inline = ["Move-Item '${var.image_folder}\\assets\\post-gen' 'C:\\post-generation'", "Remove-Item -Recurse '${var.image_folder}\\assets'", "Move-Item '${var.image_folder}\\scripts\\docs-gen' '${var.image_folder}\\SoftwareReport'", "Move-Item '${var.image_folder}\\scripts\\helpers' '${var.helper_script_folder}\\ImageHelpers'", "New-Item -Type Directory -Path '${var.helper_script_folder}\\TestsHelpers\\'", "Move-Item '${var.image_folder}\\scripts\\tests\\Helpers.psm1' '${var.helper_script_folder}\\TestsHelpers\\TestsHelpers.psm1'", "Move-Item '${var.image_folder}\\scripts\\tests' '${var.image_folder}\\tests'", "Remove-Item -Recurse '${var.image_folder}\\scripts'", "Move-Item '${var.image_folder}\\toolsets\\toolset-2019.json' '${var.image_folder}\\toolset.json'", "Remove-Item -Recurse '${var.image_folder}\\toolsets'"]
  }

  provisioner "powershell" {
    environment_vars = ["IMAGE_VERSION=${var.image_version}", "IMAGE_OS=${var.image_os}", "AGENT_TOOLSDIRECTORY=${var.agent_tools_directory}", "ACTIONS_RUNNER_ACTION_ARCHIVE_CACHE=C:\\actionarchivecache\\", "IMAGEDATA_FILE=${var.imagedata_file}"]
    execution_policy = "unrestricted"
    scripts          = ["${path.root}/../scripts/build/Configure-PowerShell.ps1", "${path.root}/../scripts/build/Install-PowerShellModules.ps1", "${path.root}/../scripts/build/Install-Chocolatey.ps1", "${path.root}/../scripts/build/Configure-ImageDataFile.ps1", "${path.root}/../scripts/build/Configure-SystemEnvironment.ps1"]
  }
  
  provisioner "powershell" {
    scripts = ["${path.root}/../scripts/build/Install-PowershellCore.ps1"]
  }

  provisioner "powershell" {
    scripts = ["${path.root}/../scripts/build/Install-VisualStudio.ps1"]
  }

  provisioner "powershell" {
    scripts = ["${path.root}/../scripts/build/Install-WDK.ps1", "${path.root}/../scripts/build/Install-ChocolateyPackages.ps1"]
  }

  provisioner "powershell" {
    scripts = ["${path.root}/../scripts/build/Install-Toolset.ps1", "${path.root}/../scripts/build/Configure-Toolset.ps1", "${path.root}/../scripts/build/Install-NodeJS.ps1", "${path.root}/../scripts/build/Install-Git.ps1"]
  }

  post-processor "docker-tag" {
     repository = "actions-runner-image:ltsc2019"
     tags = ["windows-2019-builds"]
  }
}
