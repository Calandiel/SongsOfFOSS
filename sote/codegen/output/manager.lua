local ffi = require("ffi")
---manage dll loading

local dll_path = love.filesystem.getSourceBaseDirectory() .. "/sote/codegen/dll/win/"
DCON = ffi.load(dll_path .. "dcon.dll")

-- local dll_path = "C:/_projects/dcon/DataContainer/x64/Debug/"
-- DCON = ffi.load(dll_path .. "lua_dll_build_test.dll")

assert(DCON, "FAILED_TO_LOAD_DLL")

ffi.cdef[[
    void* calloc( size_t num, size_t size );
]]


DATA = require "codegen.output.generated"
require "codegen.output.helpers"