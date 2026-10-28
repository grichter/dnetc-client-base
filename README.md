distributed.net client (dnetc) public source framework
===================================================
This source will only allow you to compile a harness for testing and benchmarking the performance of cores.
It does not have the network or file buffer capabilities necessary to create a full client.

Building
--------
### Ok, I just downloaded it, now what must I do?
If you are on a Unix box, type `./configure list` and it will show a list of supported targets. If your
hardware/software isn't listed, look at how the configure script is made and write your own entry,
it's not very hard. Once configure has created a Makefile for you, just type `make` and the whole
thing will compile.

If you are building for a non-Unix box, you will have to look to see if there is a Makefile or Project
file suitable for your machine. Some common platforms are:
* `makefile.vc` (MS Visual C++)
* `makefile.wat` (Watcom for DOS, NetWare, Win16, OS/2, Win32cli)
* `smakefile` (Amiga)
* `plat/beos/*` (BeOS)
* `make-vms.com` (VMS)


### Windows x64 and x86 CPU harness

The plain `AMD64` and `x86` targets of `makefile.vc` build with Visual Studio
2022 Build Tools (tested with MSVC 14.44). `AMD64` assembles with YASM and
`x86` with NASM; both just need to be found, nothing is installed system-wide.
`HAVE_ISPC=0` skips the optional ISPC core (`ispc` is not needed otherwise).
`HAVE_OGR_CORES=1` adds the OGR-NG cores (off by default in the makefile).
The x86 OGR assembly builds with NASM 3.x (tested with 3.02).

```bat
rem AMD64: YASM= names the assembler (default: yasm on PATH)
call vcvarsall.bat x64
nmake /f makefile.vc PROCESSOR_ARCHITECTURE=AMD64 HAVE_ISPC=0 HAVE_OGR_CORES=1 YASM=<dir>\yasm-1.3.0-win64.exe

rem x86: needs nasm on PATH
call vcvarsall.bat x86
set PATH=%PATH%;C:\Program Files\NASM
nmake /f makefile.vc PROCESSOR_ARCHITECTURE=x86 HAVE_ISPC=0 HAVE_OGR_CORES=1
```

The program is `dnetc.exe` in the source root. Delete `output` between builds
of different targets and restore it with `git checkout -- output`. Run the
result from a scratch folder with `-test` and `-bench rc5-72` (or
`-bench ogr-ng`); `-bench` times every core in turn, which takes minutes.

### Windows 64-bit OpenCL benchmark harness

`PROCESSOR_ARCHITECTURE=OPENCL64` (and `OPENCL32`) build the harness with the
OpenCL RC5-72 cores for NVIDIA, AMD and Intel GPUs, using Visual Studio 2022
and the Khronos OpenCL headers. It needs no NASM or YASM. As in the ARM64
build, this source tree has no networking or work-buffer code, so use
`-gpuinfo`, `-test` and `-bench rc5-72`.

```bat
rem 1. headers: copy CL\*.h from github.com/KhronosGroup/OpenCL-Headers (v2024.10.24)
rem    to <opencldir>\include\CL
rem 2. import libraries from the installed driver's OpenCL.dll:
powershell -File plat\opencl\Make-OpenCLImportLibs.ps1 -OutDir <opencldir>
rem 3. build (use x86 and OPENCL32 for the 32-bit program):
call vcvarsall.bat x64
nmake /f makefile.vc PROCESSOR_ARCHITECTURE=OPENCL64 OPENCLDIR=<opencldir>\
```

`OPENCLDIR` must end in a backslash. Delete the `output` directory between
builds of different targets; the makefile does not separate them.
