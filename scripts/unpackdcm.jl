
using DICOM
include("DICOMUtils.jl")
using .DICOMUtils

using JLD

# Define setup
const setup = Dict(

	:inversion_recovery => Dict(
		:uids => (
		),
		:tag => tag"InversionTime",
		:target => "data/20210707/generated/inversion_recovery.jld"
	),

	:spin_echo => Dict(
		:uids => (
		),
		:tag => tag"EchoTime",
		:target => "data/20210707/generated/spin_echo.jld"
	)
)


# Open dcms
const dcmbatch = DICOMUtils.load_dcmbatch("data/20210707/dicom")

# Print information
for (uid, series) in pairs(dcmbatch)
	for frame in series
		println(uid, "  ", frame[tag"InstanceNumber"], " ", frame[tag"SequenceName"])
	end
end


