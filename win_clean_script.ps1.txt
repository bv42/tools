<#MIT LicenseCopyright (c) [2025] [Bitvektor]Permission is hereby granted, free of charge, to any person obtaining a copyof this software and associated documentation files (the "Software"), to dealin the Software without restriction, including without limitation the rightsto use, copy, modify, merge, publish, distribute, sublicense, and/or sellcopies of the Software, and to permit persons to whom the Software isfurnished to do so, subject to the following conditions:The above copyright notice and this permission notice shall be included in allcopies or substantial portions of the Software.THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS ORIMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THEAUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHERLIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THESOFTWARE.#># PowerShell script to clean up files and folders older than 5 days# in the specified directory and its sub-directories.# Define the target directory$TargetDirectory = "c:\Users\User1\AppData\Local\Temp"# Define the age threshold in days$AgeThreshold = -5# Get the current date and calculate the cutoff date$CutoffDate = (Get-Date).AddDays($AgeThreshold)

# Function to delete old items in the directoryfunction Remove-OldFilesAndFolders {
    param (
        [string]$Path    )

    try {
        # Log event before the cleanup starts        Write-EventLog -LogName "Application" -Source "FileCleanupScript" -EventId 1001 -EntryType Information -Message "File cleanup process started for $Path."        # Verify directory exists        if (-not (Test-Path -Path $Path)) {
            Write-EventLog -LogName "Application" -Source "FileCleanupScript" -EventId 1005 -EntryType Warning -Message "The directory $Path does not exist."            return        }

        # Get all items (files and folders) in the target directory, including sub-directories        $Items = Get-ChildItem -Path $Path -Recurse -ErrorAction Stop -Force
        $DeletedItems = @()

        foreach ($Item in $Items) {
            # Check if the item's LastWriteTime is older than the cutoff date            if ($Item.LastWriteTime -lt $CutoffDate) {
                try {
                    # Attempt to remove the item                    if ($Item.PSIsContainer) {
                        # Item is a folder, remove it                        Remove-Item -Path $Item.FullName -Recurse -Force -ErrorAction Stop
                    } else {
                        # Item is a file, remove it                        Remove-Item -Path $Item.FullName -Force -ErrorAction Stop
                    }
                    $DeletedItems += $Item.FullName                } catch {
                    Write-Warning "Failed to delete item: $($Item.FullName). Error: $($_.Exception.Message)"                }
            }
        }

        # Log event after successful cleanup        if ($DeletedItems.Count -gt 0) {
            $Message = "File cleanup completed successfully. Deleted items:`n" + ($DeletedItems -join "`n")
            Write-EventLog -LogName "Application" -Source "FileCleanupScript" -EventId 1002 -EntryType Information -Message $Message        } else {
            Write-EventLog -LogName "Application" -Source "FileCleanupScript" -EventId 1003 -EntryType Information -Message "File cleanup completed. No items were deleted."        }

    } catch {
        # Log error in the event log        $ErrorMessage = "An error occurred during cleanup: $($_.Exception.Message)"        Write-EventLog -LogName "Application" -Source "FileCleanupScript" -EventId 1004 -EntryType Error -Message $ErrorMessage        Write-Error $ErrorMessage    }
}

# Check if the current session has administrative privilegesif (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host "This script requires administrative privileges. Run the script as an administrator." -ForegroundColor Red
    exit}

# Ensure the event log source existsif (-not (Get-EventLog -LogName "Application" -Source "FileCleanupScript" -ErrorAction SilentlyContinue)) {
    New-EventLog -LogName "Application" -Source "FileCleanupScript"}

# Run the cleanup functionRemove-OldFilesAndFolders -Path $TargetDirectory
