using GenieFramework
using Stipple
@genietools

@app begin
    @in projection_choice = nothing 
    @in lon0 = 0
    @in lon_step_choice = 15
end

function projection_iframe(i)
    Html.iframe(
        src = "projection_$(i).html",
        var"v-show" = "projection_choice == $i",
        style = """
        height: 100%;
        width: 100%;
        border: none;
        display: block;
        """
    )
end

function ui()
    [
        row([
            # LEFT 
            cell(
                size = 6,
                class = "st-module",
                style = "height: 65vh; padding: 0; overflow: visible; position: relative;",
                [
                    Html.div(
                        style = "height: 100%; width: 100%; position: relative;",
                        [projection_iframe(i) for i in 1:13]
                    )
                ]
            ),

            # RIGHT 
            cell(
                size = 6,
                class = "st-module",
                style = "height: 65vh; display: flex; align-items: center; justify-content: center; background: #f9f9f9; border-left: 1px solid #ddd;",
                [
                    Html.p("Right Plot Area (Empty)", class = "text-h6 text-grey-7")
                ]
            )
        ]),

        # BOTTOM
        row([
            cell(class = "st-module", style = "margin-top: 20px;", [
                row([
                    cell(class="col-8", [
                        Stipple.select(
                            :projection_choice,
                            label = "Select Map Projection",
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
                    ]),
                    
                    cell(class="col-4 q-px-md", [
                        p("Central Meridian: {{lon0}}°", class="q-mb-none text-weight-bold", style="font-size: 0.85rem; color: #666;"),
                        slider(-180:1:180, :lon0, label=true, class="q-mb-md"),

                        p("Grid Interval",
                            class="q-mb-xs text-weight-bold",
                            style="font-size: 0.85rem; color: #666;"
                        ),

                        Stipple.select(:lon_step_choice,
                            options=[Dict("label"=>"$(i)°", "value"=>i) for i in [5,10,15,20,25,30]],
                            filled=true
                        )
                    ])
                ])
            ])
        ])
    ]
end

@page("/", ui)

Server.up()