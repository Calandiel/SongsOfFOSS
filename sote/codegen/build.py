"""
Handles build of DataContainer:
https://github.com/schombert/DataContainer
"""
import os
import subprocess
from pathlib import Path
from shutil import copyfile, move

codegen_path = Path().absolute().joinpath("sote").joinpath("codegen")

description_path = \
    codegen_path.joinpath("dcon").joinpath("sote.txt")

repo_folder = Path().absolute().joinpath("DataContainer")

generation_folder = repo_folder.joinpath("lua_dll_build_test")
dll_generator_folder = repo_folder.joinpath("LuaDLLGenerator")


common_include = repo_folder.joinpath("CommonIncludes")

description_destination = \
    generation_folder.joinpath("objs.txt")

generator_exe = \
    generation_folder.joinpath("DataContainerGenerator.exe")

dll_generator_exe = \
    generation_folder.joinpath("LuaDLLGenerator.exe")

copyfile(description_path, description_destination)




subprocess.run([generator_exe, description_destination], check=True)

print("compiling dll source code generator")
subprocess.run([ \
    "clang++",
    "-std=c++20",
    dll_generator_folder.joinpath("*.cpp"), \
    # f"-o \"{generation_folder.joinpath('dll_code_gen.exe')}\"",
], check=True, shell=True)

move("a.exe", dll_generator_exe)
subprocess.run([dll_generator_exe, description_destination], check=True)

# compile dll itself
for file in os.listdir(common_include):
    copyfile(common_include.joinpath(file), generation_folder.joinpath(file))

dll_folder = codegen_path.joinpath("dll")
if os.name == 'nt':
    print("compiling dll")
    subprocess.run([ \
        "clang++",
        "-std=c++20",
        "-shared",
        generation_folder.joinpath("lua_objs.cpp"),
        "-o", "dcon.dll"
    ], check=True, shell=True)

    dll_folder = dll_folder.joinpath("win")
    move("./dcon.dll", dll_folder.joinpath("dcon.dll"))
    move("./dcon.exp", dll_folder.joinpath("dcon.exp"))
    move("./dcon.lib", dll_folder.joinpath("dcon.lib"))
else:
    # TODO
    dll_folder = dll_folder.joinpath("linux")
    # move("dcon.so")
