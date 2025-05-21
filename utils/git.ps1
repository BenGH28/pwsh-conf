
function gsf
{
    $temp = [System.IO.Path]::GetTempFileName()
    git status --porcelain | ForEach-Object {
        $path = $_.Substring(3)
        if(Test-Path $path -PathType Container)
        {
            Get-ChildItem -Path $path -Recurse -File | ForEach-Object {Resolve-Path -Relative $_.FullName}
        } elseif(Test-Path $path)
        {
            Resolve-Path -Relative $path
        }
    } | fzf --preview 'git --no-pager diff {} | bat --color=always'`
        --bind 'zero:execute(echo clean working tree)+abort'`
        --bind 'enter:become(nvim {})'`
        --bind 'ctrl-u:preview-up,ctrl-d:preview-down'`
        --bind "ctrl-i:execute-silent(echo {} > $temp)+abort"`
        --header "Press CTRL-I to navigate to path, CTRL-U/D to scroll preview Up/Down"

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
}

function gpl
{
    git pull
}

function gpp
{
    git push
}

function gs
{
    git status
}

function gbc
{
    git fetch
    $branches = (git branch -vv)
    foreach($branch in $branches)
    {
        if ($branch -like '*: gone*')
        {
            $trimmed = $branch.Trim()
            $branchParts = $trimmed -split " "
            $branchName = $branchParts[0]
            git branch -d $branchName
        }
    }
}

function gloog
{
    git log --oneline --graph
}

function glog
{
    git log --graph
}

function glo
{
    git log
}

function gloo
{
    git log --oneline
}

function gcmg
{
    param (
        $message
    )
    git commit -m $message
}

function gco
{
    git checkout $args
}

