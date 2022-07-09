local lib_path = path.join(os.projectdir(),"3rd","stb") 

target("stb")
    set_group("lib3rd")
    set_kind("headeronly")
    add_includedirs(lib_path,{public = true})
    add_headerfiles(path.join(lib_path,"*.h"))