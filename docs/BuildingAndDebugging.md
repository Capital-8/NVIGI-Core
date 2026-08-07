# Building and Debugging

This document consolidates all instructions for building NVIGI Core and for debugging the resulting binaries locally or on a remote device.

## Platform Support

In addition to NVIGI Core's existing support for x64 devices, this release adds ARM64 platform support as an RTX Spark Developer Preview.  However, building on an ARM64 device is not currently supported; ARM64 binaries must be cross-compiled on an x64 machine, and debugging must be done remotely from an x64 host machine connected to the target ARM64 device.  There are additional requirements when building for and debugging ARM64 binaries; they are covered in the [Prerequisites](#prerequisites) section below.

Several scripts contained within the NVIGI Core repository have command-line parameters that allow you to specify which platform to target.  These scripts default to x64 if no platform is specified, but you may pass either `-x64` or `-arm64` to explicitly choose the target platform.

The following placeholders are used throughout this document:

- `<SDK_PLATFORM>`: the target CPU architecture.  Replace with either `x64` or `arm64`.
- `<Configuration>`: the build configuration.  Replace with `Debug`, `Release`, or `Production`.

> **NOTE:** NVIGI Core can also be used on an ARM64 device in x64 emulation mode.  In that case, use `x64` as the target platform and build on an x64 machine as normal.  The resulting x64 binaries run on the ARM64 device via Windows emulation.  Remote debugging is still required: the x64 machine acts as the debugging host and connects to `msvsmon.exe` running on the ARM64 device, exactly as described in the [Remote Debugging](#remote-debugging) section — the only difference is that the x64 build and x64 project settings are used rather than ARM64.

> **IMPORTANT:** The NVIGI 1.7.0 RTX Spark Developer Preview:
>- Does NOT support building for the ARM64 target the **core libraries** or the **plugins themselves** from the full source posted to GitHub.
>- DOES still support building the entire SDK (inc. core and plugins) x64 target from GitHub source
>- DOES support building the samples provided with the binary releases from the source in the release packs for either platform.
>- An upcoming full release for RTX Spark will add support for building the entire SDK including core libraries and the plugins themselves for ARM64 target from source.

> **IMPORTANT:** The RTX Spark Developer Preview does not support CiG - the 3D Samples currently disable CiG on Spark, and application developers should not enable CiG in their applications on Spark. Updates to the Spark driver and NVIGI SDK will be released later to enable CiG. Enabling CiG on the initial release may lead to application crashes.

## Prerequisites

| NVIGI Core          | Minimum                                                                                   | Recommended                    |
| :------------------- | :----------------------------------------------------------------------------------------- | :------------------------------- |
| GPU                 | RTX 30x0/A6000                                                                            | RTX 4080/4090 or RTX 5080/5090 |
| VRAM                | 8GB                                                                                       | 12GB                           |
| Windows             | Win11 22H2 (version 22H2 - 10.0.22621)                                                    |                                |
| Graphics Driver     | r555.85                                                                                   |                                |
| Development Tools   | VS2022 with [SDK 10.0.22621+](https://go.microsoft.com/fwlink/?linkid=2250105)            |                                |

> **NOTE:** Some plugins only support RTX 40x0 and above, and will not be available on RTX 30x0.

For ARM64 cross-compilation, the following additional requirements apply:

| Requirement                | Details                                                                                                                                                  |
| :-------------------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Visual Studio 2022         | Must include the **MSVC ARM64 build tools** component.  In the VS Installer, enable *Individual components → MSVC v143 - VS 2022 C++ ARM64 build tools*. |
| ARM64 target device        | A Windows on ARM device reachable over the network.                                                                                                      |
| Visual Studio Remote Tools | The ARM64 version of *Remote Tools for Visual Studio 2022* installed on the target device (needed for remote debugging).                                  |

## Building

### Setting Up the Build Environment

Open a **Visual Studio Developer Command Prompt** in the repo root directory (same directory as `README.md`) and run:

```sh
setup.bat [-x64|-arm64]
```

This causes two things to happen:

1. `packman` pulls all build dependencies to the local machine, caches them in a shared directory, and creates links from `external` in the NVIGI Core tree to this shared cache.
2. `premake` generates the project build files in `_project\vs2022`.

> **NOTE:** If `setup.bat` fails with an error from the `packman` package downloader, re-run `setup.bat` — there are rare but possible link-creation issues on the initial run.

> **NOTE:** You cannot mix x64 and ARM64 in the same `_project` tree.  To switch between architectures, re-run `setup.bat` with the appropriate flag (`-x64` or `-arm64`), which regenerates the project files.

### Building

To build, open `_project\vs2022\nvigicoresdk.sln` in Visual Studio, ensure that the **Platform** dropdown displays the correct target platform, select the desired build configuration, and build.  It is recommended to build all three configurations (Debug, Release, Production) as Core builds quickly.

The three build configurations are:

- **Release**: optimized build for local development and testing.
- **Debug**: unoptimized build with full debug symbols for stepping through code.
- **Production**: optimized build intended for distribution; debug output is suppressed.

> **NOTE:** Minimal OS configuration is needed to build — the specific Windows version and NVIDIA driver are runtime dependencies, not compile/link-time dependencies.  This allows NVIGI Core to build on stock virtual machines with zero configuration.

### Modifying Projects

> **IMPORTANT:** Do not edit the MSVC project files directly.  Always modify `premake.lua` or files in the `premake` directory.

When changing an existing project's settings (e.g. adding a source file, changing a compiler setting, or linking a new library), re-run `setup.bat` after making the changes, then reload the solution in the IDE.

> **NOTE:** NVIDIA does not recommend making changes to the headers in core, as these affect the API itself and can make developer-built components incompatible with NVIDIA-supplied components.

### Deploy to the Remote Device

> **NOTE:** This step is required whenever you intend to run or debug on a remote ARM64 device.  Skip it if you are running and debugging locally on the build machine.

Transfer `bin\<SDK_PLATFORM>\<Configuration>\` to the remote device using any mechanism — network share, `robocopy`, USB, etc.

Example using `robocopy` to deploy ARM64 binaries to a remote ARM64 device:

```sh
robocopy bin\arm64\<Configuration> \\<device-name>\share\nvigi\bin\arm64\<Configuration> /MIR
```

On the ARM64 device, open a command prompt in `bin\<SDK_PLATFORM>\<Configuration>\` and run the test:

```sh
nvigi.test.exe
```

## Debugging

### Local Debugging in Visual Studio

For local (x64) debugging, the test executable `nvigi.test.exe` is built directly into `bin\<SDK_PLATFORM>\<Configuration>\`.

#### One-Time Project Configuration

For the `tests\nvigi.test` project, in Visual Studio open the project properties (right-click the project → *Properties* → *Debugging*) and set:

| Property              | Value                                                                          |
| :--------------------- | :------------------------------------------------------------------------------ |
| **Command**           | `<repo-root>\bin\<SDK_PLATFORM>\<Configuration>\nvigi.test.exe`               |
| **Command Arguments** | Catch2 filter tags (optional, e.g. `[gpu]`)                                   |
| **Working Directory** | `<repo-root>\bin\<SDK_PLATFORM>\<Configuration>`                              |

> **NOTE:** These settings are stored in the `_project` directory and must be re-applied if `_project` is deleted and `setup.bat` is re-run.

#### Running the Test

After each build, launch the test either by pressing **F5** in VS2022 with the `nvigi.test` project set as the startup project, or from a command prompt in the repo root:

```sh
bin\<SDK_PLATFORM>\<Configuration>\nvigi.test.exe
```

Optional Catch2 tag filtering can be used to narrow which tests run, for example:

```sh
bin\<SDK_PLATFORM>\<Configuration>\nvigi.test.exe [gpu]
```

### Remote Debugging

When debugging ARM64 builds, Remote Debugging must be used: VS2022 on the x64 machine acts as the host debugger; `msvsmon.exe` on the ARM64 device acts as the remote debugger agent.

#### One-Time Setup on the Remote Device

1. Download **Remote Tools for Visual Studio 2022** for the ARM64 platform from the [Visual Studio downloads page](https://visualstudio.microsoft.com/downloads/#remote-tools-for-visual-studio-2022) and install them on the target device.
2. Launch the Remote Debugger: *Start Menu → Remote Debugger* (or run `msvsmon.exe` directly).
3. Note the **connection string** shown in the Remote Debugger window, e.g.:
   ```
   my-remote-device:4026
   ```
4. Ensure the firewall on the remote device allows inbound connections on the port shown (default: `4026`).

#### Configure Visual Studio on the Build (Host) Machine

1. In VS2022, open `_project\vs2022\nvigicoresdk.sln`.
2. Set the active platform to the target platform (e.g. `ARM64`) and the configuration to **Release** (or **Debug**).
3. Right-click the `nvigi.test` project → *Properties* → *Debugging*.
4. Set the following properties:

| Property               | Value                                                                                                                  |
| :---------------------- | :---------------------------------------------------------------------------------------------------------------------- |
| **Debugger to launch** | `Remote Windows Debugger`                                                                                              |
| **Remote Command**     | Full path (*on the remote device*) to the executable, e.g. `<device-path>\bin\arm64\<Configuration>\nvigi.test.exe`   |
| **Command Arguments**  | Catch2 filter tags if desired (e.g. `[gpu]`)                                                                          |
| **Working Directory**  | Path (*on the remote device*) to `bin\<SDK_PLATFORM>\<Configuration>`                                                 |
| **Remote Server Name** | The `msvsmon.exe` connection string, e.g. `my-remote-device:4026`                                                     |
| **Connection**         | `Remote with Windows Authentication` (adjust if the device is not domain-joined)                                       |

> **IMPORTANT:** All paths entered here are resolved on the **remote device**, not the build machine.

5. Click *OK* to save.

#### Starting a Remote Debug Session

1. Ensure the latest binaries are deployed to the remote device (re-run the [staging and deploy steps](#deploy-to-the-remote-device) after every build).
2. Verify `msvsmon.exe` is running on the remote device.
3. In VS2022 on the build machine, press **F5** (or *Debug → Start Debugging*).

VS2022 will connect to `msvsmon.exe`, upload symbol information, launch the executable on the remote device, and attach the debugger.  Breakpoints, watch windows, call stacks, and all other VS2022 debugger features work normally.

#### Attaching to a Running Process

If the test is already running on the remote device (e.g. to catch a startup race condition), use *Debug → Attach to Process*:

1. Set **Connection type** to `Remote with Windows Authentication` (or `Remote (no authentication)` as appropriate).
2. Set **Connection target** to the `msvsmon.exe` connection string.
3. Click **Find** to list processes running on the device.
4. Select `nvigi.test.exe` and click **Attach**.
