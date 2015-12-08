%%
%    Copyright (C) 2015  Andrea Vaccari
%
%    This program is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    This program is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with this program.  If not, see <http://www.gnu.org/licenses/>.
%%
% CITATION
%
% If you decide to use this code or part of it, please cite our work:
% Vaccari, A.; Stuecheli, M.; Bruckno, B.; Hoppe, E.; Acton, S.T.;
% "Detection of geophysical features in InSAR point cloud data sets using
% spatiotemporal models," International Journal of Remote Sensing, vol.34,
% no.22, pp.8215-8234. doi: 10.1080/01431161.2013.833357
% <http://dx.doi.org/10.1080/01431161.2013.833357>

function EvaluateSubsidence(xaccdel, ...
                            yaccdel, ...
                            ampmin, ...
                            ampmax, ...
                            ampstp, ...
                            sigmin, ...
                            sigmax, ...
                            sigstp, ...
                            N, ...
                            show, ...
                            geotiff, ...
                            options)

                        %% Enable parallel processing
% Enable parallel processing (with the idea that it might be possible to
% simply port the code directly to the FIR or RIVANNA clusters

% Check if matlabpool is enabled, if not, enable
poolobj = gcp('nocreate');
if isempty(poolobj)
    disp('Starting parallel pool...');
    h = msgbox('Starting parallel processing pool...');
    parpool;
    if exist('h', 'var')
        delete(h);
        clear('h');
    end
else
    disp(['Using existing parallel pool with ' poolobj.NumWorkers ' workers...'])
end




%% General data import section
% Import the point cloud data. This is stored in a format known as shape
% file (ESRI), basically an old dbase customized to represent geometric
% shapes. It is one of the standard in geographic information systems (GIS)

% Open a shape file and read projection file if it exists
[ShapeData, ShapeProj, path, BaseName] = OpenShapeFile();

% Verify that ShapeData contains actual data. It will be 0 if the opening
% was cancelled.
if exist('ShapeData', 'var')
    if  isstruct(ShapeData) == 0
        return
    end
end

%% Extract coordinates and displacements from shape file
h = msgbox('Preparing data for analysis...');
% After the shapefile is loaded using a matlab library, the data is
% extracted and packaged in array format for easier analyis and use.
if ~exist('displ', 'var')
    [displ, coo, ~, ~, date] = GetDisplacementData(ShapeData);
    clear ShapeData;
end


% Calculate months since first acquisition (check)
day = zeros(1, length(date));
for i = 1:length(date)
    d = date{i};
    yy = str2double(d(2:5));
    mm = str2double(d(6:7));
    dd = str2double(d(8:9));
    day(i) = dd + mm * 30.4368 + yy * 365.242;
end
month = (day - day(1)) / 30.4368;


% Calculate extremes and ranges
nx = coo(:, 1);
ny = coo(:, 2);

xmin = min(nx);
ymin = min(ny);

xmax = max(nx);
ymax = max(ny);

xrng = xmax - xmin;
yrng = ymax - ymin;


% Define the number of intervals and size of scanning block
% This is where the dataset is subdivided in blocks. This is
% necessary for two main reasons: the intermidiate products of the
% computation will not fit in memory if the dataset is large and, since
% each block can be executed independently, this allow for the use of
% matlab parallelization (parfor). In theory, the choice on how and if to 
% split the dataset could be unloaded to the underlying implementation of 
% the algorithm. The only parameter of interest is the actal definition of
% the parameter space (coming next). But this is really a specific
% implementation and probably not general enough to be of interest.
% Function parameter: N = 5;
xstp = xrng / N;
ystp = yrng / N;


% Define the basic boundaries of each block
n = 1:N;
xp1 = xmin + (n - 1) * xstp;
yp1 = ymin + (n - 1) * ystp;
xp2 = xmin + n * xstp;
yp2 = ymin + n * ystp;

if exist('h', 'var')
    delete(h);
    clear('h');
end


%% Accumulator
% Accumulator: amplitude range (units/month)
% In this section, the size of the parameter space is defined. The decision
% on range and step interval define the resolution vs. computation burden.
% The larger the parameter space, the more computationally expensive is the
% analyis both in term of memory use and processor load.
% The units depend on the data within the analyzed dataset. An example, in
% case of mm, is presented here:
% Function parameter: ampmin = 1;  % 1mm/month
% Function parameter: ampmax = 5;  % 5mm/month
% Function parameter: ampstp = 16;  % 16 (0.25mm/month)

% The function linspace(min, max, stp) creates a linear range of stp values
% between min and max. It is used across this program to generate a set of
% coordinates within the 4D parameter space (x, y, growth, amp, sig). For
% each of these points, the residual function is calculated.
if options.amplog
    amp = logspace(log10(ampmin), log10(ampmax), ampstp);
else
    amp = linspace(ampmin, ampmax, ampstp);
end

% Accumulator: sigma range (units)
% The units depend on the data within the analyzed dataset. An example, in
% case of m, is presented here:
% Function parameter: sigmin = 5;  % 5m (16.4042ft)
% Function parameter: sigmax = 100;  % 100m (328.0839ft)
% Function parameter: sigstp = 5;  % 19 (5m)
if options.siglog
    sig = logspace(log10(sigmin), log10(sigmax), sigstp);
else
    sig = linspace(sigmin, sigmax, sigstp);
end

% Accumulator: data step (assumes blocks with same physical size) (units)
% The units depend on the data within the analyzed dataset. An example, in
% case of m, is presented here:
% Function parameter: xaccdel = 2.5;  % 2.5m (8.2021ft)
xaccstp = ceil(xstp / xaccdel);
% Function parameter: yaccdel = 2.5;  % 2.5m (8.2021ft)
yaccstp = ceil(ystp / yaccdel);
% The propagation scaling factor is the average. Propagation only works
% with circular regions. TODO: modify propagation to work with elliptical
% regions.
prodel = 0.5 * (xaccdel + yaccdel);



%% Run on entire image
% This is the core of the implementation. The dataset was divided in
% blocks. The next three lines prepare 3D arrays that will contain the
% results of the analysis for each of the blocks.
mampblk = uint8(zeros(yaccstp - 1, xaccstp - 1, N^2));
msigblk = uint8(zeros(yaccstp - 1, xaccstp - 1, N^2));
resblk = single(zeros(yaccstp - 1, xaccstp - 1, N^2));

% At this point the matlab implemntation of the for...loop is called and
% each block "i" is evaluated in a separate instance. This could be a
% simple call where the parameter space is passed together with the dataset
% and everything happens within the implementation that could make best use
% of the hardware found.
h = msgbox('Analyzing data...');
parfor i = 1:N^2
    % Accumulator: coordinates range
    [r, c] = ind2sub([N, N], i);
    
    xaccmin = xp1(r);
    xaccmax = xp2(r);
    yaccmin = yp1(c);
    yaccmax = yp2(c);
    
    % x, y accumulator vectors
    xac = linspace(xaccmin, xaccmax, xaccstp);
    yac = linspace(yaccmin, yaccmax, yaccstp);

    % Select data within 3sigma of block ranges.
    % The selection of data is done to only consider those points within
    % the dataset that are required to compute the "residuals".
    % The residual function is implemented in cpp (it's really c) and it is
    % compile using the mex command that, in practice creates a library
    % that is called by matlab.
    didx = (nx >= (xac(1) - 3 * sigmax)) & (nx <= (xac(end - 1) + 3 * sigmax)) & (ny >= (yac(1) - 3 * sigmax)) & (ny <= (yac(end - 1) + 3 * sigmax));
    acc = residualMex(nx(didx), ny(didx), month(2:end), displ(didx, 2:end)', xac(1 : end - 1), yac(1 : end - 1), sig, amp);

    % To minimize the use of memory, only two minimum projection of the
    % final results are collected of each block. These are assembled at the
    % end, after all the block have been evaluated.
    [resblk(:, :, i), mampblk(:, :, i)] = min(min(acc(:, :, :, :, 4), [], 3), [], 4);
    [~, msigblk(:, :, i)] = min(min(acc(:, :, :, :, 4), [], 4), [], 3);

end
if exist('h', 'var')
    delete(h);
    clear('h');
end


%% Assemble the results
h = msgbox('Assemblying the results...');
% This is where the results from all the blocks are assembled in the final
% images (arrays).
% After assemblying the blocks, the arrays containing the blocks are 
% eliminated to free memory.
xblkstp = xaccstp - 1;
yblkstp = yaccstp - 1;

% Residual
if show.residual || geotiff.residual || ...
   show.propagated || geotiff.propagated || ...
   show.class || geotiff.class
    finres = single(zeros(yblkstp * N, xblkstp * N));
    for i = 1:N^2
        [c, r] = ind2sub([N, N], i);
        finres(1 + (r - 1) * yblkstp : r * yblkstp, 1 + (c - 1) * xblkstp : c * xblkstp) = resblk(end:-1:1, 1 : end , i);
    end
%     assignin('base', 'finres', finres);  % Troubleshooting
end
clear resblk 

% Amplitude (growth speed)
if show.growthSpeed || geotiff.growthSpeed
    finamp = uint8(zeros(yblkstp * N, xblkstp * N));
    for i = 1:N^2
        [c, r] = ind2sub([N, N], i);
        finamp(1 + (r - 1) * yblkstp : r * yblkstp, 1 + (c - 1) * xblkstp : c * xblkstp) = mampblk(end:-1:1, 1 : end , i);
    end
    
    % Convert to actual values instead of array indices
    amp = single(amp);
    finamp = amp(finamp);
%     assignin('base', 'finamp', finamp);  % Troubleshooting
end
clear mampblk

% Sigma (width/size)
if show.size || geotiff.size || ...
   show.propagated || geotiff.propagated || ...
   show.class || geotiff.class
    finsig = uint8(zeros(yblkstp * N, xblkstp * N));
    for i = 1:N^2
        [c, r] = ind2sub([N, N], i);
        finsig(1 + (r - 1) * yblkstp : r * yblkstp, 1 + (c - 1) * xblkstp : c * xblkstp) = msigblk(end:-1:1, 1 : end , i);
    end
    
    % Convert to actual values instead of array indices
    sig = single(sig);
    finsig = sig(finsig);
%     assignin('base', 'finsig', finsig);  % Troubleshooting
end
clear msigblk


%% Evaluate propagated residual
% This is a process by which each point in the residual is replaced by a
% disk with radius equal to the size of the model that best fitted the data
% at that location. Of interest could be the call to the function
% "imdilate" which is part of the matlab image processing library.

% The '1.0 -' is needed because imdilate is a local maximum operation in
% case of overlap and we are interested in the lowest residual.
if show.propagated || geotiff.propagated || ...
   show.class || geotiff.class
    fininv = 1.0 - finres;
    finpro = imdilate(fininv .* (finsig == sig(1)), strel('disk', double(ceil(sig(1) / (2 * prodel))), 0));
    for n = 2:length(sig)
        finpro = max(finpro, imdilate(fininv .* (finsig == sig(n)), strel('disk', double(ceil(sig(n) / (2 * prodel))), 0)));
    end
    clear fininv
    finpro = 1.0 - finpro;
%     assignin('base', 'finpro', finpro);  % Troubleshooting
end


% Classification of propagated based on user provided ranges
% Values below high are assigned value 0
% Values below medium are assigned value 0.5
% Everything else is 1
% TODO: allow user to select threshold values
if show.class || geotiff.class
    finclass = ones(size(finpro));
    finclass(finpro < 0.3) = 0.5;
    finclass(finpro < 0.15) = 0.0;
%     assignin('base', 'finclass', finclass);  % Troubleshooting
end    

if exist('h', 'var')
    delete(h);
    clear('h');
end


%% Put arrays in the base workspace (for troubleshooting)
% assignin('base', 'nx', nx);  % Troubleshooting
% assignin('base', 'ny', ny);  % Troubleshooting



%% Visualize the results.
h = msgbox('Visualizing results...');

bbox = [xmin, ymin, xmax, ymax];
% assignin('base', 'bbox', bbox);  % Troubleshooting

% Residual
if show.residual
    showResults(finres, bbox, 'Residual', nx, ny);
end

% Propagated
if show.propagated
    showResults(finpro, bbox, 'Propagated residual', nx, ny);   
end

% Growth speed (amplitude)
if show.growthSpeed
    showResults(finpro, bbox, 'Best fitting growth speed (units/month)', nx, ny);   
end

% Size (sigma)
if show.size
    showResults(finpro, bbox, 'Best fitting size (units)', nx, ny);
end

% Classification
if show.class
    showResults(finclass, bbox, 'Classification based on ranges', nx, ny);
end

if exist('h', 'var')
    delete(h);
    clear('h');
end


%% Write the results to file
h = msgbox('Saving results...');
% Create spatial reference
% Note: requires mapping toolbox

BaseName = strcat(path, BaseName);
% assignin('base', 'path', path);  % Troubleshooting
% assignin('base', 'BaseName', BaseName);  % Troubleshooting

if geotiff.residual
    writeGeoTiff(finres, bbox, strcat(BaseName, '-Residual'), ShapeProj);
end

if geotiff.propagated
    writeGeoTiff(finpro, bbox, strcat(BaseName, '-Propagated'), ShapeProj);
end

if geotiff.growthSpeed
    writeGeoTiff(finamp, bbox, strcat(BaseName, '-Growth'), ShapeProj);
end

if geotiff.size
    writeGeoTiff(finsig, bbox, strcat(BaseName, '-Size'), ShapeProj);
end

if geotiff.class
    writeGeoTiff(finclass, bbox, strcat(BaseName, '-Class'), ShapeProj);
end
    
if exist('h', 'var')
    delete(h);
    clear('h');
end










