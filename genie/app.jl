using GenieFramework, Stipple
@genietools

@app begin
    @in projection_choice = 1
end

# --- Helper: create one iframe ---
function projection_iframe(i)
    Html.iframe(
        src = "projection_$(i).html",

        var"v-show" = "projection_choice == $i || projection_choice.value == $i",

        style = """
            height: 60vh;
            width: 100%;
            border: none;
            position: absolute;
            top: 0;
            left: 0;
            background: white;
        """
    )
end

function ui()
    [
        # === MAP CONTAINER ===
        row([
            cell(
                class = "st-module",
                style = "height: 65vh; position: relative; overflow: hidden;",
                [

                    # ✅ Preload all projections
                    projection_iframe(1),
                    projection_iframe(2),
                    projection_iframe(3),
                    projection_iframe(4),
                    projection_iframe(5),
                    projection_iframe(6),
                    projection_iframe(7),
                    projection_iframe(8),
                    projection_iframe(9),
                    projection_iframe(10),
                    projection_iframe(11),
                    projection_iframe(12),
                    projection_iframe(13),

                ]
            )
        ]),

        # === DEBUG TEXT ===
        row([
            cell([
                p("Selected: {{ projection_choice }}")
            ])
        ]),

        # === DROPDOWN ===
        row([
            cell(class = "st-module", style = "padding: 20px;", [
                Stipple.select(
                    :projection_choice,
                    label = "Map Projection",
                    options = [
                        Dict("label"=>"Cylindrical Equidistant", "value"=>1),
                        Dict("label"=>"Cylindrical Equal-Area", "value"=>2),
                        Dict("label"=>"Mercator", "value"=>3),
                        Dict("label"=>"Conic Equidistant", "value"=>4),
                        Dict("label"=>"Lambert Conformal Conic", "value"=>5),
                        Dict("label"=>"Albers Equal-Area", "value"=>6),
                        Dict("label"=>"Azimuthal Equidistant", "value"=>7),
                        Dict("label"=>"Stereographic", "value"=>8),
                        Dict("label"=>"Gnomonic", "value"=>9),
                        Dict("label"=>"Orthographic", "value"=>10),
                        Dict("label"=>"Lambert Azimuthal Equal-Area", "value"=>11),
                        Dict("label"=>"Transverse: Cassini", "value"=>12),
                        Dict("label"=>"Transverse: Mercator", "value"=>13)
                    ],
                    filled = true,
                    var"emit-value" = true,
                    var"map-options" = true
                )
            ])
        ])
    ]
end

@page("/", ui)

# Start server
Server.up()