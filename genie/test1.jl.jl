using DelimitedFiles
using Plots
using Markdown

# Set the backend to PlotlyJS for interactivity
plotlyjs() 

# --- Configuration ---
const COAST_FILE_PATH = "/Users/katherinekyriakou/Desktop/genie-main/coastline_points.txt" 

# --- Projection Helper Function (Same as your original) ---
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
        mask = lats .> -π/3 # Only plot from 60S and up
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

# --- Data Loading ---
if !isfile(COAST_FILE_PATH)
    error("Coastline file not found.")
end

coast_data = readdlm(COAST_FILE_PATH, ',', Float64)
c_ids = coast_data[:, 1] 
c_lon = coast_data[:, 2] .* (π / 180)
c_lat = coast_data[:, 3] .* (π / 180)

const R = 6371.0
const phi0 = 45 * π / 180
const lon0 = 0.0
const titles = [
    "Cylindrical Equidistant", "Cylindrical Equal-Area", "Mercator",
    "Conic Equidistant", "Lambert Conformal Conic", "Albers Equal-Area",
    "Azimuthal Equidistant", "Stereographic", "Gnomonic", "Orthographic",
    "Lambert Azimuthal Equal-Area", "Transverse: Cassini", "Transverse: Mercator"
]

# --- Main Plotting Loop ---
for i in 1:13
    println("Generating Plotly Projection $i: $(titles[i])...")
    
    # Initialize Plot with Plotly attributes
    p = Plots.plot(aspect_ratio=:equal, size=(800, 550), title=titles[i],
             grid=false, showaxis=false, ticks=false, 
             bg=:white, legend=false)

    # 1. Graticule
    # Parallels
    for lat in -80:15:80
        lons_deg = collect(-180:1.0:180) 
        gx, gy = get_projected_grid(lons_deg .* (π/180), fill(lat * π/180, length(lons_deg)), i, lon0, phi0, R)
        plot_clean_lines!(p, gx, gy, :gray, 0.5, 0.3, R)
    end
    
    # Meridians
    lat_limit = (i == 3 || i == 13) ? 85.0 : 89.9
    for lon in -180:30:180
        bg = collect(-lat_limit:1.0:lat_limit) .* (π/180)
        gx, gy = get_projected_grid(fill(lon * π/180, length(bg)), bg, i, lon0, phi0, R)
        plot_clean_lines!(p, gx, gy, :gray, 0.5, 0.3, R)
    end

    # 2. Coastline
    # We group by ID but use NaNs to keep the number of series low for performance
    all_cx, all_cy = Float64[], Float64[]
    for id in unique(c_ids)
        mask = c_ids .== id
        seg_x, seg_y = get_projected_grid(c_lon[mask], c_lat[mask], i, lon0, phi0, R)
        
        # Append segment and a NaN to break the line
        append!(all_cx, seg_x); push!(all_cx, NaN)
        append!(all_cy, seg_y); push!(all_cy, NaN)
    end
    plot_clean_lines!(p, all_cx, all_cy, :magenta, 1.2, 1.0, R)

    # Output: Save as HTML (standard for Plotly) or PNG
    savefig(p, "projection_$(i).html")
end

println("Done! 13 interactive HTML plots generated.")