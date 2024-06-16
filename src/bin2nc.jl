module bin2nc
using NetCDF

# function main()
#     directory = "/media/storage/Work/30km/modis_data"
#     get_bin_files(directory)
# end

function get_bin_files(directory::String)
    !Base.Filesystem.isdir(directory) ? 
        throw(DomainError(directory, "argument must be a directory")) : 
        nothing

    dir_files = Base.Filesystem.readdir(directory)
    println("ok")
    
end

# main()

end

