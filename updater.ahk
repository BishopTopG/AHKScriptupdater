; Enhanced GitHub Auto-Updater for AHK
#SingleInstance Force
#NoEnv
SetWorkingDir %A_ScriptDir%

; Configuration
github_user := "YourUsername"
github_repo := "YourRepoName"
script_name := "main-script.ahk"
local_version_file := A_ScriptDir . "\version.txt"
current_script := A_ScriptDir . "\" . script_name
changelog_url := "https://github.com/" . github_user . "/" . github_repo . "/blob/main/changelog.txt"

; Add a GUI for better user experience
Gui, +AlwaysOnTop
Gui, Add, Text, w300, Checking for updates...
Gui, Show, w320 h100, AHK Script Updater

; Read local version
if FileExist(local_version_file) {
    FileRead, local_version, %local_version_file%
    local_version := Trim(local_version)
} else {
    local_version := "0.0.0"
    FileAppend, %local_version%, %local_version_file%
}

; GitHub API request (more reliable than raw file download)
whr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
api_url := "https://api.github.com/repos/" . github_user . "/" . github_repo . "/contents/version.txt"
try {
    whr.Open("GET", api_url, false)
    whr.Send()
    response := whr.ResponseText
    
    ; Parse JSON response
    RegExMatch(response, """content"":""([^""]+)", content_match)
    if (content_match1) {
        ; GitHub API returns Base64 encoded content
        remote_version_base64 := content_match1
        ; Convert from Base64 (simplified approach)
        remote_version := Base64Decode(StrReplace(remote_version_base64, "\n", ""))
        remote_version := Trim(remote_version)
        
        ; Compare versions
        if (CompareVersions(remote_version, local_version) > 0) {
            Gui, Destroy
            MsgBox, 4, Update Available, A new version (%remote_version%) is available. Update now?`n`nYou currently have version %local_version%.
            IfMsgBox Yes
            {
                Gui, New, +AlwaysOnTop
                Gui, Add, Progress, w300 h20 vUpdateProgress
                Gui, Add, Text, w300 vUpdateStatus, Downloading update...
                Gui, Show, w320 h100, Updating Script
                
                ; Download new script
                script_url := "https://raw.githubusercontent.com/" . github_user . "/" . github_repo . "/main/" . script_name
                backup_script := A_ScriptDir . "\backup_" . script_name
                
                ; Backup current script
                if FileExist(current_script)
                    FileCopy, %current_script%, %backup_script%, 1
                
                ; Download new script
                UrlDownloadToFile, %script_url%, %current_script%
                
                GuiControl,, UpdateProgress, 50
                GuiControl,, UpdateStatus, Updating version information...
                
                ; Update local version file
                FileDelete, %local_version_file%
                FileAppend, %remote_version%, %local_version_file%
                
                GuiControl,, UpdateProgress, 100
                GuiControl,, UpdateStatus, Update complete! Restarting...
                Sleep, 1000
                
                ; Show changelog option
                Gui, Destroy
                MsgBox, 4, Update Complete, Update to version %remote_version% successful!`n`nWould you like to view the changelog?
                IfMsgBox Yes
                    Run, %changelog_url%
                
                ; Restart script
                Run, %current_script%
                ExitApp
            }
        } else {
            Gui, Destroy
            MsgBox, You have the latest version (%local_version%).
        }
    }
} catch e {
    Gui, Destroy
    MsgBox, Failed to check for updates. Will continue with current version.`n`nError: %e%
}

; Launch the main script
Run, %current_script%
ExitApp

; Function to compare version strings
CompareVersions(vA, vB) {
    vA_parts := StrSplit(vA, ".")
    vB_parts := StrSplit(vB, ".")
    
    Loop, % Max(vA_parts.MaxIndex(), vB_parts.MaxIndex())
    {
        a := (A_Index <= vA_parts.MaxIndex()) ? vA_parts[A_Index] : 0
        b := (A_Index <= vB_parts.MaxIndex()) ? vB_parts[A_Index] : 0
        
        if (a > b)
            return 1
        if (a < b)
            return -1
    }
    return 0
}

; Simple Base64 decoder function
Base64Decode(string) {
    if !(DllCall("crypt32\CryptStringToBinary", "ptr", &string, "uint", 0, "uint", 0x1, "ptr", 0, "uint*", size, "ptr", 0, "ptr", 0))
        return
    VarSetCapacity(bin, size, 0)
    if !(DllCall("crypt32\CryptStringToBinary", "ptr", &string, "uint", 0, "uint", 0x1, "ptr", &bin, "uint*", size, "ptr", 0, "ptr", 0))
        return
    return StrGet(&bin, size, "UTF-8")
}