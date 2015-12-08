function [ displ, coo, height, vel, date ] = GetDisplacementData( ShapeData )
%GETDISPLACEMENTDATA Returns displacement and coordinates
%   Extracts displacement and coordinates of the point cloud. Assumes that
%   the coordinates are in the 'ncst' field of the structure shapeFile and
%   that the displacements are in fields identified by 'Dnnnnnnnn' where n
%   are digits between 0 and 9

    % Extract fields name from the shape file
    fn = fieldnames(ShapeData);
    
    % Cycle through the fields and extract coordinates and the displacement.
    count = 1;
    for n = 1:length(fn)
        % Look for the height contained in the field 'height'
        if (regexp(fn{n}, '^HEIGHT'))
            height = single([ShapeData.(fn{n})]);
        end
        % Look for the velocity contained in the field 'vel'
        if (regexp(fn{n}, '^VEL'))
            vel = single([ShapeData.(fn{n})]');
        end
        % Look for the coordinates contained in the fields 'X' and 'Y'
        if (regexp(fn{n}, '^X'))
            x = [ShapeData.(fn{n})];
        end
        if (regexp(fn{n}, '^Y'))
            y = [ShapeData.(fn{n})];
        end
        % Look for displacement data, identified by the fields 'Dnnnnnnnn'
        % where n is a digit between 0 and 9
        match = regexp(fn{n},'^D[0-9]{8}','match');
        if (~isempty(match))
            date(count) = match;
            temp = [ShapeData.(fn{n})];
            displ(1:length(temp), count) = temp;
            count = count + 1;
        end
    end
    % Stack coordinates
    coo = [x; y]';
    
    displ = single(displ);
end

