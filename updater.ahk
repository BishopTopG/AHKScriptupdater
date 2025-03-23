; Simplified GitHub Auto-Updater for AHK
#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%

; Configuration
github_user := "BishopTopG"
github_repo := "AHKScriptupdater"
script_name := "ColdMX.exe"
local_version_file := A_ScriptDir . "\version.txt"

; Simple GUI
Gui, +AlwaysOnTop
Gui, Add, Text, w300, Checking for updates...
Gui, Show, w320 h100, AHK Script Updater

; Read local version
local_version := "Not installed"
if FileExist(local_version_file) {
    FileRead, file_content, %local_version_file%
    if (file_content != "") {
        local_version := RegExReplace(file_content, "[\r\n\s]", "")
    }
}

; Get remote version directly (avoid API to simplify)
version_url := "https://raw.githubusercontent.com/" . github_user . "/" . github_repo . "/main/version.txt"

; Create a temporary file for the version
version_temp := A_ScriptDir . "\version_temp.txt"
FileDelete, %version_temp%

; Download the version file
UrlDownloadToFile, %version_url%, %version_temp%
if (ErrorLevel) {
    Gui, Destroy
    MsgBox, Failed to download version information. Please check your internet connection.
    ExitApp
}

; Read the downloaded version
FileRead, remote_version, %version_temp%
remote_version := RegExReplace(remote_version, "[\r\n\s]", "")
FileDelete, %version_temp%

; Find existing scripts
existing_script := ""
Loop, Files, %A_ScriptDir%\*.%script_name%
{
    SplitPath, A_LoopFileFullPath, file_name
    existing_script := A_LoopFileFullPath
    Break ; Just take the first one we find for simplicity
}

; Check if we need to download
if (!existing_script || local_version = "Not installed" || local_version != remote_version) {
    if (!existing_script) {
        GuiControl,, Static1, Script not found. Downloading...
    } else if (local_version != remote_version) {
        Gui, Destroy
        MsgBox, 4, Update Available, A new version (%remote_version%) is available. Update now?`n`nCurrent: %local_version%
        IfMsgBox No
        {
            if (existing_script) {
                Run, %existing_script%
            }
            ExitApp
        }
        Gui, +AlwaysOnTop
        Gui, Add, Text, w300, Downloading update...
        Gui, Show, w320 h100, Updating Script
    }
    
    ; Create the download path - CAREFUL with the filename
    script_url := "https://raw.githubusercontent.com/" . github_user . "/" . github_repo . "/main/" . script_name
    clean_version := Trim(remote_version)
    output_filename := clean_version . "." . script_name
    output_path := A_ScriptDir . "\" . output_filename
    
    ; Double check for any bad characters
    StringReplace, output_path, output_path, `r, , All
    StringReplace, output_path, output_path, `n, , All
    
    ; Ensure the file doesn't exist
    if FileExist(output_path) {
        FileDelete, %output_path%
    }
    
    ; Try direct download
    UrlDownloadToFile, %script_url%, %output_path%
    download_error := ErrorLevel
    
    if (download_error) {
        Gui, Destroy
        MsgBox, Failed to download the script. Please check your internet connection.
        ExitApp
    }
    
    ; Verify file was downloaded
    if FileExist(output_path) {
        FileDelete, %local_version_file%
        FileAppend, %remote_version%, %local_version_file%
        
        Gui, Destroy
        MsgBox, Update to version %remote_version% successful!
        
        ; Run the new script
        Run, %output_path%
    } else {
        Gui, Destroy
        MsgBox, Failed to create the script file after download. Check permissions.
    }
} else {
    GuiControl,, Static1, You have the latest version: %local_version%
    Sleep, 1000
    
    ; Run the existing script
    Run, %existing_script%
}

ExitApp
