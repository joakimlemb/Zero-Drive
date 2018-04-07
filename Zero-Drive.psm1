<# 
 .Synopsis
  Zero free space on a disk.

 .Description
  Powershell script version of Sdelete -Z to zero free space on a disk.

 .Parameter Drive
  Disk drive to Zero, supports with and without colon (:)

 .Parameter FileName
  FileName of Zero Temporary file to create.

 .Parameter BlockSize
  Disk write blocksize in Byte.

 .Parameter SpaceToLeave
  Disk space to leave in Gigabyte.

 .Example
   # Zero free space on c:
   Invoke-ZeroDrive -Drive C

 .Example
   # Zero free space on d: using specified filename and specified free space to not zero, using blocksize 4KB
   Invoke-ZeroDrive -Drive D: -FileName "zero.tmp" -SpaceToLeave 25 -BlockSize 4kb

#>

Function Invoke-ZeroDrive {
    param(
        [parameter(Mandatory=$true)]
        [ValidateScript({
            if( -Not ($_ | Test-Path) ) {
                throw "Drive $_ does not exist."
            }
            return $true
        })]
        [System.IO.DriveInfo]$Drive,
    
        [parameter(Mandatory=$false)]
        [string]$FileName = "zero_drive.tmp",

        [parameter(Mandatory=$false)]
        [ValidateSet(4kb,8kb,16kb,32kb,64kb,1mb)]
        [int]$BlockSize = 64kb,
    
        [parameter(Mandatory=$false)]
        [int]$SpaceToLeave = 2
    ) 
    
    $ZeroFileSizeTarget   = $Drive.AvailableFreeSpace - ($SpaceToLeave * 1024 * 1024 * 1024)
    $ZeroFileSizeTargetGB = [math]::Round(($ZeroFileSizeTarget / 1024 / 1024 / 1024),2)
    $ZeroFilePath         = $Drive.Name + "$FileName"

    # Abort if a File with the same path and name already exist (Could not get this to work within parameter validate scope)
    if( Test-Path -Path $ZeroFilePath ) {
        Throw "$ZeroFilePath Already exist, aborting."
    }

    Try {
        
        $CurrentZeroFileSize = 0
        $ProgressPercent = 0
        $StopWatch = [system.diagnostics.stopwatch]::StartNew()
        Write-Progress -Activity "Zeroing $ZeroFileSizeTargetGB GB free space with $ZeroFilePath" -PercentComplete $ProgressPercent
     
        $ZeroArray = new-object byte[]($BlockSize)
        $Stream = [io.File]::OpenWrite($ZeroFilePath)
    
        while($CurrentZeroFileSize -lt $ZeroFileSizeTarget) {
        
            # Only update progress when progress is +1 integer, Write-Progress slows down the script by updating the progress bar for each disk write.
            $PreviousProgressPercent = $ProgressPercent
            $ProgressPercent = [int]($CurrentZeroFileSize / $ZeroFileSizeTarget * 100)
            if ($ProgressPercent -gt $PreviousProgressPercent) {
                $ElapsedTime = [string]$StopWatch.Elapsed.Hours+" Hours "+[string]$StopWatch.Elapsed.Minutes+" Minutes "+[string]$StopWatch.Elapsed.Seconds+" Seconds"
                if ($StopWatch.Elapsed.Seconds -ge 1) {
                    $SpeedByte  = ($CurrentZeroFileSize / 1024 / 1024) / $StopWatch.Elapsed.TotalSeconds
                    $SpeedMByte = [math]::Round($SpeedByte,0)
                }
                Write-Progress -Activity "Zeroing $ZeroFileSizeTargetGB GB free space with $ZeroFilePath" -Status "$ProgressPercent% in $ElapsedTime" -PercentComplete $ProgressPercent -CurrentOperation "Average Speed: $SpeedMByte MB/s" -SecondsRemaining (($StopWatch.Elapsed.TotalSeconds / $ProgressPercent) * (100 - $ProgressPercent))
            }
        
            $Stream.Write($ZeroArray,0, $ZeroArray.Length)
            $CurrentZeroFileSize +=$ZeroArray.Length
        }
    }

    Catch {
        $Exception = $true
        Throw
    }

    Finally {

        # Cleanup (Also works with CTRL-C, though write-output gets lost with CTRL-C, but write-host works with CTRL-C)
        $StopWatch.Stop()

        If ($Stream) {
            $Stream.Close()
        }

        If (Test-Path -Path $ZeroFilePath) {
            Remove-Item $ZeroFilePath
        }

        Write-Progress -Activity "Finished Zeroing $ZeroFileSizeTargetGB GB free space with $ZeroFilePath" -Completed
        
        If (-not $Exception) {
            $ZeroWrittenGB = [string]([math]::Round(($CurrentZeroFileSize / 1024 / 1024 / 1024),2))+" GB"
            $ElapsedTime = $StopWatch.Elapsed
            Write-Host "Finished Zeroing $ZeroWrittenGB in $ElapsedTime on $ZeroFilePath (Average Speed: $SpeedMByte MB/s)"
        }

    }
}
