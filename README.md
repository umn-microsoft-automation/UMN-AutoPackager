# UMN-AutoPackager

- [UMN-AutoPackager](#umn-autopackager)
  - [Overview](#overview)
  - [Requirements](#requirements)
  - [Building the Project](#building-the-project)

The UMN-Autopackager module is designed to help automating the building of packages for Microsoft Endpoint Management Configuration Manager (MEMCM formerly SCCM).  See the section [Building the Project](#building-the-project) to understand how to build all the components of the repo into the output directory.

## Overview

This module consists of a PowerShell portion and a C# portion.  They all exist under the UMN-AutoPackager module.

## Requirements

- [.Net Core SDK 3.x](https://dotnet.microsoft.com/download)
- Powershell (Either built in Windows Powershell or [Powershell Core](https://github.com/PowerShell/PowerShell/releases/latest))

## Building the Project

Under the /build directory there is a quick_build_local.ps1 file.  This will automatically copy all the PowerShell files into the /output/UMN-AutoPackager directory then run a dotnet build on the C# module.  After the dotnet build it will copy the C# module to the output directory as well.  It then launch a new pwsh window and load the module.
