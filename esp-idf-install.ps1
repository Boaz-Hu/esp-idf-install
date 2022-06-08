# Install git
Write-Host ""
IF (Get-Command git) {
    git --version
} ELSE {
    Write-Host 'Please install git.' -ForegroundColor red
    Write-Host 'https://git-scm.com/download/win' -ForegroundColor red
    Write-Host ""
    pause
    exit
}

# Install python
Write-Host ""
IF (Get-Command python) {
    python --version
} ELSE {
    Write-Host 'Please install python. Recommended stable version. Test version 3.9.10 OK.' -ForegroundColor red
    Write-Host 'https://www.python.org/downloads/windows/' -ForegroundColor red
    Write-Host ""
    pause
    exit
}
# Change Source
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
pip config set global.trusted-host https://pypi.tuna.tsinghua.edu.cn

# First Use
IF (![environment]::GetEnvironmentvariable("ESP_INSTALL_PATH", "User")) {
    # Get idf install path
    Write-Host ""
    Write-Host 'First install. Please enter idf install path, eg: D:\___Software'
    $Path = Read-Host 'Path'
    IF ($Path -notmatch '^[a-zA-Z]:') {
        Write-Host ""
        Write-Host "Error path: $Path" -ForegroundColor red
        Write-Host ""
        pause
        exit
    } ELSE {
        [environment]::SetEnvironmentvariable("ESP_INSTALL_PATH", $Path + "\esp", "User")
    }
} ELSE {
    $Path = [environment]::GetEnvironmentvariable("ESP_INSTALL_PATH", "User")
    IF ($Path -notmatch '^[a-zA-Z]:') {
        Write-Host ""
        Write-Host "Error path: $Path" -ForegroundColor red
        Write-Host ""
        Write-Host 'Please enter idf install path, eg: D:\___Software'
        $Path = Read-Host 'Path'
        IF ($Path -notmatch '^[a-zA-Z]:') {
            Write-Host ""
            Write-Host "Error path: $Path" -ForegroundColor red
            Write-Host ""
            pause
            exit
        } ELSE {
            [environment]::SetEnvironmentvariable("ESP_INSTALL_PATH", $Path + "\esp", "User")
        }
    }
}
Write-Host ""
Write-Host "ESP install path: $Path" -ForegroundColor green
Write-Host ""

# Get idf install version
Write-Host 'Please enter idf install version, branch: "release/v4.3.1" or tag: "v4.3.1"'
$Version = Read-Host 'Version'
$Version = $Version.replace("\", "/")
$Version = $Version.replace("release/v", "rv")
IF ($Version -eq '') {
    Write-Host ""
    Write-Host 'Error branch or Error tag.' -ForegroundColor red
    Write-Host ""
    pause
    exit
} ELSE {
    Write-Host ""
    Write-Host "ESP install version: $Version" -ForegroundColor green
    Write-Host ""
}

# Temp variables
Write-Host ""
$url_idf = 'https://gitee.com/EspressifSystems/esp-idf.git'
$url_tools = 'https://gitee.com/EspressifSystems/esp-gitee-tools.git'
$path_tools = $Path + '\esp-gitee-tools'
$path_esp = $Path + '\esp-idf-' + $Version
$path_esp_idf = $path_esp + '\esp-idf'
$path_esp_espressif = $path_esp + '\.espressif'

# Create folder
IF (Test-Path $path_esp_espressif) {
    Write-Host ""
    Write-Host 'Failed, the same idf version exists.' -ForegroundColor red
    Write-Host ""
    pause
    exit
} ELSE {
    $null = New-Item -ItemType Directory -Path $path_esp_espressif
}

# Open "git bash" and then install
$Version = $Version.replace("rv", "release/v")

$cmd0 = 'cd ' + $path_esp.replace("\", "/") + ' && '
$cmd1 = "git clone -b $Version $url_idf && "
$cmd2 = 'cd .. && '
$cmd3 = "git clone $url_tools && "
$cmd4 = 'cd ' + $path_esp_idf.replace("\", "/") + ' && '
$cmd5 = 'export IDF_TOOLS_PATH=' + $path_esp_espressif.replace("\", "/") + ' && '
$cmd6 = '../../esp-gitee-tools/install.sh && '
$cmd7 = '../../esp-gitee-tools/submodule-update.sh'
#$cmdn = ' && exec /bin/bash'
IF (Test-Path $path_tools) {
    Write-Host "esp-gitee-tools have beed cloned."
    Write-Host ""
    $cmd = $cmd0 + $cmd1 + $cmd4 + $cmd5 + $cmd6 + $cmd7
} ELSE {
    $cmd = $cmd0 + $cmd1 + $cmd2 + $cmd3 + $cmd4 + $cmd5 + $cmd6 + $cmd7
}
$ArgList = "'" + "'" + '-c ' + '"' + $cmd + '"' + "'" + "'"
$return = Start-Process bash -ArgumentList $ArgList -Wait -PassThru -NoNewWindow
IF ($return.ExitCode) {
    Write-Host ""
    Write-Host 'Failed, delete the installed version and reinstall it.' -ForegroundColor red
    Write-Host "idf installation path: $path_esp" -ForegroundColor red
    Write-Host ""
    pause
    exit
}
$idf_python = Get-ChildItem $path_esp_espressif -Recurse | where {$_.Name -eq "python.exe"} | % {$_.FullName}
IF ($idf_python) {
    $ArgList = "'" + "'" + '-c ' + '"' + $idf_python.replace("\", "/") + ' -m pip install windows-curses' + '"' + "'" + "'"
    Start-Process bash -ArgumentList $ArgList -Wait -NoNewWindow
} ELSE {
    Write-Host ""
    Write-Host 'Failed, delete the installed version and reinstall it.' -ForegroundColor red
    Write-Host "idf installation path: $path_esp" -ForegroundColor red
    Write-Host ""
    pause
    exit
}

# Overwrite or Create PowerShell Startup Script
IF (Select-String -Path $PROFILE -Pattern "esp_env_init") {
} ELSE {
    '
    function esp_env_init{
        switch($args.Count) {
            1 {
                $path = "' + $Path + '\esp-idf-" + $args
                $env:IDF_TOOLS_PATH=$path + "\.espressif"
                . $path\esp-idf\export.ps1
                return
            }
            Default {
                Write-Error "args error"
                return
            }
        }
    }

    function espefuse{
        python $env:IDF_PATH"\components\esptool_py\esptool\espefuse.py" $args
    }
    function espsecure{
        python $env:IDF_PATH"\components\esptool_py\esptool\espsecure.py" $args
    }
    function esptool{
        python $env:IDF_PATH"\components\esptool_py\esptool\esptool.py" $args
    }

    function menuconfig{
        Start-Process powershell -ArgumentList "-command &{idf.py menuconfig}"
    }

    Set-Alias idf idf.py
    ' | Out-File $PROFILE
    Write-Host ""
    Write-Host "Overwrite or create PowerShell Startup Script: $PROFILE"
}

# Install Success
Write-Host ""
Write-Host 'Success!' -ForegroundColor green
Write-Host ""
pause
exit
