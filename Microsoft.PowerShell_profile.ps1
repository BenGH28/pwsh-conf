using namespace Microsoft.PowerShell
$env:PYTHONIOENCODING = "utf-8"
$Env:EDITOR = "nvim"
$Env:IGNITION = "C:\Program Files\Inductive Automation\Ignition"

Set-Alias -Name which -Value Get-Command
Set-Alias -Name lg -Value lazygit
Set-Alias -Name vim -Value nvim
Set-Alias -Name vi -Value nvim
Set-Alias -Name vid -Value neovide

Remove-Item Alias:ls -ErrorAction SilentlyContinue
Remove-Item Alias:cd -ErrorAction SilentlyContinue


# binds
Set-PSReadLineOption -EditMode Emacs
Set-PSReadLineKeyHandler -Chord 'Ctrl+backspace' -Function BackwardDeleteWord

$UtilsPath = "$(Split-Path -Path $PROFILE -Parent)\utils\"
Get-ChildItem -Path $UtilsPath -Filter *.ps1 | ForEach-Object {
    . $_.FullName
}


function Set-Location-Up
{
    Set-Location ..
}
Set-Alias -Name .. -Value Set-Location-Up


function Set-Location-Profile
{
    Set-Location (Split-Path -Path $PROFILE -Parent)
}
function profile
{
    nvim $PROFILE
}

function ivg
{
    param (
        [Parameter(Mandatory=$true)][string]$pattern,
        [string[]]$glob = @('!.resources/**'),
        [string]$path = "."
    )

    $rgArgs = @(
        "--color=auto",
        "--smart-case",
        "--vimgrep"
    )
    foreach ($g in $glob)
    {
        $rgArgs += "--glob"
        $rgArgs += $g
    }
    $rgArgs += $pattern
    $rgArgs += $path


    $search = & rg  $rgArgs | fzf --delimiter=":" `
        --preview 'bat --color=always --style=numbers {1} --highlight-line {2} -r {2}:'`

    if ($search)
    {
        $array = $search -split ":"  # Split multiline string into array
        $file = $array[0]
        $line = [int]$array[1]
        $col = [int]$array[2]
        nvim "+call cursor(${line},${col})" $file
    }
}

function vq
{
    param (
        [Parameter(Mandatory=$true)][string]$term,
        [string]$glob = "*",
        [string]$path = "."
    )
    $temp = [System.IO.Path]::GetTempFileName()
    rg --smart-case --vimgrep --glob=$glob $term $path | Set-Content $temp
    if ((Get-Content $temp).Length -eq 0)
    {
        Write-Host "No matches found."
        Remove-Item $temp
    } else
    {
        nvim -q $temp
        Remove-Item $temp
    }
}


function iv
{
    try
    {
        $temp = "$env:TMP\selected_path.txt"
        # Get the selected files using fd and fzf with bat as the preview
        fd -H --type f `
            --exclude "*.bin" `
            --exclude "*.gif" `
            --exclude "*.png" `
            --exclude "*.jpeg" `
            --exclude "*.jpg" `
            --exclude "*OneDrive*" `
            --exclude ".cache" `
            --exclude ".codeium" `
            --exclude ".git" `
            --exclude ".docker" `
            --exclude ".ignition" `
            --exclude ".local" `
            --exclude ".ollama" `
            --exclude ".pyenv" `
            --exclude "go" `
            --exclude "scoop" `
            --exclude "*resource.json" `
        | fzf --multi `
            --bind "enter:become(nvim {+})"`
            --bind "ctrl-e:become(code {+})"`
            --bind "ctrl-i:execute-silent(echo {} > $temp)+abort"`
            --preview 'bat --color=always {}'

        if (Test-Path "$temp")
        {
            $path = (Get-Content "$temp" | Out-String).Trim('"')
            Remove-Item "$temp"

            if ($path -ne "")
            {
                $dir = Split-Path -Path $path -Parent

                if (Test-Path $dir)
                {
                    Set-Location $dir
                } else
                {
                    Write-Host "Directory does not exist: $dir"
                }
            }
        }

    } catch
    {
        Write-Host "exited"
    }
}

Set-PSReadLineKeyHandler -Chord Ctrl+/ -ScriptBlock {
    [PSConsoleReadLine]::RevertLine()
    [PSConsoleReadLine]::Insert("ivg -glob '@@' -path '@@' -pattern @@")
    [PSConsoleReadLine]::SetCursorPosition(13)
}


# cycle through place holders `@@`
Set-PSReadLineKeyHandler -Chord 'Ctrl+n' -ScriptBlock {
    $line = $null
    $cursor = $null
    [PSConsoleReadLine]::GetBufferState([ref]$line, [ref]$cursor)

    $next = $line.IndexOf('@@', $cursor) + 2
    if ($next -eq $cursor)
    {
        # If we're already at the marker, find the next one
        $next = $line.IndexOf('@@', $cursor + 2)
    }

    if ($next -ge 0)
    {
        [PSConsoleReadLine]::SetCursorPosition($next)
    }
}

Set-PSReadLineKeyHandler -Chord Ctrl+g -ScriptBlock {
    [PSConsoleReadLine]::RevertLine()
    [PSConsoleReadLine]::Insert("gsf")
    [PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Chord Ctrl+o -ScriptBlock {
    [PSConsoleReadLine]::RevertLine()
    [PSConsoleReadLine]::Insert("iv")
    [PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Chord Ctrl+. -ScriptBlock {
    [PSConsoleReadLine]::RevertLine()
    [PSConsoleReadLine]::Insert(". '$PROFILE'")
    [PSConsoleReadLine]::AcceptLine()
}

Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }

Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PsFzfOption -TabExpansion
Set-PsFzfOption -EnableAliasFuzzyKillProcess
Set-PsFzfOption -EnableAliasFuzzyScoop


function liw
{
    Set-Location "$Env:IGNITION\data\projects"
}

function cd
{
    param (
        [string]$Path
    )

    if ($Path)
    {
        z $Path
    } else
    {
        z $HOME
    }
}

# ls
function l
{
    exa --color=always --group-directories-first --icons $args
}

function ls
{
    exa --color=always --group-directories-first --icons $args
}

function la
{
    eza -laF --color=always --group-directories-first --icons $args
}

function ll
{
    eza -l --color=always --group-directories-first --icons $args
}

function lT
{
    eza -lT --color=always --group-directories-first --icons $args
}


function Invoke-Starship-PreCommand
{
    $loc = $executionContext.SessionState.Path.CurrentLocation;
    $prompt = "$([char]27)]9;12$([char]7)"
    if ($loc.Provider.Name -eq "FileSystem")
    {
        $prompt += "$([char]27)]9;9;`"$($loc.ProviderPath)`"$([char]27)\"
    }
    $host.ui.Write($prompt)
}

function Update-WindowTitle
{
    $host.ui.RawUI.WindowTitle = (Get-Location).Path | Split-Path -Leaf
}

Register-EngineEvent PowerShell.OnIdle -Action { Update-WindowTitle } | Out-Null

Invoke-Expression (&starship init powershell)
Invoke-Expression (& { (zoxide init powershell | Out-String) })
Invoke-Expression (&scoop-search --hook)
