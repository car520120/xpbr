local lib_path = path.join(os.projectdir(),"3rd","glbinding")
local lib_src =   path.join(lib_path,"source")
local lib_khr = path.join(lib_src,"3rdparty","KHR","include")
local lib_gbsrc = path.join(lib_src,"glbinding","source")
local lib_gbinc = path.join(lib_src,"glbinding","include","glbinding")
local lib_auxsrc = path.join(lib_src,"glbinding-aux","source")
local lib_auxinc = path.join(lib_src,"glbinding-aux","include","glbinding")



local cfg_dir = path.join(os.projectdir(),"build","config")
local cfg_gd = path.join(cfg_dir,"glbinding")
local cfg_gd_api = path.join(cfg_dir,"glbinding","glbinding_api.h")

local cfg_aux = path.join(cfg_dir,"glbinding-aux")
local cfg_aux_api = path.join(cfg_dir,"glbinding-aux","glbinding-aux_api.h")

local template = is_plat("windows") and "template_msvc_api.h.in" or "template_api.h.in"
local lib_gd_api = path.join(lib_src,"codegeneration",template)
local is_gd_cfg = false == os.isfile(cfg_gd_api)
local is_aux_cfg = false == os.isfile(cfg_aux_api)

local gb_src = [[
    getProcAddress.cpp
    glbinding.cpp
    Binding.cpp
    Binding_list.cpp
    glbinding.cpp
    gl/functions-patches.cpp

    AbstractFunction.cpp
    AbstractState.cpp
    AbstractValue.cpp
    FunctionCall.cpp
    State.cpp
]]

local gb_inc = [[
    nogl.h
    getProcAddress.h

    gl/bitfield.h
    gl/boolean.h
    gl/enum.h
    gl/extension.h
    gl/functions.h
    gl/types.h
    gl/types.inl
    gl/values.h

    glbinding.h

    glbinding.h
    AbstractFunction.h
    CallbackMask.h
    Function.h
    FunctionCall.h
    Binding.h
    ProcAddress.h
    Value.h
    Version.h
    Version.inl
    SharedBitfield.h
    AbstractFunction.h
    AbstractState.h
    AbstractValue.h
    Boolean8.h
    Boolean8.inl
    CallbackMask.h
    CallbackMask.inl
    ContextHandle.h
    Function.h
    Function.inl
    FunctionCall.h
    ProcAddress.h
    SharedBitfield.h
    SharedBitfield.inl
    State.h
    Value.h
    Value.inl
    Version.h
    Version.inl
]]

local gb_cpp = [[
    Binding_objects_*.cpp
    gl/functions_*.cpp
]]


local aux_src = [[
    ContextInfo.cpp

    Meta.cpp
    Meta_getStringByBitfield.cpp
    Meta_BitfieldsByString.cpp
    Meta_BooleansByString.cpp
    Meta_EnumsByString.cpp
    Meta_ExtensionsByFunctionString.cpp
    Meta_ExtensionsByString.cpp
    Meta_FunctionStringsByExtension.cpp
    Meta_FunctionStringsByVersion.cpp
    Meta_ReqVersionsByExtension.cpp
    Meta_StringsByBitfield.cpp
    Meta_StringsByBoolean.cpp
    Meta_StringsByEnum.cpp
    Meta_StringsByExtension.cpp

    ValidVersions_list.cpp

    debug.cpp
    logging.cpp

    types_to_string.cpp
    types_to_string_private.cpp

    types_to_string.cpp
    ValidVersions.cpp
]]

local aux_irc = [[
    Meta_Maps.h
    types_to_string_private.h
    logging_private.h
]]
local aux_inc = [[
    ContextInfo.h
    Meta.h

    ValidVersions.h

    debug.h
    logging.h

    types_to_string.h
    types_to_string.inl

    RingBuffer.h
    RingBuffer.inl
    ValidVersions.h
    types_to_string.h
]]

-- local function chk_empty(ss)
--     return (1 + #ss) == ss:match("^%s*()")
-- end

local function unpack_files(src,ss)
    local  result = {}
    if not ss then
        return result
    end

    local pattern = "[^%s]+"

    string.gsub(ss,pattern,function(s)
        result[#result + 1] = path.join(src,s)
    end)
    return table.unpack(result)
end

local function chk_files(src,...)
    local mt = table.pack(...)
    for _,ss in ipairs(mt) do
        add_files(unpack_files(src,ss))
    end
end

local function chk_inc(src,...)
    local mt = table.pack(...)
    for _,ss in ipairs(mt) do
        add_headerfiles(unpack_files(src,ss))
    end
end
local function api_export_inc(decl)
    local aei = [[
        #ifndef ${decl}_API_H
        #define ${decl}_API_H

        #ifdef ${decl}_STATIC_DEFINE
        #  define ${decl}_API
        #  define ${decl}_NO_EXPORT
        #else
        #  ifndef ${decl}_API
        #    ifdef ${decl}_EXPORTS
                /* We are building this library */
        #      define ${decl}_API __declspec(dllexport)
        #    else
                /* We are using this library */
        #      define ${decl}_API __declspec(dllimport)
        #    endif
        #  endif

        #  ifndef ${decl}_NO_EXPORT
        #    define ${decl}_NO_EXPORT 
        #  endif
        #endif

        #ifndef ${decl}_DEPRECATED
        #  define ${decl}_DEPRECATED __declspec(deprecated)
        #endif

        #ifndef ${decl}_DEPRECATED_EXPORT
        #  define ${decl}_DEPRECATED_EXPORT ${decl}_API ${decl}_DEPRECATED
        #endif

        #ifndef ${decl}_DEPRECATED_NO_EXPORT
        #  define ${decl}_DEPRECATED_NO_EXPORT ${decl}_NO_EXPORT ${decl}_DEPRECATED
        #endif

        #if 0 /* DEFINE_NO_DEPRECATED */
        #  ifndef ${decl}_NO_DEPRECATED
        #    define ${decl}_NO_DEPRECATED
        #  endif
        #endif

        #endif /* ${decl}_API_H */
    ]]
    return  string.gsub(aei, "(.-)\n", function(ss)
        local s,n = string.gsub(ss, "%s+#(.-)","#%1")
        if 0 < n then
            local ds = string.gsub(s, "${decl}", decl)
            return ds .. "\n"
        else
            if 2 < #ss then
                return string.gsub(s, "%s+(.+)", "        %1\n")
            else
                return "\n"
            end
        end
    end)
end

if is_gd_cfg then
    option("gd_env")
        before_check(function(op)
            if os.isfile(cfg_gd_api) then
                return
            end

            if not os.isdir(cfg_gd) then
                os.mkdir(cfg_gd)
            end
            local decl_src = path.join(lib_src,"codegeneration")
            local decl_features = path.join(decl_src,"glbinding_features.h")
            os.cp(decl_features,cfg_gd)

            local cfg_export = path.join(cfg_gd,"glbinding_export.h")
            local content = api_export_inc("GLBINDING")
            io.writefile(cfg_export,content)
        end)
    option_end()
end

target("glbinding")
    set_kind("shared")
    chk_files(lib_gbsrc, gb_src,gb_cpp)
    chk_inc(lib_gbinc,gb_inc,"gl*/*.h")
    chk_inc(lib_gbsrc,"Binding_pch.h")
    add_includedirs(path.join(lib_src,"glbinding","include") ,cfg_dir,lib_khr,{public = true})
    if is_plat("windows") then
        add_defines("SYSTEM_WINDOWS")
    end
    if is_gd_cfg then
        add_configfiles(lib_gd_api,{filename="glbinding_api.h"})
        set_configdir(cfg_gd)
        add_options("gd_env")
        set_configvar("target_id","GLBINDING",{quote = false})
        set_configvar("target","glbinding",{quote = false})
    end
    on_load(function(target)
        if is_plat("windows") then
            if "shared" == target:get("kind") then
                target:add("defines","GLBINDING_EXPORTS")
            else
                target:add("defines","GLBINDING_STATIC_DEFINE")
            end
        end
    end)
target_end()

if is_aux_cfg then
    option("aux_env")
        before_check(function(op)
            if os.isfile(cfg_aux_api) then
                return
            end

            if not os.isdir(cfg_aux) then
                os.mkdir(cfg_aux)
            end
            local decl_src = path.join(lib_src,"codegeneration")
            local decl_features = path.join(decl_src,"glbinding_features.h")
            os.cp(decl_features,path.join(cfg_aux,"glbinding-aux_features.h"))

            local cfg_export = path.join(cfg_aux,"glbinding-aux_export.h")
            local content = api_export_inc("GLBINDING_AUX")
            io.writefile(cfg_export,content)
        end)
    option_end()
end

target("glbinding-aux")
    set_kind("shared")
    add_deps("glbinding")
    chk_files(lib_auxsrc, aux_src)
    chk_inc(lib_auxsrc,aux_irc)
    chk_inc(lib_auxinc,aux_inc)
    add_includedirs(path.join(lib_src,"glbinding-aux","include"),{public = true})
    if is_plat("windows") then
        add_defines("SYSTEM_WINDOWS")
    end
    if is_aux_cfg then
        add_configfiles(lib_gd_api,{filename="glbinding-aux_api.h"})
        set_configdir(cfg_aux)
        add_options("aux_env")
        set_configvar("target_id","GLBINDING_AUX",{quote = false})
        set_configvar("target","glbinding-aux",{quote = false})
    end
    on_load(function(target)
        if is_plat("windows") then
            if "shared" == target:get("kind") then
                target:add("defines","GLBINDING_AUX_EXPORTS")
            else
                target:add("defines","GLBINDING_AUX_STATIC_DEFINE")
            end
        end
    end)
target_end()