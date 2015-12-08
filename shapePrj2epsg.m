function ShapeProj = shapePrj2epsg(file)

%%%%% TODO: Modify code so that the type of the coordinate system is
%%%%% returned: geographic vs projected. This is necessary for the
%%%%% geotiffwrite function.

    ShapeProj = [];

    % open shapefile projection file
    [pathstr, name, ~] = fileparts(file);
    sep = filesep; % get os file seperator
    strPrjFile = [pathstr,sep,name, '.prj'];
    fidPrj = fopen(strPrjFile);
    if (fidPrj == -1) % file not found
        dlg = {sprintf(['Projection file not found.\n',...
                        'Provide the EPSG code describing the shapefile coordinates.\n', ...
                        'This will be the assumed coordinate system, the data will NOT\n',...
                        'be reprojected!'])};
        proj = inputdlg(dlg, 'EPSG code?', 1, {'4326'});
        if isempty(proj)
            return
        end
        dlg = {sprintf(['Does the code ', proj{:}, ' correspond to a geographic\n', ...
                        'or a projected coordinates system?'])};
        type = questdlg(dlg, 'Coordinate system type?','GEOGCS', 'PROJCS', 'Cancel', 'GEOGCS');
        if strcmp(type, 'Cancel')
            return
        end
        ShapeProj.type = type;
        ShapeProj.id = proj{:};
        ShapeProj.name = 'Unknown';   
        return
    else % file found
        % read WKT from shapefile projection file. Use textscan rather than 
        % textread as latter will be deprecated
        P = textscan(fidPrj, '%c'); 
        fclose(fidPrj);

        P = P{:}'; %turn cell array into a more usable array string

        % check for projection type using first 6 characters of P
        if strncmpi(P, 'GEOGCS', 6) || strncmpi(P, 'PROJCS', 6) % projection found
            type = P(1:6);
            % get projection EPSG code and name
            id = regexp(P, 'AUTHORITY\["EPSG",([0-9]*)\]', 'tokens', 'once');
            name = regexp(P, '^(?:PROJCS|GEOGCS)\["(\w*)",', 'tokens', 'once');
        else
            prj = regexp(P, '^(\w*)\[', 'tokens', 'once');
            msg = sprintf('Projection type: %s not supported!', prj);
            msgbox(msg, 'Projection not supported!');
        end

        if ~isempty(id) % id found
            ShapeProj.id = id{:};
            ShapeProj.type = type;
            if ~isempty(name)
                ShapeProj.name = name{:};
            else
                ShapeProj.name = 'Unknown';
            end
        end
    end

    % Define output projection
    if ~isempty(ShapeProj) % wkt and id found
        proj = ShapeProj.id;
        name = ShapeProj.name;
        quest = {'Keep coordinate system detected from shapefile:', name, strcat('EPSG code: ', proj)};
        choice = questdlg(quest, 'Confirm the detectd coordinate system', 'Yes', 'No', 'Yes');
        if strcmp(choice, 'No')
            dlg = {sprintf(['Provide the EPSG code describing the shapefile coordinates.\n', ...
                            'This will be the assumed coordinate system, the data will NOT\n',...
                            'be reprojected!'])};
            proj = inputdlg(dlg, 'EPSG code?', 1, {proj});
            if isempty(proj)
                ShapeProj = [];
                return
            end
            dlg = {sprintf(['Does the code ', proj{:}, ' correspond to a geographic\n', ...
                            'or a projected coordinates system?'])};
            type = questdlg(dlg, 'Coordinate system type?','GEOGCS', 'PROJCS', 'Cancel', 'GEOGCS');
            if strcmp(type, 'Cancel')
                ShapeProj = [];
                return
            end
            proj = proj{:};
            name = 'Unknown';   
        end
    else % wkt found but id not found
        quest = {sprintf(['The EPSG code was not found within the shapefile projection file.\n',...
                          'Do you want to search for a matching coordinate system on prj2epsg.org?\n',...
                          '(Internet access required.)'])};
        choice = questdlg(quest, 'Search online?', 'Yes', 'No', 'Yes');
        if strcmp(choice, 'Yes') % look for epsg online
            api = 'http://prj2epsg.org/search.json?terms=';
            res = webread([api P]);
            if res.exact == 1 % if single hit
                proj = res.codes.code;
                name = res.codes.name;
            else % if several, get the most relevant
                proj = res.codes(1).code;
                name = res.codes(1).name;
            end
            quest = {'Keep coordinate system detected from prj2epsg.org:', name, strcat('EPSG code: ', proj)};
            choice = questdlg(quest, 'Confirm detected coordinate system', 'Yes', 'No', 'Yes');
            if strcmp(choice, 'No')
                dlg = {sprintf(['Provide the EPSG code describing the shapefile coordinates.\n', ...
                                'This will be the assumed coordinate system, the data will NOT\n',...
                                'be reprojected!'])};
                proj = inputdlg(dlg, 'EPSG code?', 1, {proj});
                if isempty(proj)
                    ShapeProj = [];
                    return
                end
                dlg = {sprintf(['Does the code ', proj{:} , ' correspond to a geographic\n', ...
                                'or a projected coordinates system?'])};
                type = questdlg(dlg, 'Coordinate system type?','GEOGCS', 'PROJCS', 'Cancel', 'GEOGCS');
                if strcmp(type, 'Cancel')
                    ShapeProj = [];
                    return
                end
                ShapeProj.type = type;
                ShapeProj.id = proj{:};
                ShapeProj.name = 'Unknown';   
            end
        else % user provides epsg
            dlg = {sprintf(['Provide the EPSG code describing the shapefile coordinates.\n', ...
                            'This will be the assumed coordinate system, the data will NOT\n',...
                            'be reprojected!'])};
            proj = inputdlg(dlg, 'EPSG code?', 1, {'4326'});
            if isempty(proj)
                ShapeProj = [];
                return
            end
            dlg = {sprintf(['Does the code ', proj{:}, ' correspond to a geographic\n', ...
                            'or a projected coordinates system?'])};
            type = questdlg(dlg, 'Coordinate system type?','GEOGCS', 'PROJCS', 'Cancel', 'GEOGCS');
            if strcmp(type, 'Cancel')
                ShapeProj = [];
                return
            end
            ShapeProj.type = type;
            ShapeProj.id = proj{:};
            ShapeProj.name = 'Unknown';   
            return
        end
    end
    
    ShapeProj.type = type;
    ShapeProj.id = proj;
    ShapeProj.name = name;   

end


    
