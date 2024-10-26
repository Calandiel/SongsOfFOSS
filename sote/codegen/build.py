"""
Handles build of DataContainer:
https://github.com/schombert/DataContainer
"""
import os
import subprocess
from pathlib import Path
from shutil import copyfile, move

COMPILE_DCON_GEN = False
COMPILE_LUA_GEN = False

codegen_path = Path().absolute().joinpath("sote").joinpath("codegen")

description_path = \
    codegen_path.joinpath("dcon").joinpath("sote.txt")

additional_types_header = \
    codegen_path.joinpath("dcon").joinpath("sote_types.hpp")
additional_functions_source = \
    codegen_path.joinpath("dcon").joinpath("sote_functions.cpp")
additional_functions_header = \
    codegen_path.joinpath("dcon").joinpath("sote_functions.hpp")

repo_folder = Path().absolute().joinpath("DataContainer")

generation_folder = repo_folder.joinpath("lua_dll_build_test")
dcon_generator_folder = repo_folder.joinpath("DataContainerGenerator")
dll_generator_folder = repo_folder.joinpath("LuaDLLGenerator")


common_include = repo_folder.joinpath("CommonIncludes")

description_destination = \
    generation_folder.joinpath("objs.txt")

additional_types_destination = \
    generation_folder.joinpath("sote_types.hpp")
additional_functions_src_destination = \
    generation_folder.joinpath("sote_functions.cpp")
additional_functions_header_destination = \
    generation_folder.joinpath("sote_functions.hpp")

generator_exe = \
    generation_folder.joinpath("DataContainerGenerator.exe")

dll_generator_exe = \
    generation_folder.joinpath("LuaDLLGenerator.exe")

copyfile(description_path, description_destination)
copyfile(additional_types_header, additional_types_destination)
copyfile(additional_functions_source, additional_functions_src_destination)
copyfile(additional_functions_header, additional_functions_header_destination)


if COMPILE_DCON_GEN:
    print("compiling datacontainer")
    subprocess.run([ \
        "clang++",
        "-std=c++20",
        dcon_generator_folder.joinpath("*.cpp"),
        "-o", "a.exe",
        # f"-o \"{generation_folder.joinpath('dll_code_gen.exe')}\"",
    ], check=True, shell=True)
    move("a.exe", generator_exe)

subprocess.run([generator_exe, description_destination], check=True)

if COMPILE_LUA_GEN:
    print("compiling dll source code generator")
    subprocess.run([ \
        "clang++",
        "-std=c++20",
        dll_generator_folder.joinpath("*.cpp"),
        "-o", "a.exe",
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
        "-O3",
        "-std=c++20",
        "-msse4.1",
        "-shared",
        # "-DDCON_LUADLL_EXPORTS",
        generation_folder.joinpath("lua_objs.cpp"),
        generation_folder.joinpath("common_types.cpp"),
        additional_functions_src_destination,
        "-o", "dcon.dll",
    ], check=True, shell=True)

    dll_folder = dll_folder.joinpath("win")
    move("./dcon.dll", dll_folder.joinpath("dcon.dll"))
    move("./dcon.exp", dll_folder.joinpath("dcon.exp"))
    move("./dcon.lib", dll_folder.joinpath("dcon.lib"))
else:
    # TODO
    dll_folder = dll_folder.joinpath("linux")
    # move("dcon.so")
