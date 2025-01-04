
using JLD
using Interpolations
using LinearAlgebra

include("MRFExcitationSchedule.jl")
import .MRFExcitationSchedule


function load_instructions(path::AbstractString)::Vector{ComplexF64}
	_, α, _, pulses, _ = MRFExcitationSchedule.read_excitation_plan(path, 1)
	pulses .*= α
	for p ∈ eachindex(pulses)
		pulses[p] = extrapolate(
			interpolate(
				pulses[p],
				BSpline(Linear())
			),
			Flat()
		)(1.8 : 0.2 : length(pulses[p]))
	end
	pulses = vcat(pulses...)
	return pulses
end

function overlay_pulses(instructed, measured)
	# The time shifts and δts are all over the place ...

	instructed = load_instructions(instructed)
	measured = load(measured, "pulses")

	# Combine channels
	measured = dropdims(
		sum(measured, dims=2);
		dims=2
	)
	measured = @view measured[9:end] # random shift of 10 indices

	# Cut measured to correct length
	remainder = length(measured) % length(instructed)
	repeats = length(measured) ÷ length(instructed)
	show(repeats) # TODO save this for plot, or generate plot data here in the first place
	measured = measured[1:end-remainder]
	
	# Normalise using last cycle, after RF-amplifier is warmed up
	# Scale with least squares minimiser
	let extract = @view measured[end-length(instructed)+1:end]
		measured .*= (
			(extract' * instructed)
			/ norm(extract)^2
		)
	end

	# Repeat instructed to correct size
	instructed = repeat(instructed, repeats)

	# Time axis
	t = collect((0:size(instructed, 1)-1) .* 0.5e-6) # Random δt = 0.5μs

	return t, instructed, measured
end


# Define setup
const datapath = "data/20210707"
const targetpath = joinpath(datapath, "generated")

time, instructed, measured = overlay_pulses(
	joinpath(datapath, "raw/MRFPulses0"),
	joinpath(targetpath, "measured_pulses.jld")
)

save(
	joinpath(targetpath, "overlayed_pulses.jld"),
	"time", time,
	"instructed", instructed,
	"measured", measured
)

