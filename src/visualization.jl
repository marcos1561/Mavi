"Systems visualizaions"
module Visualization

using GLMakie
using Mavi: State, System
using Mavi.Configs
using DataStructures

include("gui/info_ui.jl")
include("gui/system_graph.jl")

using .InfoUIs 
using .SystemGraphs 

@kwdef struct UiSettings
    sidebar_rel_length = 0.2
end

"""
Animation configurations

# Arguments
- fps: 
Animation fps
- num_stesp_per_frame: 
    How many time steps are done in a single frame.
- circle_radius: 
    Radius used to draw circles centered on particles positions.  
    If not given, `particle_radius(dynamic_cfg)` will be used.
- circle_rel: 
    How many verticies used to draw circles.
- exec_times_size: 
    Circular buffer length that stores step time execution.
"""
@kwdef struct AnimationCfg{GraphT, InfoT}
    graph_cfg::GraphT = DefaultGraphCfg()
    info_cfg::InfoT = DefaultInfoUICfg()
    fps = 30
    num_steps_per_frame = 10
    exec_times_size = 40
    ui_settings = UiSettings()
end

mutable struct ExecInfo 
    sym_time::Float64
    times::CircularBuffer{Float64}
end

"Render, in real time, the system using the given step function."
function animate(system::System, step!, cfg::AnimationCfg)
    fig = Figure(
        backgroundcolor = RGBf(0.98, 0.98, 0.98), 
        # size = (1000, 700),
    )

    ui_settings = cfg.ui_settings

    system_gl = fig[1, 2] = GridLayout()
    
    sidebar_gl = fig[1, 1] = GridLayout()
    info_gl = sidebar_gl[1, 1] = GridLayout(
        halign=:left, 
        valign=:top, 
        tellwidth=false,
    )
    
    rowsize!(sidebar_gl, 1, Relative(1))
    colsize!(fig.layout, 1, Relative(ui_settings.sidebar_rel_length))
    
    Box(sidebar_gl[:, 1], cornerradius=5)

    info = InfoUIs.get_info_ui(info_gl, cfg.info_cfg)
    graph = SystemGraphs.get_graph(system_gl, system, cfg.graph_cfg)

    exec_info = ExecInfo(0, CircularBuffer{Float64}(cfg.exec_times_size))

    display(fig)
    while events(fig).window_open[] 
        for _ in 1:cfg.num_steps_per_frame
            step_info = @timed step!(system, system.int_cfg)
            push!(exec_info.times, step_info.time)
            exec_info.sym_time += system.int_cfg.dt
        end
        
        InfoUIs.update_info_ui(info, exec_info)
        SystemGraphs.update_graph(graph, system.state)

        sleep(1/cfg.fps)
    end
end

end
