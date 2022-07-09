local lib_path = path.join(os.projectdir(),"3rd","glfw")
local function chk_files(...)
    local mt = table.pack(...)
    local t = {}
    for _,fn in ipairs(mt) do
        table.insert(t,path.join(lib_path,fn))
    end
    add_files(table.unpack(t))
end

target("glfw")
    set_group("lib3rd")
    set_kind("static")
    chk_files(
        "src/context.c",
        "src/egl_context.c",
        "src/init.c",
        "src/input.c",
        "src/monitor.c",
        "src/osmesa_context.c",
        "src/vulkan.c",
        "src/window.c"
    )

    add_includedirs(path.join(lib_path,"include"),{public = true})

    if is_os("windows") then
        add_defines("_GLFW_WIN32")
        chk_files(
            "src/win32_*.c",
            "src/wgl_context.c"
        )
    elseif is_os("linux") then
        add_defines("_GLFW_X11")
        chk_files(
            "src/glx_context.c",
            "src/linux*.c",
            "src/posix*.c",
            "src/x11*.c",
            "src/xkb*.c"
        )
    elseif is_os("macosx") then
        add_defines("_GLFW_COCOA")
        chk_files(
            "src/cocoa_*.c",
            "src/cocoa_*.m",
            "src/posix_thread.c",
            "src/nsgl_context.m",
            "src/egl_context.c",
            "src/nsgl_context.m",
            "src/osmesa_context.c"
        )
    end