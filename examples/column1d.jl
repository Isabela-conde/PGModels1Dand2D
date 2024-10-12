using PGModels1Dand2D
using PyPlot

plt.style.use("../plots.mplstyle")
plt.close("all")
pygui(false)

set_out_folder("../output/")

function run(; bl=false)
    # parameters
    f = -5.5e-5
    N2 = 1e-6
    nz = 2^8
    H = 2e3
    θ = 2.5e-3         
    transport_constraint = true
    U = [0.0]

    # grid: chebyshev unless bl
    if bl
        z = collect(-H:H/(nz-1):0) # uniform
    else
        z = @. -H*(cos(pi*(0:nz-1)/(nz-1)) + 1)/2 # chebyshev 
    end
    
    # diffusivity
    κ0 = 6e-5
    κ1 = 2e-3
    h = 200
    κ_func(z) = κ0 + κ1*exp(-(z + H)/h)
    κ_z_func(z) = -κ1/h*exp(-(z + H)/h)

    # viscosity
    μ = 1e0
    ν_func(z) = μ*κ_func(z)
    
    # timestepping
    Δt = 10*secs_in_day
    t_save = 3*secs_in_year
    
    # create model struct
    m = ModelSetup1D(bl, f, nz, z, H, θ, ν_func, κ_func, κ_z_func, N2, Δt, transport_constraint, U)

    # save and log params
    save_setup(m)

    # set initial state
    b = zeros(nz)
    χ, u, v = invert(m, b)
    i = [1]
    s = ModelState1D(b, χ, u, v, i)

    # solve transient
    evolve!(m, s, 15*secs_in_year, t_save) 
    
    return m, s
end

# run
m, s = run()
# m, s = run(bl=true)

# plots
setup_file = string(out_folder, "setup.h5")
state_files = string.(out_folder, "state", 0:5, ".h5")
profile_plot(setup_file, state_files)

println("Done.")