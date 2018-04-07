# Zero-Drive

Powershell script version of Sdelete -Z to zero free space on a disk.

### Installing

Can be installed from PowerShell Gallery via Install-Module for Powershell 5.x and up.

```
Install-Module -Name Zero-Drive  
```

### Usage examples

Write Zero's to C drive with default settings

```
Invoke-ZeroDrive -Drive C
```

Write Zero's to E drive with blocksize of 1MB and leave 10GB of free space

```
Invoke-ZeroDrive -Drive E -BlockSize 1MB -SpaceToLeave 10
```
