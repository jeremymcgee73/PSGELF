# PSGELF
A PowerShell Module to send logs to a GELF server like Graylog.

##Description
This repository contains PowerShell functions to send logs to a compatible GELF server like Graylog. I have tested this module on Powershell 4/5 on Windows and lightly tested with Powershell 6 on CentOS 7 and OSX.

##Getting Started
You can install this module by copying the PSGELF folder to your PowerShell Modules directory.

##Functions
|  PSGELF Function  |  Description  |
| ------------- | ------------- |
| Send-PSGelfTCP | Sends a GELF message via UDP. This function does not accept Pipeline input. |
| Send-PSGelfUDP | Sends a GELF message via TCP. This function does not accept Pipeline input. |
| Send-PSGelfTCPFromObject | This function sends an PSObject to Graylog via TCP to a server supporting GELF. This function is designed to accept Pipeline from Get-WinEvent. But, accepts any PSOBJECT. |
| Send-PSGelfUDPFromObject | This function sends an PSObject to Graylog via UDP to a server supporting GELF. This function is designed to accept Pipeline from Get-WinEvent. But, accepts any PSOBJECT. |

##Help
You can use `Get-Command -Module PSGELF` to get a list of cmdlets in the module.
You can use `Get-Help command` to view the help information for the cmdlet.

##TO DO
I may add defaults for the port parameters. I am also going to publish the module to the Powershell Gallery.
