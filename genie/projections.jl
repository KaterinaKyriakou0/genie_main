module Projections

using DelimitedFiles
using Plots
using Markdown

plotlyjs() 

# --- Constants ---
const R_DEFAULT = 6371.0
const PHI0_DEFAULT = 45 * π / 180
const LON0_DEFAULT = 0.0
const TITLES = [
    "Cylindrical Equidistant", "Cylindrical Equal-Area", "Mercator",
    "Conic Equidistant", "Lambert Conformal Conic", "Albers Equal-Area",
    "Azimuthal Equidistant", "Stereographic", "Gnomonic", "Orthographic",
    "Lambert Azimuthal Equal-Area", "Transverse: Cassini", "Transverse: Mercator"
]

# --- Internal Helper: Projection Math ---
function get_projected_grid(lons, lats, projection_choice, lon0, phi0, R)
    lam0_rad = lon0 * π / 180
    adj_l = mod.(lons .- lam0_rad .+ π, 2π) .- π
    
    if projection_choice == 1 # Cylindrical Equidistant
        return R .* adj_l, R .* lats
    elseif projection_choice == 2 # Cylindrical Equal-Area
        return R .* adj_l, R .* sin.(lats)
    elseif projection_choice == 3 # Mercator
        limit = 85 * π/180
        mask = abs.(lats) .< limit
        return R .* adj_l[mask], R .* log.(tan.(π/4 .+ lats[mask]./2))
    elseif projection_choice == 4 # Conic Equidistant
        r = R .* (cot(phi0) .+ phi0 .- lats)
        return r .* sin.(adj_l .* sin(phi0)), r .* cos.(adj_l .* sin(phi0))
    elseif projection_choice == 5 # Lambert Conformal Conic
        n = sin(phi0)
        F = (cos(phi0) * (tan(π/4 + phi0/2)^n)) / n
        mask = lats .> -π/3 
        r = (R * F) ./ (tan.(π/4 .+ lats[mask] ./ 2).^n)
        return r .* sin.(n .* adj_l[mask]), r .* cos.(n .* adj_l[mask])
    elseif projection_choice == 6 # Albers Equal-Area
        n = sin(phi0)
        C = cos(phi0)^2 + 2 * n * sin(phi0)
        r = (R / n) .* sqrt.(max.(0, C .- 2 .* n .* sin.(lats)))
        return r .* sin.(n .* adj_l), r .* cos.(n .* adj_l)
    elseif projection_choice == 7 # Azimuthal Equidistant
        rho = R .* (π/2 .- lats)
        return rho .* sin.(adj_l), rho .* cos.(adj_l)
    elseif projection_choice == 8 # Stereographic
        mask = lats .> -75 * π/180
        rho = 2 * R .* tan.(π/4 .- lats[mask] ./ 2)
        return rho .* sin.(adj_l[mask]), rho .* cos.(adj_l[mask])
    elseif projection_choice == 9 # Gnomonic
        mask = lats .> (15 * π/180)
        r = R .* tan.(π/2 .- lats[mask])
        return r .* sin.(adj_l[mask]), r .* cos.(adj_l[mask])
    elseif projection_choice == 10 # Orthographic
        mask = lats .>= 0
        rho = R .* cos.(lats[mask])
        return rho .* sin.(adj_l[mask]), rho .* cos.(adj_l[mask])
    elseif projection_choice == 11 # Lambert Azimuthal Equal-Area
        rho = 2 * R .* sin.((π/2 .- lats) ./ 2)
        return rho .* sin.(adj_l), rho .* cos.(adj_l)
    elseif projection_choice == 12 || projection_choice == 13 # Transverse
        u = atan.(1.0 ./ (cot.(lats) .* cos.(adj_l)))
        v = asin.(cos.(lats) .* sin.(adj_l))
        mask = (abs.(v) .< (π/2 - 0.001)) .& (cos.(adj_l) .> 0)
        if projection_choice == 12 # Cassini
            return R .* v[mask], R .* u[mask]
        else # Transverse Mercator
            return R .* log.(tan.(π/4 .+ v[mask]./2)), R .* u[mask]
        end
    end
    return R .* adj_l, R .* lats 
end

# --- Internal Helper: Line Cleaning ---
function plot_clean_lines!(plt, x, y, col, weight, op, R)
    jump_threshold = 0.25 * π * R 
    clean_x, clean_y = Float64[], Float64[]
    
    for i in 1:length(x)
        if i > 1
            if !isfinite(x[i]) || !isfinite(y[i]) || 
               abs(x[i] - x[i-1]) > jump_threshold || 
               abs(y[i] - y[i-1]) > jump_threshold
                push!(clean_x, NaN); push!(clean_y, NaN)
            end
        end
        push!(clean_x, x[i]); push!(clean_y, y[i])
    end
    plot!(plt, clean_x, clean_y, linecolor=col, linewidth=weight, alpha=op)
end

# --- Main Exported Function ---
"""
    generate_all_projections(filepath::String)

Calculates 13 map projections and returns a Dictionary where:
Key: Integer (1-13)
Value: HTML String (Plotly interactive)
"""
function generate_all_projections(filepath::String)
    if !isfile(filepath)
        error("Coastline file not found at: \$filepath")
    end

    coast_data = readdlm(filepath, ',', Float64)
    c_ids = coast_data[:, 1] 
    c_lon = coast_data[:, 2] .* (π / 180)
    c_lat = coast_data[:, 3] .* (π / 180)

    html_outputs = Dict{Int, String}()

    for i in 1:13
        p = Plots.plot(aspect_ratio=:equal, size=(800, 550), title=TITLES[i],
                 grid=false, showaxis=false, ticks=false, 
                 bg=:white, legend=false)

        # 1. Graticule
        for lat in -80:15:80
            lons_deg = collect(-180:1.0:180) 
            gx, gy = get_projected_grid(lons_deg .* (π/180), fill(lat * π/180, length(lons_deg)), i, LON0_DEFAULT, PHI0_DEFAULT, R_DEFAULT)
            plot_clean_lines!(p, gx, gy, :gray, 0.5, 0.3, R_DEFAULT)
        end
        
        lat_limit = (i == 3 || i == 13) ? 85.0 : 89.9
        for lon in -180:30:180
            bg = collect(-lat_limit:1.0:lat_limit) .* (π/180)
            gx, gy = get_projected_grid(fill(lon * π/180, length(bg)), bg, i, LON0_DEFAULT, PHI0_DEFAULT, R_DEFAULT)
            plot_clean_lines!(p, gx, gy, :gray, 0.5, 0.3, R_DEFAULT)
        end

        # 2. Coastline
        all_cx, all_cy = Float64[], Float64[]
        for id in unique(c_ids)
            mask = c_ids .== id
            seg_x, seg_y = get_projected_grid(c_lon[mask], c_lat[mask], i, LON0_DEFAULT, PHI0_DEFAULT, R_DEFAULT)
            append!(all_cx, seg_x); push!(all_cx, NaN)
            append!(all_cy, seg_y); push!(all_cy, NaN)
        end
        plot_clean_lines!(p, all_cx, all_cy, :magenta, 1.2, 1.0, R_DEFAULT)

        # Capture Plotly HTML as string
        io = IOBuffer()
        show(io, MIME"text/html"(), p)
        html_outputs[i] = String(take!(io))
    end

    return html_outputs
end

end # module