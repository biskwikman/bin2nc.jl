module bin2nc

using NetCDF
using CairoMakie

function main()

    directory = "/home/dan/Work/julia/30km/modis_data/MOD11A2.005/MONTH/LST_Day"

    bin_files = get_bin_files(directory)

    bin_array = read_bin_files(bin_files)

end

function get_bin_files(directory::String)

    !Base.Filesystem.isdir(directory) ? 
        throw(DomainError(directory, "argument must be a directory")) : 
        nothing

    return Base.Filesystem.readdir(join=true, directory)
    
end

function read_bin_files(bin_files::Vector)

    var_array = Array{Union{Float32, Missing}, 3}(missing, 1440, 720, 12*length(bin_files))

    for (i, file) in enumerate(bin_files)
        year_array = Array{Float32, 3}(undef, 1440, 720, 12)
        read!(file, year_array)
        var_array[:,:,i*12-11:i*12] = year_array
    end

    replace!(var_array, -9999.0 => missing)
    reverse!(var_array; dims=2)

end

function convert_to_nc(bin_array) {
        lat = collect(-89.875, 89.875)
        lon = collect(-179.875, 179.875)
    }

# main()

end

