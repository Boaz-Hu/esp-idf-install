#安装git
Write-Host ""
IF (Get-Command git) {
    git --version
} ELSE {
    Write-Host '请安装git' -ForegroundColor red
    Write-Host 'https://git-scm.com/download/win' -ForegroundColor red
    Write-Host ""
    pause
    exit
}

#安装python
Write-Host ""
IF (Get-Command python) {
    python --version
} ELSE {
    Write-Host '请安装python, 推荐稳定版本, 测试3.9.10版本OK' -ForegroundColor red
    Write-Host 'https://www.python.org/downloads/windows/' -ForegroundColor red
    Write-Host ""
    pause
    exit
}
#换源
pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
pip config set global.trusted-host https://pypi.tuna.tsinghua.edu.cn

#获取安装地址
Write-Host ""
$Path = Read-Host '请输入安装路径(路径: D:\___Software)'
IF ($Path -notmatch '^[a-zA-Z]:\\') {
    Write-Host ""
    Write-Host '错误路径' -ForegroundColor red
    Write-Host ""
    pause
    exit
}
$Version = Read-Host '请输入安装的 idf 版本(分支: release/v4.3.1 或者 标签: v4.3.1)'
$Version = $Version -replace "release/", "r"
IF ($Version -eq '') {
    Write-Host ""
    Write-Host '错误分支或错误标签' -ForegroundColor red
    Write-Host ""
    pause
    exit
}

#变量
Write-Host ""
$url_idf = 'https://gitee.com/EspressifSystems/esp-idf.git'
$url_tools = 'https://gitee.com/EspressifSystems/esp-gitee-tools.git'
$path_tools = $Path + '\esp\esp-gitee-tools'
$path_esp = $Path + '\esp\esp-idf-' + $Version
$path_esp_idf = $path_esp + '\esp-idf'
$path_esp_espressif = $path_esp + '\.espressif'

#创建文件夹
IF (Test-Path $path_esp_espressif) {
    Write-Host ""
    Write-Host "安装失败, 已存在相同 idf 版本" -ForegroundColor red
    Write-Host ""
    pause
    exit
} ELSE {
    $null = New-Item -ItemType Directory -Path $path_esp_espressif
}

#打开git bash 安装
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
    Write-Host "安装失败, 请查看失败信息, 删除安装版本后重装" -ForegroundColor red
    Write-Host "idf 安装路径: $path_esp" -ForegroundColor red
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
    Write-Host "安装失败, 请查看失败信息, 删除安装版本后重装" -ForegroundColor red
    Write-Host "idf 安装路径: $path_esp" -ForegroundColor red
    Write-Host ""
    pause
    exit
}

#创建并写入 PowerShell 启动脚本
'
function esp_env_init{
    switch($args.Count) {
        1 {
            $path = "' + $Path + '\esp\esp-idf-" + $args
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
Write-Host "已覆盖创建 PowerShell 启动脚本: $PROFILE"

#安装完成
Write-Host ""
Write-Host '安装完成' -ForegroundColor green
Write-Host ""
pause
exit

