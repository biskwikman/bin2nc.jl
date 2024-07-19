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
- `-t, --type=<type>`: Data type of input data
- `-o, --outtype=<type>`: Data type of output data
- `-p, --pixels`: number of columns of raster image
- `-l, --lines`: number of rows of raster image
- `-e, --easting`: furthest west extent
- `-n, --northing`: furthest north extent
- `-m, --mask`: Mask mode. Removes time dimension from output.
"""
@main function main(in_dir, out_file; 
    compression::Int=0,
    variable::String="variable_placeholder", 
    resolution::Float32=Float32(0.25), 
    fill::String="-9999.0", 
    sname::String="name_placeholder",
    units::String="1", 
    type::String="Float32",
    pixels::Int=720,
    lines::Int=360,
    easting::Float32=Float32(180.0),
    northing::Float32=Float32(90.0),
    mask::Bool=false,
    outtype::String="Float32",
)

    if type in ["Float32", "Float", "float32", "float"] 
            type = Float32
    elseif type in ["Int8", "Int", "int8", "int"]
            type = Int8
    end

   if outtype in ["Float32", "Float", "float32", "float"] 
            outtype = Float32
            fill = parse(Float32, fill)
    elseif outtype in ["Int8", "Int", "int8", "int"]
            outtype = Int8
            fill = parse(Int8, fill)
    end

    println("gathering files from ", in_dir)
    bin_files = get_bin_files(in_dir)

    println("reading files")
    (bin_array, years) = read_bin_files(bin_files, type, mask, pixels, lines)

    println("converting to NetCDF file ", out_file)
    convert_to_nc(
        bin_array, years, out_file, compression, variable, resolution, fill, sname, units, mask, 
        pixels, lines, easting, northing, outtype,
    )

end

function get_bin_files(directory::String)

    !Base.Filesystem.isdir(directory) ? 
        throw(DomainError(directory, "argument must be a directory")) : 
        nothing

    return Base.Filesystem.readdir(join=true, directory)
    
end

function read_bin_files(bin_files::Vector, type, mask, pixels, lines)


    # scale_factor = 1 / resolution
    # lines = Integer(180 * scale_factor)
    # pixels = Integer(360 * scale_factor)

    years = length(bin_files)

    var_array = Array;

    if mask
        var_array = Array{type, 2}(undef, pixels, lines)

        println(bin_files[1])
        read!(bin_files[1], var_array)
    else    
        var_array = Array{type, 3}(undef, pixels, lines, 12*years)

        for (i, file) in enumerate(bin_files)
            println(file)
            year_array = Array{type, 3}(undef, pixels, lines, 12)
            read!(file, year_array)
            var_array[:,:,i*12-11:i*12] = year_array
        end
    end


    (reverse!(var_array; dims=2), years)

end

function convert_to_nc(
    bin_array, years, out_file, compression, variable, resolution, fill, sname, units, mask,
    pixels, lines, easting, northing, outtype   
) 
        lat_max = northing - resolution / 2
        lat_min = (northing - resolution * lines) + resolution / 2

        lon_min = easting + resolution / 2
        lon_max = (easting + resolution * pixels) - resolution / 2

        lat = collect(lat_min:resolution:lat_max)
        lon = collect(lon_min:resolution:lon_max)
        tim = collect(0:12*years-1)

        varatts = Dict(
            "standard_name" => sname,
            "units" => units,
            "_FillValue" => fill,
            "missing_value" => fill,
            )

        lonatts = Dict("standard_name" => "longitude", "units" => "degree_east")
        latatts = Dict("standard_name" => "latitude", "units" => "degree_north")
        timatts = Dict("standard_name" => "time", "units" => "months since 2000-01-01 00:00:00")

        isfile(out_file) && rm(out_file)
        
        if !mask 
            nccreate(
                out_file, variable, "lon", lon, lonatts, "lat", lat, latatts, "time", tim, timatts, atts=varatts,
                compress=compression, t=outtype,
            )
        else
            nccreate(
                out_file, variable, "lon", lon, lonatts, "lat", lat, latatts, atts=varatts,
                compress=compression, t=outtype,
            )
        end

        ncwrite(bin_array, out_file, variable)
end

end

