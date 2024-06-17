module bin2nc

using NetCDF
# using CairoMakie

function main()

    directory = "/home/dan/Work/julia/30km/modis_data/MOD11A2.005/MONTH/LST_Day"

    bin_files = get_bin_files(directory)

    (bin_array, years) = read_bin_files(bin_files)

    convert_to_nc(bin_array, years)

end

function get_bin_files(directory::String)

    !Base.Filesystem.isdir(directory) ? 
        throw(DomainError(directory, "argument must be a directory")) : 
        nothing

    return Base.Filesystem.readdir(join=true, directory)
    
end

function read_bin_files(bin_files::Vector)

    years = length(bin_files)

    var_array = Array{Union{Float32, Missing}, 3}(missing, 1440, 720, 12*years)

    for (i, file) in enumerate(bin_files)
        year_array = Array{Float32, 3}(undef, 1440, 720, 12)
        read!(file, year_array)
        var_array[:,:,i*12-11:i*12] = year_array
    end

    replace!(var_array, -9999.0 => missing)
    (reverse!(var_array; dims=2), years)

end

function convert_to_nc(bin_array, years) 
        lat = collect(-89.875:89.875)
        lon = collect(-179.875:179.875)
        tim = collect(0:12*years-1)

        varatts = Dict("longname" => "Gross Primary Product", "units" => "gC/m^2/day")
        lonatts = Dict("longname" => "Longitude", "units" => "degrees east")
        latatts = Dict("longname" => "Latitude", "units" => "degrees north")
        timatts = Dict("longname" => "Time", "units" => "months since 2000-01-01 00:00:00")

        nccreate("zzz.nc", "gpp", "lon", lon, lonatts, "lat", lat, latatts, "time", tim, timatts, atts=varatts)

        ncwrite(bin_array, "zzz.nc", "gpp")
end

# main()

end

