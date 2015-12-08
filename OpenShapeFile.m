function [ ShapeData, ShapeProj, path, BaseName ] = OpenShapeFile()
    %ShapeFile   Imports the data of a shapefile into the workspace
    %   This function asks the user to select a shape file to import into the
    %   workspace and return the shape file data.

    ShapeData = 0;
    BaseName = '';

    % Get user input to select a specific shape file
    [file, path] = uigetfile({'*.shp', 'Shape Files (*.shp)'}, ...
                             'Choose a shape file...');
                         
    % Check if any file was selected
    if(file == 0)
        path = '';
        return
    end

    % Extract the file name without extension
    [~, BaseName, ~] = fileparts(file);

    % Use the full path file name
    FileName = strcat(path, BaseName);

    % Read shapefile
    h = msgbox('Reading shapefile...');
    ShapeData = shaperead(FileName);
    if exist('h', 'var')
        delete(h);
        clear('h');
    end
    
    % Try to get the projection info
    ShapeProj = shapePrj2epsg(FileName);
    
end

