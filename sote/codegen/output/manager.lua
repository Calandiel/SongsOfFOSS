local ffi = require("ffi")
---manage dll loading

local dll_path = love.filesystem.getSourceBaseDirectory() .. "/sote/codegen/dll/win/"
-- local dll_path = "C:/_projects/dcon/DataContainer/x64/Release/"
DCON = ffi.load(dll_path .. "dcon.dll")
assert(DCON, "FAILED_TO_LOAD_DLL")

ffi.cdef[[
    void* calloc( size_t num, size_t size );
]]


DATA = require "codegen.output.generated"
require "codegen.output.helpers"