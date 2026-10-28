# Makes OpenCL.lib import libraries (x64 and x86) for the OPENCL64 / OPENCL32
# targets of makefile.vc, from the OpenCL.dll installed with the GPU driver,
# and lays them out the way makefile.vc expects:
#   <OutDir>\include\CL\*.h        (Khronos OpenCL-Headers, copied by you)
#   <OutDir>\lib\x86_64\OpenCL.lib
#   <OutDir>\lib\x86\OpenCL.lib
# Usage: .\plat\opencl\Make-OpenCLImportLibs.ps1 -OutDir Z:\workspace\dnetc-deps\opencl
# Needs the Visual Studio C++ build tools. Only the OpenCL 1.x/2.x entry points
# are used by the client; the x86 list below is exactly what it links against.
param([Parameter(Mandatory)][string]$OutDir)
$ErrorActionPreference = 'Stop'
function Log($m) { Write-Host ("{0:HH:mm:ss} {1}" -f (Get-Date), $m) }
$vs = & "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -property installationPath
$vcvars = Join-Path $vs 'VC\Auxiliary\Build\vcvarsall.bat'
$tmp = Join-Path $env:TEMP 'dnetc-oclimp'
New-Item -ItemType Directory -Force $tmp, "$OutDir\lib\x86_64", "$OutDir\lib\x86" | Out-Null

Log 'x64: import library from the exports of System32\OpenCL.dll'
$names = cmd /c "call `"$vcvars`" x64 >nul 2>&1 && dumpbin /exports C:\Windows\System32\OpenCL.dll" |
    Where-Object { $_ -match '^\s+\d+\s+[0-9A-F]+\s+[0-9A-F]+\s+(\w+)' } | ForEach-Object { $Matches[1] }
Set-Content "$tmp\x64.def" (@('LIBRARY OpenCL', 'EXPORTS') + $names) -Encoding ascii
cmd /c "call `"$vcvars`" x64 >nul 2>&1 && lib /nologo /def:$tmp\x64.def /machine:X64 /out:$OutDir\lib\x86_64\OpenCL.lib"

# x86 entry points are __stdcall (_name@N), so the arguments' byte counts are needed.
Log 'x86: import library from stdcall stubs'
$args32 = @{
 clBuildProgram=24; clCreateBuffer=24; clCreateCommandQueue=20; clCreateContext=24; clCreateKernel=12
 clCreateProgramWithSource=20; clEnqueueMapBuffer=44; clEnqueueNDRangeKernel=36; clEnqueueUnmapMemObject=24
 clGetDeviceIDs=24; clGetDeviceInfo=20; clGetEventProfilingInfo=20; clGetKernelWorkGroupInfo=24
 clGetPlatformIDs=12; clGetPlatformInfo=20; clGetProgramBuildInfo=24; clReleaseCommandQueue=4
 clReleaseContext=4; clReleaseEvent=4; clReleaseKernel=4; clReleaseMemObject=4; clReleaseProgram=4
 clSetKernelArg=16; clWaitForEvents=8
}
$c = ($args32.GetEnumerator() | ForEach-Object { "struct A_$($_.Key){char c[$($_.Value)];}; void __stdcall $($_.Key)(struct A_$($_.Key) a){}" }) -join "`n"
Set-Content "$tmp\stub.c" $c -Encoding ascii
Set-Content "$tmp\stub.def" (@('LIBRARY OpenCL', 'EXPORTS') + $args32.Keys) -Encoding ascii
cmd /c "call `"$vcvars`" x86 >nul 2>&1 && cd /d $tmp && cl /nologo /c stub.c && link /nologo /dll /noentry /nodefaultlib /def:stub.def /out:stub.dll /implib:$OutDir\lib\x86\OpenCL.lib stub.obj"
Log "done: $OutDir"
