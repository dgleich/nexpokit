
if ismac
mex -O -largeArrayDims gsqres_mex.cpp
else
mex -O CXXFLAGS="\$CXXFLAGS -std=c++0x" -largeArrayDims gsqres_mex.cpp
mex -O CXXFLAGS="\$CXXFLAGS -Wall" -largeArrayDims gexpmq_mex.cpp
%mex -O CXXFLAGS="\$CXXFLAGS -Wall" -largeArrayDims gsqres_mex.cpp
end