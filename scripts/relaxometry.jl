
using Statistics
using JLD
import MRIQuant

include("ThreadUtils.jl")
using .ThreadUtils

const target = "data/20210707/generated"
const setup = Dict(

	:inversion_recovery => Dict(
		:path => target * "/inversion_recovery.jld",
		:fitfunc => (Tinv, signal, Δsignal) -> begin
			MRIQuant.fit_inversion_recovery(
				Tinv,
				signal,
				Δsignal,
				2000.0, # T1
				-1.0, # Minv
				1000.0 # M0
			)
		end,
		:model => (t, T1, Minv, M0) -> M0 .* abs(MRIQuant.longitudinal_relax(t, 1.0/T1, Minv)),
		:modelparamidx => [1, 3, 5], # Indices of fit-results (below) which are fed into model
		:returntypes => (Float64, Float64, Float64, Float64, Float64, Float64),
		:returnnames => ("T1", "DeltaT1", "Minv", "DeltaMinv", "M0", "DeltaM0"),
		:roi => (130:159, 55:65, 1:1), # TODO: Sync with plot_relax.py
		:roi_noise => (1:20, 1:20, 1:1),
		:out => target * "/T1.jld"
	),

	:spin_echo => Dict(
		:path => target * "/spin_echo.jld",
		:fitfunc => MRIQuant.fit_transverse_relax,
		:model => (t, T2, M0) -> M0 * MRIQuant.transverse_relax(t, 1.0/T2),
		:modelparamidx => [1, 3], # Indices of fit-results (below) which are fed into model
		:returntypes => (Float64, Float64, Float64, Float64),
		:returnnames => ("T2", "DeltaT2", "M0", "DeltaM0"),
		:roi => (130:159, 55:65, 1:1), # TODO: Sync with plot_relax.py
		:roi_noise => (1:20, 1:20, 1:1),
		:out => target * "/T2.jld"
	)
)


function relaxometry(info)
	# Load data
	arrays, tags = load(info[:path], "arrays", "tags")
	
	# Get mean signal and noise estimation
	meansignal = mean(view(arrays, :, info[:roi]...); dims=2:4)
	Δsignal = std(view(arrays, :, info[:roi_noise]...); dims=2:4)
	meansignal, Δsignal = dropdims.((meansignal, Δsignal); dims=(2, 3, 4))

	# Get shorthand for fitfunc
	fitfunc = info[:fitfunc]

	# Get initial size and flatten voxel dimensions
	arraysize = [ size(arrays, d) for d = 2:4 ]
	arrays = reshape(arrays, (length(tags), :))

	# Construct results array
	results = [
		Array{T, 3}(undef, arraysize...)
		for T in info[:returntypes]
	]

	# Iterate over voxels
	curve = @forallthreads Vector{Float64}(undef, length(tags))
	Threads.@threads for i = 1:size(arrays, 2)
		@thisthread curve = view(arrays, :, i)
		returned = fitfunc(tags, @thisthread(curve), Δsignal)
		for (j, r) in enumerate(returned)
			results[j][i] = r
		end
	end

	# Reshape to initial size
	for j in eachindex(results)
		results[j] = reshape(results[j], arraysize...)
	end

	# Get parameter estimation
	roi = [ view(r, info[:roi]...) for r in results ]
	θ = [ mean(a) for a in roi ]
	Δθ = [ std(a; mean=m) for (a, m) in zip(roi, θ) ]
	
	# Compute curve with estimated parameters
	estimation = info[:model].(tags, θ[info[:modelparamidx]]...)

	return θ, Δθ, tags, estimation, meansignal, Δsignal, results
end

for (i, info) in enumerate(values(setup))

	θ, Δθ, tags, estimation, meansignal, Δsignal, results = relaxometry(info)
	f = jldopen(info[:out], "w")
	write(f, "tags", tags)
	write(f, "estimation", estimation)
	write(f, "meansignal", meansignal)
	write(f, "Deltasignal", Δsignal) # Can be used to scale error-maps
	for (name, result, p, Δp) in zip(info[:returnnames], results, θ, Δθ)
		write(f, name, result)
		write(f, name * "_mean", p)
		write(f, name * "_std", Δp)
	end
	close(f)
end

