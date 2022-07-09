
add_rules("mode.debug", "mode.release", "asm")

set_project("xpbr")
-- set_languages("cxx14")
if is_mode("debug") then
    set_suffixname("_d")
end

if is_plat("windows") then
    if is_mode("debug") then
        set_runtimes("MDd")
    else
        set_runtimes("MD")
    end
end

local function chk_3rd_inc(...)
    local mt = table.pack(...)
    local t = {}
    for _,fn in ipairs(mt) do
        table.insert(t,path.join("xmgr",fn))
    end
    includes(table.unpack(t))
end

chk_3rd_inc("glfw.lua","glm.lua","glbinding.lua","stb.lua")

target("game")
    set_kind("binary")
    set_default(true)
    add_deps("glfw","glm","glbinding-aux","stb")
    add_files("src/**.cpp")
    add_defines("GLFW_INCLUDE_NONE","GLM_ENABLE_EXPERIMENTAL")
    add_syslinks("gdi32", "shell32", "user32")
    set_rundir("$(projectdir)")

    
