###### :world_map: Supported languages: [English](#) - [Spanish](https://github.com/mlibre2/myLogin/blob/main/README/es.md)

# myLogin [![GitHub Release](https://img.shields.io/github/v/release/mlibre2/myLogin?style=for-the-badge) ![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/mlibre2/myLogin/latest/total?style=for-the-badge) ![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/mlibre2/myLogin/total?style=for-the-badge) <img align="right" width="32" height="32" alt="en" src="https://github.com/user-attachments/assets/c8c08b6a-927c-4278-917a-c23b10e6491d" />](https://github.com/mlibre2/myLogin/releases)

<img width="1280" height="768" alt="en" src="https://github.com/mlibre2/myLogin/blob/main/README/en.png" />

Simple open-source program to lock the Windows Desktop screen with advanced options:
- Disables the desktop while the lock window is active
- Prevents normal system use
- Only unlocks with a password set by the administrator

## 🚀 How to get started/use it?

### 1. Generate your password (Hash)
Run the program with the parameter:

- ``/GenerateHash`` or ``/gh``

Example:
``MyLogin.exe /GenerateHash``

> [!IMPORTANT]
> Once executed, follow the instructions until you get the generated hash (e.g., `0x9461E4B1394C6134483668F09CCF7B93`)
> 🔐 Save it; it will be your "encrypted" password; we'll use it to start the program.

### 2. Start the lock
Use your hash to start the program:

- ``/PassHash`` or ``/ph``

Example:
``MyLogin.exe /PassHash 0x9461E4B1394C6134483668F09CCF7B93``

This hash is the password you entered earlier in plain text but encrypted.
- If you haven't generated a hash, you won't be able to access the program, as it is required to unlock it.
- The password you must use to unlock it is the original one (the one you entered when creating the hash), not the encrypted hash.

Also check out this new feature: [``config.ini``](https://github.com/mlibre2/myLogin/tree/main#%EF%B8%8F-archive-configini)

> [!NOTE]
> 🔧 The following parameters are optional; they are not required.

- ``/DisableExplorer`` or ``/de``
  
  With this parameter, you can temporarily disable **Windows Explorer**, preventing the taskbar, desktop icons, and the ability to open the Start menu.
  > For added security, it is enabled by default since [v2.5](https://github.com/mlibre2/myLogin/releases/tag/2.5)

- ``/DisablePowerOff`` or ``/dp``

  With this parameter, you can disable the Power Off button **(available since [v1.1](https://github.com/mlibre2/myLogin/releases/tag/1.1))**

- ``/DisableReboot`` or ``/dr``

  With this parameter, you can disable the Restart button **(available since [v1.1](https://github.com/mlibre2/myLogin/releases/tag/1.1))**

- ``/DisableLockSession`` or ``/dl``

  With this parameter, you can disable the Lock Session button **(available since [v2.0](https://github.com/mlibre2/myLogin/releases/tag/2.0))**

- ``/Style`` or ``/st``

  With this parameter, you can change the layout (0=Default White, 1=Dark, 2=Light Blue)

  Example, enable dark mode:

``MyLogin.exe /PassHash 0x9461E4B1394C6134483668F09CCF7B93 /Style 1``

- ``/AutoUpdater`` or ``/au``

  With this parameter, you enable automatic updates every time the program starts, once the package is downloaded, it is installed on the next start. **(available since [v2.2](https://github.com/mlibre2/myLogin/releases/tag/2.2))**

- ``/DisableBlur`` or ``/db``

  With this parameter, you can disable the screen blur **(available since [v2.8](https://github.com/mlibre2/myLogin/releases/tag/2.8))**

Example with all options:

``MyLogin.exe /ph 0x9461E4B1394C6134483668F09CCF7B93 /dp /dr /dl /st 1 /au``

## ⚙️ Archive [``config.ini``](https://github.com/mlibre2/myLogin/blob/main/src/config.ini)
> [!WARNING]
> Since version 3.0, a function has been added to read parameters from a file called ``config.ini``. This file allows you to configure settings more easily and conveniently, avoiding having to enter them manually via the command line.
> - Optional:
> If you prefer, you can continue using parameters via the command line without any problem, ignoring this file.
> - The file structure is as follows:
```
[config]
PassHash = 
DisableExplorer = True
DisablePowerOff = False
DisableReboot = False
DisableLockSession = False
Style = 0
AutoUpdater = False
DisableBlur = False
```
## 🔌 ¿How to install it?

You have two options:
- Portable
- Inno Setup

Since version [3.0](https://github.com/mlibre2/myLogin/releases/tag/3.0), a simpler installation system has been included, supporting both manual and unattended modes. You can use these [parameters](https://jrsoftware.org/ishelp/index.php?topic=setupcmdline) to install the program quickly and quietly. It also features a multilingual interface.

## 📥 How do I download it?

Go to the [Releases](https://github.com/mlibre2/myLogin/releases) section where the latest compiled versions will be available.

## ⛓️ How do configure it to start automatically?
### Recommended methods:

You have several methods to ``auto-run``, choose one of them:

| # | Method | Process | Difficulty | Speed | Recommended | Hidden |
|------|-----|-----|-----|-----|-----|-----|
| 1 | Winlogon | Regedit | High | Fast | :heavy_check_mark: | :heavy_check_mark: |
| 2 | Logon Scripts | Gpedit | Medium | Medium | :heavy_check_mark: | :heavy_check_mark: |
| 3 | Run StartUp | Windows | Low | Medium | :heavy_check_mark: | :x: |
| 4 | Scheduled Task | Windows | Low | Slow | :x: | :x: |

1. **Winlogon**:

This is one of the fastest ways to start a program, as it runs immediately after the user logs on, right after the desktop is displayed.
- Open ``regedit`` 
- Go to ``[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon]`` 
- Modify the ``Shell`` key: 

Example: 
``` 
explorer.exe, "C:\myLogin.exe" /PassHash 0x9461E4B1394C6134483668F09CCF7B93 
```


2. **Logon Scripts**: 

- Open ``gpedit.msc`` 
- Go to -> ``Config. User -> Config. Windows -> Script -> Login -> Add``
- Script name: ``C:\myLogin.exe``
- Script parameters: ``/ph 0x9461E4B1394C6134483668F09CCF7B93``
- OK
- Apply and OK

3. **Run StartUp**:

- Create a shortcut in: ``C:\ProgramData\Microsoft\Windows\Start Menu\Programs\StartUp``

Whose properties would look like this: ``C:\myLogin.exe /ph 0x9461E4B1394C6134483668F09CCF7B93``

4. **Scheduled Task**:

- This method may take a while depending on the number of processes and tasks in the queue, so I don't recommend it. If you still decide to use it, follow these steps:
- Open ``cmd``
- Enter ``schtasks /create /tn "myLogin" /tr "\"C:\myLogin.exe\" /ph 0x9461E4B1394C6134483668F09CCF7B93" /sc onlogon``
- And press ENTER.
- Once created, it should run every time the user logs in.

If you want to delete the task, enter the command: ``schtasks /delete /tn "myLogin" /f``

> [!TIP]
> For maximum security, use the "Hidden" methods (Winlogon or Scripts) that prevent others from easily deactivating the program.

## :hammer_and_wrench: How do I compile it manually?

You can use the [CMD](https://github.com/mlibre2/myLogin/blob/main/compile_manual/Aut2Exe.cmd) file, which requires having AutoIt3 installed with Aut2Exe.

## :earth_americas: How do I add more languages?

Starting with version [1.5](https://github.com/mlibre2/myLogin/releases/tag/1.5), you can help add support for languages not yet available. The files are located in the folder [lang/](https://github.com/mlibre2/myLogin/tree/main/src/lang)

## :building_construction: Can I help with its development?

Of course, all suggestions are welcome ;)

> [!CAUTION]
> To report any ``Bug`` :spider: create an [Issues](https://github.com/mlibre2/myLogin/issues) with your problem details!
