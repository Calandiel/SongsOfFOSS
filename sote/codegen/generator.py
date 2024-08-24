"""
Code generator of Songs of GPL data manager.
Creates properly typed LUA bindings for these arrays.
Handles (de)serialisation routines.
"""

import typing
import random

DESCRIPTION_PATH = "./sote/codegen/description"
OUTPUT_PATH = "./sote/codegen/output/generated.lua"
NAMESPACE = "DATA"
SAVE_FILE_NAME_LUA = "gamestatesave.bitserbeaver"
SAVE_FILE_NAME_FFI = "gamestatesave.binbeaver"

def prefix_to_id_name(prefix: str):
    """
    Returns symbol for id for given prefix
    """

    return f'{prefix}_id'

class EntityField:
    """
    Description of entity field
    """
    prefix: str
    name: str
    type: str
    lsp_type: str
    description: str
    is_ctype: bool

    def __init__(self, prefix, name, field_type, description) -> None:
        self.prefix = prefix
        self.name = name
        self.type = field_type

        if field_type in ["int32_t", "uint32_t", "float"]:
            self.lsp_type = "number"
            self.is_ctype = True
        elif field_type in ["bool"]:
            self.lsp_type = "boolean"
            self.is_ctype = True
        else:
            self.lsp_type = field_type
            self.is_ctype = False

        self.description = description

    def local_var_name(self):
        """
        Returns a name of local variable responsible for pointer to array with this field
        """
        return f'{self.prefix}_{self.name}'

    def array_string(self, max_count: int):
        """
        Generates description of ffi array
        """

        lsp_table_type = f'---@type ({self.lsp_type})[]\n'
        declaration = f'local {self.local_var_name()}'
        if self.is_ctype:
            return lsp_table_type + declaration + f'= ffi.new("{self.type}[?]", {max_count})\n'
        return lsp_table_type + declaration + '= {}\n'

    def getter_name(self):
        return f"{NAMESPACE}.{self.prefix}_get_{self.name}"

    def setter_name(self):
        return f"{NAMESPACE}.{self.prefix}_set_{self.name}"

    def lua_getter(self):
        """
        Returns a string with getter binding
        """
        arg = prefix_to_id_name(self.prefix)

        return  f"---@param {arg} {prefix_to_id_name(self.prefix)} valid {self.prefix} id\n" \
                f"---@return {self.lsp_type} {self.name} {self.description}\n" \
                f"function {self.getter_name()}({arg})\n" \
                f"    return {self.local_var_name()}[{arg}]\n" \
                f"end\n"

    def lua_setter(self):
        """
        Returns a string with setter binding
        """
        arg = prefix_to_id_name(self.prefix)

        return  f"---@param {arg} {prefix_to_id_name(self.prefix)} valid {self.prefix} id\n" \
                f"---@param value {self.lsp_type} value\n" \
                f"function {self.setter_name()}({arg}, value)\n" \
                f"    {self.local_var_name()}[{arg}] = value\n" \
                f"end\n"

    def lua_bindings(self):
        """
        Returns a string with all according bindings
        """
        return f'{self.lua_getter()}{self.lua_setter()}'

class EntityDescription:
    """
    Description of entity fields
    """
    name: str
    max_count: int
    fields: typing.List[EntityField]

    def __init__(self, name, max_count) -> None:
        self.name = name
        self.max_count = max_count
        self.fields = []

        ENTITY_LIST.append(self)

        with open(f"{DESCRIPTION_PATH}/{name}.txt", "r", encoding="utf8") as file:
            for line in file.readlines():
                line_splitted = line.strip().split(" ")
                name = line_splitted[0]
                field_type = line_splitted[1]
                description = " ".join(line_splitted[2:])

                self.fields.append(EntityField(self.name, name, field_type, description))

    def __str__(self) -> str:
        result = f"----------{self.name}----------\n\n"

        result += f"\n---{self.name}: LSP types---\n"
        #id
        result += f'---@alias {prefix_to_id_name(self.name)} number\n'
        #fat id
        result += f'---@class fat_{prefix_to_id_name(self.name)}\n'
        result += f'---@field id {prefix_to_id_name(self.name)} Unique {self.name} id\n'
        for field in self.fields:
            result += f'---@field {field.name} {field.lsp_type} {field.description}\n'

        # arrays
        result += f"\n---{self.name}: FFI arrays---\n"
        for field in self.fields:
            result += field.array_string(self.max_count)

        result += f"\n---{self.name}: LUA bindings---\n"

        #bindings lua
        for field in self.fields:
            result += field.lua_bindings()

        #metatable

        result += f"local fat_{prefix_to_id_name(self.name)}_metatable = {{\n"

        result += "    __index = function (t,k)\n"
        for field in self.fields:
            result += f"        if (k == \"{field.name}\") then return {field.getter_name()}(t.id) end\n"
        result += "        return rawget(t, k)\n"
        result += "    end,\n"

        result += "    __newindex = function (t,k,v)\n"
        for field in self.fields:
            result += f"        if (k == \"{field.name}\") then\n"
            result += f"            {field.setter_name()}(t.id, v)\n"
            result += "        end\n"
        result += "        rawset(t, k, v)\n"
        result += "    end\n"

        result += "}\n"

        #fat id
        result += f'---@param id {prefix_to_id_name(self.name)}\n'
        result += f'---@return fat_{prefix_to_id_name(self.name)} fat_id\n'
        result += f"function {NAMESPACE}.fatten_{self.name}(id)\n"
        result +=  "    local result = {id = id}\n"
        result += f"    setmetatable(result, fat_{prefix_to_id_name(self.name)}_metatable)"
        result +=  "    return result\n"
        result +=  "end\n"
        return result

ENTITY_LIST: typing.List[EntityDescription] = []

def auxiliary_types():
    """
    Generates helper types for lsp
    """

    result = "\n"

    result += "---@class LuaDataBlob\n"
    for entity in ENTITY_LIST:
        for field in entity.fields:
            if not field.is_ctype:
                result += f"---@field {field.local_var_name()} ({field.lsp_type})[]\n"

    result += "\n"

    return result




def save_state():
    """
    Generates routine which saves state in two files:\n
    One for c arrays -- fast\n
    And another one for lua tables -- slow
    """
    result = f"function {NAMESPACE}.save_state()\n"
    result += "    local current_lua_state = {}\n"

    for entity in ENTITY_LIST:
        for field in entity.fields:
            if not field.is_ctype:
                result += f"    current_lua_state.{field.local_var_name()} = {field.local_var_name()}\n"

    result += f"\n    bitser.dumpLoveFile(\"{SAVE_FILE_NAME_LUA}\", current_lua_state)\n\n"

    result += "    local current_offset = 0\n"
    result += "    local current_shift = 0\n"
    result += "    local total_ffi_size = 0\n"

    for entity in ENTITY_LIST:
        for field in entity.fields:
            if field.is_ctype:
                result += f'    total_ffi_size = total_ffi_size + ffi.sizeof("{field.type}") * {entity.max_count}\n'

    result += "    local current_buffer = ffi.new(\"uint8_t[?]\", total_ffi_size)\n"

    for entity in ENTITY_LIST:
        for field in entity.fields:
            if field.is_ctype:
                result += f'    current_shift = ffi.sizeof("{field.type}") * {entity.max_count}\n'
                result +=   f'    ffi.copy(current_buffer + current_offset,' \
                            f" {field.local_var_name()}, current_shift)\n"
                result += "    current_offset = current_offset + current_shift\n"

    result += f"assert(love.filesystem.write(\"{SAVE_FILE_NAME_FFI}\", ffi.string(current_buffer, total_ffi_size)))"

    result += "end\n"
    return result

def load_state():
    """
    Generates routine which saves state in two files:\n
    One for c arrays -- fast\n
    And another one for lua tables -- slow
    """
    result = f"function {NAMESPACE}.load_state()\n"
    result += "    ---@type LuaDataBlob|nil\n"
    result += f"    local loaded_lua_state = bitser.loadLoveFile(\"{SAVE_FILE_NAME_LUA}\")\n"
    result += "    assert(loaded_lua_state)\n"

    for entity in ENTITY_LIST:
        for field in entity.fields:
            if not field.is_ctype:
                result += f"    for key, value in pairs(loaded_lua_state.{field.local_var_name()}) do\n"
                result += f"        {field.local_var_name()}[key] = value\n"
                result += "    end\n"

    result += f"    local data_love, error = love.filesystem.newFileData(\"{SAVE_FILE_NAME_FFI}\")\n"
    result += "    assert(data_love, error)\n"
    result += "    local data = ffi.cast(\"uint8_t*\", data_love:getPointer())\n"
    result += "    local current_offset = 0\n"
    result += "    local current_shift = 0\n"
    result += "    local total_ffi_size = 0\n"

    for entity in ENTITY_LIST:
        for field in entity.fields:
            if field.is_ctype:
                result += f'    total_ffi_size = total_ffi_size + ffi.sizeof("{field.type}") * {entity.max_count}\n'

    # result += "    local current_buffer = ffi.new(\"uint8_t[?]\", total_ffi_size)\n"

    for entity in ENTITY_LIST:
        for field in entity.fields:
            if field.is_ctype:
                result += f'    current_shift = ffi.sizeof("{field.type}") * {entity.max_count}\n'
                result +=   f'    ffi.copy({field.local_var_name()},' \
                            " data + current_offset, current_shift)\n"
                result += "    current_offset = current_offset + current_shift\n"

    result += "end\n"
    return result

def tests():
    """
    Generates tests for generated code
    """
    result = ""
    for i in range(3):
        result += f"function {NAMESPACE}.test_save_load_{i}()\n"

        # generate data
        random.seed(i)
        for entity in ENTITY_LIST:
            for field in entity.fields:
                if field.is_ctype:
                    value = str(random.randint(0, 255))
                    if field.type == "bool":
                        if int(value) % 2 == 0:
                            value = "true"
                        else:
                            value = "false"
                    result += f"    for i = 0, {entity.max_count} do\n"
                    result += f"        {field.local_var_name()}[i] = {value}\n"
                    result +=  "    end\n"

        # checks
        result += f"    {NAMESPACE}.save_state()\n"
        result += f"    {NAMESPACE}.load_state()\n"

        result +=  "    local test_passed = true\n"

        random.seed(i)
        for entity in ENTITY_LIST:
            for field in entity.fields:
                if field.is_ctype:
                    value = str(random.randint(0, 255))
                    if field.type == "bool":
                        if int(value) % 2 == 0:
                            value = "true"
                        else:
                            value = "false"
                    result += f"    for i = 0, {entity.max_count} do\n"
                    result += f"        test_passed = test_passed or {field.local_var_name()}[i] == {value}\n"
                    result +=  "    end\n"

        result += f"    print(\"SAVE_LOAD_TEST_{i}:\")\n"
        result +=  "    if test_passed then print(\"PASSED\") else print(\"ERROR\") end\n"
        result += "end\n"

        result += f"function {NAMESPACE}.test_set_get_{i}()\n"


        for entity in ENTITY_LIST:
            result += f"    local fat_id = {NAMESPACE}.fatten_{entity.name}(0)\n"
            random.seed(i)
            for field in entity.fields:
                if field.is_ctype:
                    value = str(random.randint(0, 255))
                    if field.type == "bool":
                        if int(value) % 2 == 0:
                            value = "true"
                        else:
                            value = "false"
                    result += f"    fat_id.{field.name} = {value}\n"
            result += "    local test_passed = true\n"
            random.seed(i)
            for field in entity.fields:
                if field.is_ctype:
                    value = str(random.randint(0, 255))
                    if field.type == "bool":
                        if int(value) % 2 == 0:
                            value = "true"
                        else:
                            value = "false"
                    result += f"    test_passed = test_passed or fat_id.{field.name} == {value}\n"

            result += f"    print(\"SET_GET_TEST_{i}_{entity.name}:\")\n"
            result +=  "    if test_passed then print(\"PASSED\") else print(\"ERROR\") end\n"
            result += "end\n"

    return result


TileDescription = EntityDescription("tile", 600 * 600 * 6)

with open(OUTPUT_PATH, "w", encoding="utf8") as out:
    out.write('local ffi = require("ffi")\n')
    out.write('local bitser = require("engine.bitser")\n')
    out.write("\n")
    out.write(f'{NAMESPACE} = {{}}\n')
    for entity in ENTITY_LIST:
        out.write(str(entity))

    out.write(auxiliary_types())
    out.write(save_state())
    out.write(load_state())
    out.write(tests())

    out.write(f'return {NAMESPACE}\n')