# Installation

## Step 1

download the zip file from the official download page
[https://ziglang.org/download/]

## Step 2

Extract the zig file

## Step 3

move the zip file to /usr/local

```
sudo mv zig-linux-x86_64-0.12.0-dev.1632+acf9de376 /usr/local/
```

## Step 4

Rename the folder containing zig to **_zig_**

```
mv ./zig-linux-x86_64-0.12.0-dev.1632+acf9de376 ./zig
```

## Step 5

Add the $PATH to bashrc

- go to the ~/.bashrc file

```
>> sudo nano ~/.bashrc
```

- add the path to zig at the end of the file

```
export PATH=$PATH:/usr/local/zig
```

- source the ~/.bashrc

```
>> source ~/.bashrc
```

- test the installation

```
>> zig
info: Usage: zig [command] [options]

Commands:

  build            Build project from build.zig
  fetch            Copy a package into global cache and print its hash
  init-exe         Initialize a `zig build` application in the cwd
  init-lib         Initialize a `zig build` library in the cwd

  ast-check        Look for simple compile errors in any set of files
  build-exe        Create executable from source or object files
  build-lib        Create library from source or object files
  build-obj        Create object from source or object files
  fmt              Reformat Zig source into canonical form
  run              Create executable and run immediately
  test             Create and run a test build
  translate-c      Convert C code to Zig code

  ar               Use Zig as a drop-in archiver
  cc               Use Zig as a drop-in C compiler
  c++              Use Zig as a drop-in C++ compiler
  dlltool          Use Zig as a drop-in dlltool.exe
  lib              Use Zig as a drop-in lib.exe
  ranlib           Use Zig as a drop-in ranlib
  objcopy          Use Zig as a drop-in objcopy
  rc               Use Zig as a drop-in rc.exe

  env              Print lib path, std path, cache directory, and version
  help             Print this help and exit
  libc             Display native libc paths file or validate one
  targets          List available compilation targets
  version          Print version number and exit
  zen              Print Zen of Zig and exit

General Options:

  -h, --help       Print command-specific usage

error: expected command argument
```
