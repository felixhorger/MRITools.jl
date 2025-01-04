
using JLD
import MATLAB

txtfile = ARGV[1]
outpath = ARGV[2]

function parse_dsv(path, session)
	MATLAB.eval_string(
		session,
		"dsv = dsvread($(path)).values;"
	)
	return MATLAB.jarray(MATLAB.get_mvariable(session, :dsv))
end

session = MATLAB.MSession()
MATLAB.eval_string(
	session,
	"""
		cd("$(pwd())");
		addpath("../dsv-reader");
		clear dsvread; % Reload
	"""
)

G = parse_dsv(txtfile, session)
k = cumsum(G)
save(outpath, "G", G, "k", k)

