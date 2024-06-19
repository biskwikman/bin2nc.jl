module bin2nc

using Comonicon
using NetCDF


"""
Convert bin to netcdf.

# Arguments

- `in_dir`: Directory which contains binary files
- `out_file`: NetCDF file to create

# Options

- `-c, --compression`: Set compression level
- `-v, --variable`: Name of variable (not lat, lon, or time)
- `-r, --resolution`: Resolution of input data in degrees
- `-f, --fill`: Fill value of input data
- `-s, --sname`: Standard name for variable. See https://cfconventions.org/Data/cf-standard-names/current/build/cf-standard-name-table.html 
- `-u, --units`: Units for variable
- `-t, --type=<type>`: Data type of input data (NC_FLOAT, NC_INT)
"""
@main function main(in_dir, out_file; 
    compression::Int=0,
    variable::String, 
    resolution::Float32=Float32(0.25), 
    fill::Float32=Float32(-9999.0), 
    sname::String, 
    units::String, 
    type::String,
)

    if type in ["Float32", "Float", "float32", "float"] 
            type = Float32
    elseif type in ["Int16", "Int", "int16", "int"]
            type = Int16
    end
    println(type, " ", typeof(type))

    bin_files = get_bin_files(in_dir)

    (bin_array, years) = read_bin_files(bin_files, resolution)

    convert_to_nc(bin_array, years, out_file, compression, variable, resolution, fill, sname, units, type)

end

function get_bin_files(directory::String)

    !Base.Filesystem.isdir(directory) ? 
        throw(DomainError(directory, "argument must be a directory")) : 
        nothing

    return Base.Filesystem.readdir(join=true, directory)
    
end

function read_bin_files(bin_files::Vector, resolution)

    scale_factor = 1 / resolution
    lines = Integer(180 * scale_factor)
    pixels = Integer(360 * scale_factor)

    years = length(bin_files)

    var_array = Array{Float32, 3}(undef, pixels, lines, 12*years)

    for (i, file) in enumerate(bin_files)
        year_array = Array{Float32, 3}(undef, pixels, lines, 12)
        read!(file, year_array)
        var_array[:,:,i*12-11:i*12] = year_array
    end

    (reverse!(var_array; dims=2), years)

end

function convert_to_nc(bin_array, years, out_file, compression, variable, resolution, fill, sname, units, type) 
        lat_max = 90 - resolution / 2
        lon_max = 180 - resolution / 2
        lat = collect(-lat_max:resolution:lat_max)
        lon = collect(-lon_max:resolution:lon_max)
        tim = collect(0:12*years-1)

        varatts = Dict(
            # "standard_name" => "gross_primary_productivity_of_biomass_expressed_as_carbon",
            # "units" => "g m-2 day-1",
            "standard_name" => sname,
            "units" => units,
            "_FillValue" => fill,
            "missing_value" => fill,
            )
        lonatts = Dict("standard_name" => "longitude", "units" => "degree_east")
        latatts = Dict("standard_name" => "latitude", "units" => "degree_north")
        timatts = Dict("standard_name" => "time", "units" => "months since 2000-01-01 00:00:00")

        isfile(out_file) && rm(out_file)
        
        nccreate(
            out_file, variable, "lon", lon, lonatts, "lat", lat, latatts, "time", tim, timatts, atts=varatts,
            compress=compression, t=type,
        )

        ncwrite(bin_array, out_file, variable)
end

end

