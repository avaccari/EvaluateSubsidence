# Subsidence detection tool

This tool looks within a spatio-temporal point cloud dataset for regions 
behaving according to a specific subsidence model. The ranges of the model
parameters can be specified by the user as well as the desired outputs.


Notes:
- the expected dataset is a ESRI shapefile
- the *Growth speed range*, *Size range*, and *Spatial resolution* units 
  should match those used in the shapefile
- the coordinate should be located in the *X* and *Y* atributes of the 
  shapefile
- the time, **always in months**, is extracted from the atributes in the 
  shapefile matching the format "DYYYYMMDD"
- the "DYYYYMMDD" atributes should contain the displacement information 
  for that date
- the projection is estimated from the EPSG code in the .PRJ file. If the 
  file does not contain an EPSG code, a query is made to prj2epsg.org and 
  the first match is returned. The user can always provide a specific EPSG 
  code to be used. In this case, the data will be assumed to be in the 
  specified projection and **NOT** reprojected.
- GeoTIFFs are saved in the directory where the shapefile is and 
  descriptive suffix are appended.

For more informations see the provided example data and

Vaccari, A.; Stuecheli, M.; Bruckno, B.; Hoppe, E.; Acton, S.T.; 
*"Detection of geophysical features in InSAR point cloud data sets using 
spatiotemporal models,"* International Journal of Remote Sensing, vol.34, 
no.22, pp.8215-8234. doi: [10.1080/01431161.2013.833357](http://viva-lab.ece.virginia.edu/refbase/files/vaccari/2013/71_Vaccari_etal2013.pdf)

The development of this tool was supported by USDOT RITA and OST-R.

The views, opinions, findings and conclusions reflected in this tool are 
the responsibility of the authors only and do not represent the official 
policy or position of the US Department of Transportation/Office of the 
Assistant Secretary for Research and Technology, or any state or other 
entity.

To compile the required mex files, execute the following command from the
MATLAB prompt:

*mex residualMex.cpp residual.cpp*

The executables are self contained while, running the source code directly, 
requries the mapping toolbox in order to generate the georeferenced TIFF 
files.

The executables will download and install the MATLAB runtime environment.

The **x64** version is for **64-bit Windows**.

The **maci64** version is for **64-bit Mac OS X**.

## Revision history
### 2015-12-07 (Rev. 1.0)
First release.
