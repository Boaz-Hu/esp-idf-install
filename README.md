# esp-idf PowerShell 安装脚本

- 需要预先安装 git-bash, python (3.9.10版本测试OK)  
- 初次使用 PowerShell 脚本需要以管理员身份执行该命令 `Set-ExecutionPolicy RemoteSigned`  


# 使用方法

1. VSCode 打开 esp 工程
2. 唤出内置 PowerShell 终端
3. 输入 `esp_env_init <idf 版本>` , eg: `esp_env_init v4.4` , 部署运行环境（每次打开新的终端都需要部署运行环境）
    - <idf 版本> 分为 "分支版本, 如: release/v4.4"、"标签版本, 如: v4.4"
    - "分支版本: release/v4.4" 的初始化为 `esp_env_init rv4.4`
    - "标签版本: v4.4" 的初始化为 `esp_env_init v4.4`
4. 输入 `idf all` , 编译工程
5. 输入 `menuconfig` , 打开配置界面
