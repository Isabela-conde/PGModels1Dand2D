using PyPlot
using PyCall
using JLD2
using NCDatasets


plt.style.use(joinpath(@__DIR__, "../../plots.mplstyle"))
close("all")
pygui(false)

pl = pyimport("matplotlib.pylab")
inset_locator = pyimport("mpl_toolkits.axes_grid1.inset_locator")
pc = 1/6 # pica

"""
    profile_plot(datafiles)

Plot profiles from JLD2 snapshot files in the `datafiles` list.
"""
function profile_plot(datafiles; fname=joinpath(out_dir, "profiles.png"))


    # init plot
    fig, ax = subplots(2, 2, figsize=(29pc, 31pc), sharey=true)


    ax[1].set_xlabel(L"Cross-slope flow $u$")
    ax[1].set_ylabel(L"Depth $z$")
    ax[2].set_xlabel(L"Along-slope flow $v$")

    ax[3].set_xlabel("Cross-slope watermass \ntransformation " * L" $\partial_t b + u$")
    ax[2].set_ylabel(L"Depth $z$")


    ax[4].set_xlabel(L"Stratification $N^2 + \partial_z b$")

    subplots_adjust(bottom=0.15, top=0.92, left=0.1, right=0.9, wspace=0.15, hspace=0.3)

    for a in ax
        a.ticklabel_format(style="sci", axis="x", scilimits=(-3, 3))
        a.grid(true)  
    end

    # color map
    colors = pl.cm.viridis(range(1, 0, length=size(datafiles, 1)-1))

    # zoomed z
    ax[1].set_ylim([0, z_max])
    # ax[3].set_xlim([-0.002, 0.08])


    # plot data from `datafiles`
    for i ∈ eachindex(datafiles)
        # load
        d = jldopen(datafiles[i], "r")
        u = d["u"]*V
        v = d["v"]*V
        b = d["b"]*B
        t = d["t"]*T      
        
        model = d["model"]
        close(d)
        z = model.z
        Ñ = model.N
        N = sqrt(1e-5)
        κ = 1e-4
        
        # stratification
        bz = differentiate(b, z) 
        bt = -u .+ differentiate(κ.*(N^2 .+ bz),z)

        # colors and labels
        if t == Inf
            label = "Steady state"
        else
            # convert from seconds to hours
            label = string(L"$t$ = ", Int64(round(t/60/60/24)), " days")
        end

        if i == 1
            color = "mediumblue"
        else
            color = colors[i-1, :]
        end

        # plot
        ax[1].plot(u, z, c=color)
        ax[3].plot(bt + u,z, c=color)
        ax[2].plot(v,z, color = color)
        ax[4].plot(N^2 .+ bz,  z, c=color, label=label)

    end

    # ax[2].legend()
    ax[4].legend()
    # forces 1e-3 on the u and v plots
    ax[1].ticklabel_format(style="sci", axis="x", scilimits=(-3, -3))
    # ax[2].ticklabel_format(style="sci", axis="x", scilimits=(-3, -3))

    # default scientific formatting for the other two
    ax[3].ticklabel_format(style="sci", axis="x")
    ax[4].ticklabel_format(style="sci", axis="x")

    savefig(fname)
    println(fname)
    plt.close()
end



# dfiles = [joinpath(out_dir, @sprintf("checkpoint%03d.jld2", i)) for i in i_saves]
# i_saves = 0:1:5

# d = jldopen(dfiles[1], "r")

# u = d["u"]
# v = d["v"]
# b = d["b"]
# t = d["t"]        
# model = d["model"]
# close(d)
# z = model.z
# N = model.N

# # stratification
# bz = differentiate(b, z)
# bt = differentiate(b, t)
# Δz = z[2] - z[1]          # constant spacing
# # u = Array(u_center)                   # Nz×Nt
# Qz = vec(sum(u, dims=1)) .* Δz
# Δt = t[2] - t[1]
# Q_cumtime = cumsum(Q) .* Δt         # length Nt
