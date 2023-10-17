
module MRITools

	using Statistics

	"""
		See WIP 23.02.22

		voltage[time, channel, pulse]
		returns in units of [unit of α] / ([unit of voltage] sampling time of voltage)
	"""
	@inline function voltage2frequency_factor(α::Real, voltage::AbstractArray{3, <: Real})::Vector{Float64}
		α ./ abs.(
			dropdims(
				mean(sum(voltage, 1); dims=3);
				dims=3
			)
		)
	end
end

