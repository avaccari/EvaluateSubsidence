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

function varargout = EvaluateSubsidenceGUI(varargin)
% EvaluateSubsidenceGUI MATLAB code for EvaluateSubsidenceGUI.fig
%      EvaluateSubsidenceGUI, by itself, creates a new EvaluateSubsidenceGUI or raises the existing
%      singleton*.
%
%      H = EvaluateSubsidenceGUI returns the handle to a new EvaluateSubsidenceGUI or the handle to
%      the existing singleton*.
%
%      EvaluateSubsidenceGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EvaluateSubsidenceGUI.M with the given input arguments.
%
%      EvaluateSubsidenceGUI('Property','_value',...) creates a new EvaluateSubsidenceGUI or raises the
%      existing singleton*.  Starting from the left, property _value pairs are
%      applied to the EvaluateSubsidenceGUI before EvaluateSubsidenceGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid _value makes property application
%      stop.  All inputs are passed to EvaluateSubsidenceGUI_OpeningFcn via varargin.
%
%      *See EvaluateSubsidenceGUI Options on GUIDE's Tools menu.  Choose "EvaluateSubsidenceGUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EvaluateSubsidenceGUI

% Last Modified by GUIDE v2.5 29-Nov-2015 11:38:36

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EvaluateSubsidenceGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @EvaluateSubsidenceGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before EvaluateSubsidenceGUI is made visible.
function EvaluateSubsidenceGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EvaluateSubsidenceGUI (see VARARGIN)

% Choose default command line output for EvaluateSubsidenceGUI
handles.output = hObject;

% Set the info about the software
handles.info.name = 'Subsidence detection';
handles.info.developer = 'VIVA - Andrea Vaccari';
handles.info.contact = 'av9g@virginia.edu';
handles.info.version = '1.0';
handles.info.date = '2015-11-23';
handles.info.notes = {
    'This tool looks within a spatio-temporal point cloud dataset for regions behaving according to a specific subsidence model. The ranges of the model parameters can be specified by the user as well as the desired outputs.', ...
    '', ...
    '- the expected dataset is a ESRI shapefile.', ...
    '- the ''Growth speed range'', ''Size range'', and ''Spatial resolution'' units should match those used in the shapefile.', ...
    '- the coordinate should be located in the ''X'' and ''Y'' atributes of the shapefile.', ...
    '- the time, always in months, is extracted from the atributes in the shapefile matching the format ''DYYYYMMDD''.', ...
    '- the ''DYYYYMMDD'' atributes should contain the displacement information for that date.', ...
    '- the projection is estimated from the EPSG code in the .PRJ file. If the file does not contain an EPSG code, a query is made to prj2epsg.org and the first match is returned. The user can always provide a specific EPSG code to be used. In this case, the data will be assumed to be in the specified projection and NOT reprojected.', ...
    '- GeoTIFFs are saved in the directory where the shapefile is and descriptive suffix are appended,', ...
    '', ...
    'For more informations see the provided example data and', ...
    strcat('Vaccari, A.; Stuecheli, M.; Bruckno, B.; Hoppe, E.; Acton, S.T.; ', ... 
    '"Detection of geophysical features in InSAR point cloud data sets using spatiotemporal models," ', ...
    'International Journal of Remote Sensing, vol.34, no.22, pp.8215-8234. doi: 10.1080/01431161.2013.833357'), ...
    '', ...
    'The development of this tool was supported by USDOT RITA and OST-R.', ...
    '', ...
    'The views, opinions, findings and conclusions reflected in this tool are the responsibility of the authors only and do not represent the official policy or position of the US Department of Transportation/Office of the Assistant Secretary for Research and Technology, or any state or other entity.'};                

% Some default values
handles.show.residual = 0;
set(handles.show_residual, 'Value', handles.show.residual);
handles.show.propagated = 0;
set(handles.show_propagated, 'Value', handles.show.propagated);
handles.show.growthSpeed = 0;
set(handles.show_growthSpeed, 'Value', handles.show.growthSpeed);
handles.show.size = 0;
set(handles.show_size, 'Value', handles.show.size);
handles.show.class = 0;
set(handles.show_class, 'Value', handles.show.class);

handles.geotiff.residual = 0;
set(handles.geotiff_residual, 'Value', handles.geotiff.residual);
handles.geotiff.propagated = 0;
set(handles.geotiff_propagated, 'Value', handles.geotiff.propagated);
handles.geotiff.growthSpeed = 0;
set(handles.geotiff_growthSpeed, 'Value', handles.geotiff.growthSpeed);
handles.geotiff.size = 0;
set(handles.geotiff_size, 'Value', handles.geotiff.size);
handles.geotiff.class = 0;
set(handles.geotiff_class, 'Value', handles.geotiff.class);

handles.options.amplog = 0;
set(handles.amplog, 'Value', handles.options.amplog);
handles.options.siglog = 0;
set(handles.siglog, 'Value', handles.options.siglog);


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes EvaluateSubsidenceGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = EvaluateSubsidenceGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in startAnalysis.
function startAnalysis_Callback(hObject, eventdata, handles)
% hObject    handle to startAnalysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Start subsidence analysis
try
    EvaluateSubsidence(handles.xaccdel_value, ... 
                       handles.yaccdel_value, ...
                       handles.ampmin_value, ...
                       handles.ampmax_value, ...
                       handles.ampstp_value, ...
                       handles.sigmin_value, ...
                       handles.sigmax_value, ...
                       handles.sigstp_value, ...
                       handles.N_value, ...
                       handles.show, ...
                       handles.geotiff, ...
                       handles.options);
catch ME
    uiwait(errordlg(ME.message, ME.identifier));
end
    


               
               
% --- Executes on button press in help.
function help_Callback(hObject, eventdata, handles)
% hObject    handle to help (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Assemble and display the info message box

message = {sprintf('%s\n', handles.info.name),...
           sprintf('%s (%s)\n', handles.info.version, handles.info.date),...
           sprintf('%s - %s\n', handles.info.developer, handles.info.contact)};
message = {message{:}, handles.info.notes{:}};
title='Software Info';
mode='modal';
uiwait(msgbox(message,title,mode));



               
               
function ampmin_Callback(hObject, eventdata, handles)
% hObject    handle to ampmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ampmin as text
%        str2double(get(hObject,'String')) returns contents of ampmin as a double
handles.ampmin_value = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function ampmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ampmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.ampmin_value = 1.0;
set(hObject, 'String', num2str(handles.ampmin_value))

% Update handles structure
guidata(hObject, handles);


function ampmax_Callback(hObject, eventdata, handles)
% hObject    handle to ampmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ampmax as text
%        str2double(get(hObject,'String')) returns contents of ampmax as a double
handles.ampmax_value = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function ampmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ampmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.ampmax_value = 40.0;
set(hObject, 'String', num2str(handles.ampmax_value))

% Update handles structure
guidata(hObject, handles);


function ampstp_Callback(hObject, eventdata, handles)
% hObject    handle to ampstp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ampstp as text
%        str2double(get(hObject,'String')) returns contents of ampstp as a double
handles.ampstp_value = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function ampstp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ampstp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.ampstp_value = 20;
set(hObject, 'String', num2str(handles.ampstp_value))

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in amplog.
function amplog_Callback(hObject, eventdata, handles)
% hObject    handle to amplog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of amplog
handles.options.amplog = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


function sigmin_Callback(hObject, eventdata, handles)
% hObject    handle to sigmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sigmin as text
%        str2double(get(hObject,'String')) returns contents of sigmin as a double
handles.sigmin_value = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function sigmin_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sigmin (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.sigmin_value = 5.0;
set(hObject, 'String', num2str(handles.sigmin_value))

% Update handles structure
guidata(hObject, handles);



function sigmax_Callback(hObject, eventdata, handles)
% hObject    handle to sigmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sigmax as text
%        str2double(get(hObject,'String')) returns contents of sigmax as a double
handles.sigmax_value = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function sigmax_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sigmax (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.sigmax_value = 100.0;
set(hObject, 'String', num2str(handles.sigmax_value))

% Update handles structure
guidata(hObject, handles);



function sigstp_Callback(hObject, eventdata, handles)
% hObject    handle to sigstp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sigstp as text
%        str2double(get(hObject,'String')) returns contents of sigstp as a double
handles.sigstp_value = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function sigstp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sigstp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.sigstp_value = 20;
set(hObject, 'String', num2str(handles.sigstp_value))

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in siglog.
function siglog_Callback(hObject, eventdata, handles)
% hObject    handle to siglog (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of siglog
handles.options.siglog = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


function xaccdel_Callback(hObject, eventdata, handles)
% hObject    handle to xaccdel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of xaccdel as text
%        str2double(get(hObject,'String')) returns contents of xaccdel as a double
handles.xaccdel_value = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function xaccdel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to xaccdel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.xaccdel_value = 2.5;
set(hObject, 'String', num2str(handles.xaccdel_value))

% Update handles structure
guidata(hObject, handles);


function yaccdel_Callback(hObject, eventdata, handles)
% hObject    handle to yaccdel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of yaccdel as text
%        str2double(get(hObject,'String')) returns contents of yaccdel as a double
handles.yaccdel_value = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function yaccdel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to yaccdel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.yaccdel_value = 2.5;
set(hObject, 'String', num2str(handles.yaccdel_value))

% Update handles structure
guidata(hObject, handles);


function N_Callback(hObject, eventdata, handles)
% hObject    handle to N (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of N as text
%        str2double(get(hObject,'String')) returns contents of N as a double
handles.N_value = str2double(get(hObject,'String'));

% Update handles structure
guidata(hObject, handles);

% --- Executes during object creation, after setting all properties.
function N_CreateFcn(hObject, eventdata, handles)
% hObject    handle to N (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

handles.N_value = 50;
set(hObject, 'String', num2str(handles.N_value))

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in show_residual.
function show_residual_Callback(hObject, eventdata, handles)
% hObject    handle to show_residual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_residual
handles.show.residual = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in show_propagated.
function show_propagated_Callback(hObject, eventdata, handles)
% hObject    handle to show_propagated (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_propagated
handles.show.propagated = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in show_growthSpeed.
function show_growthSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to show_growthSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_growthSpeed
handles.show.growthSpeed = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in show_size.
function show_size_Callback(hObject, eventdata, handles)
% hObject    handle to show_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_size
handles.show.size = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in show_class.
function show_class_Callback(hObject, eventdata, handles)
% hObject    handle to show_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of show_class
handles.show.class = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in geotiff_residual.
function geotiff_residual_Callback(hObject, eventdata, handles)
% hObject    handle to geotiff_residual (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of geotiff_residual
handles.geotiff.residual = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in geotiff_propagated.
function geotiff_propagated_Callback(hObject, eventdata, handles)
% hObject    handle to geotiff_propagated (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of geotiff_propagated
handles.geotiff.propagated = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in geotiff_growthSpeed.
function geotiff_growthSpeed_Callback(hObject, eventdata, handles)
% hObject    handle to geotiff_growthSpeed (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of geotiff_growthSpeed
handles.geotiff.growthSpeed = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in geotiff_size.
function geotiff_size_Callback(hObject, eventdata, handles)
% hObject    handle to geotiff_size (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of geotiff_size
handles.geotiff.size = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in geotiff_class.
function geotiff_class_Callback(hObject, eventdata, handles)
% hObject    handle to geotiff_class (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of geotiff_class
handles.geotiff.class = get(hObject,'Value');

% Update handles structure
guidata(hObject, handles);


