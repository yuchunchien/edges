This repo is forked from https://github.com/pdollar/edges.
Thanks for Piotr Dollar's contribution on Structured Edge Detection Toolbox.

# Added Files Description
## edgeBoxesGT.m
1. Generate localization ground truth based on EdgeBoxes framework.
2. Define the range of each sea lion with the edges surrounding it.

## edgeBoxesMex.cpp
1. Provide C++ functions (edgeBoxesMex) for matlab files to call.
2. Renovate function "refineBox" to achieve self-defined refinement of the range (box) of each sea lion.
3. Create function "getGT" to control the work flow of generating ground truth for each sea lion.
