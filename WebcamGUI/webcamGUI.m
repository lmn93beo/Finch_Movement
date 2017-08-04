function varargout = webcamGUI(varargin)
% WEBCAMGUI MATLAB code for webcamGUI.fig
%      WEBCAMGUI, by itself, creates a new WEBCAMGUI or raises the existing
%      singleton*.
%
%      H = WEBCAMGUI returns the handle to a new WEBCAMGUI or the handle to
%      the existing singleton*.
%
%      WEBCAMGUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in WEBCAMGUI.M with the given input arguments.
%
%      WEBCAMGUI('Property','Value',...) creates a new WEBCAMGUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before webcamGUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to webcamGUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help webcamGUI

% Last Modified by GUIDE v2.5 09-Sep-2016 16:19:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @webcamGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @webcamGUI_OutputFcn, ...
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


% --- Executes just before webcamGUI is made visible.
function webcamGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to webcamGUI (see VARARGIN)

global cam finish
% Choose default command line output for webcamGUI
handles.output = hObject;

% Initialize the camera
finish = 1;
cam = webcam(1);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes webcamGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = webcamGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in start_pushbutton.
function start_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to start_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cam r_threshold g_threshold b_threshold finish debug
global size_threshold

root = get(handles.root_text, 'String');  %Root of file names
framerate = 30; %fps

choice = questdlg(['Start recording animal ' root ' ?'], ...
	'Yes', 'No');

if ~strcmp(choice, 'Yes')
    error('User chose no');
end

% How many frames to record before writing to log
BUFFER_SIZE = str2double(get(handles.buffersize_text, 'String')) ...
    * framerate * 60;

nsound = str2double(get(handles.soundinterval_text, 'String')) / ...
    str2double(get(handles.buffersize_text, 'String'));

% For log keeping
centroids = zeros(BUFFER_SIZE, 2);
times = zeros(BUFFER_SIZE, 1);
areas = zeros(BUFFER_SIZE, 1);
timestamps = zeros(BUFFER_SIZE, 3);
i = 1;
count = 0;
tic;

finish = 0;
debug = 1;

r_threshold = get(handles.red_slider, 'Value');
g_threshold = get(handles.green_slider, 'Value');
b_threshold = get(handles.blue_slider, 'Value');
size_threshold = get(handles.size_slider, 'Value');

% Set up a sound to be played
fs = 44100;
if nsound > 0
    sig = 1 : fs;
    sig = sin(sig/5);
end

while ~finish %toc < 30
    passed = 0;
    % Capture a raw frame
    while ~passed
        try
            img = snapshot(cam);
            passed = 1;
        catch
            disp('Error. Retrying...');
            pause(10);
        end
    end
    img = imresize(img, 0.5);
    
    % Threshold
    diff = img(:,:,1) < r_threshold & ...
        img(:,:,2) < g_threshold & ...
        img(:,:,3) < b_threshold;
    
    % Remove small areas
    bw2 = bwareaopen(diff, ceil(size_threshold), 8);
 
    % Get centroid
    L = logical(bw2);
    s = regionprops(L, 'area', 'centroid');
    
    area_vector = [s.Area];
    if debug ~= 0
        set(handles.sizes_list, 'String', {sort(area_vector, 'descend')});
    end
    
    [tmp, idx] = max(area_vector);
    if ~isempty(tmp)
        centroids(i,:) = s(idx(1)).Centroid;
        areas(i,:) = s(idx(1)).Area;
    end
    
    times(i) = toc;
    currtime = clock;
    timestamps(i,:) = currtime(4:end);
    tic;
    
    i = i + 1;
    
    
    % Show the image (for debugging)
    if debug == 1
        imshow(img);
        hold on;
        plot(centroids(i-1, 1), centroids(i-1, 2), 'r.', 'MarkerSize', 20);
    elseif debug == 2
        imshow(bw2);
        hold on;
        plot(centroids(i-1, 1), centroids(i-1, 2), 'r.', 'MarkerSize', 20);
    end
    
    if i > BUFFER_SIZE
        % Write the data
        currtime = strrep(datestr(now), ':', '_');
        filename = [root '_' currtime '.csv']
        csvwrite(filename, [times centroids areas timestamps]);
        
        % Reset some variables
        i = 1;
        
        if nsound > 0 && mod(count, nsound) == 0
            sound(sig, fs);
            disp('Sound played');
        end
        
        count = count + 1;
        clear centroids times;
        centroids = zeros(BUFFER_SIZE, 2);
        times = zeros(BUFFER_SIZE, 1);
    end
    
    drawnow;
end

%clear cam
% Write the data one last time
currtime = strrep(datestr(now), ':', '_');
filename = [root '_' currtime '.csv']
csvwrite(filename, [times centroids areas timestamps]);



function red_text_Callback(hObject, eventdata, handles)
% hObject    handle to red_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of red_text as text
%        str2double(get(hObject,'String')) returns contents of red_text as a double


% --- Executes during object creation, after setting all properties.
function red_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to red_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function green_text_Callback(hObject, eventdata, handles)
% hObject    handle to green_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of green_text as text
%        str2double(get(hObject,'String')) returns contents of green_text as a double


% --- Executes during object creation, after setting all properties.
function green_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to green_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function blue_text_Callback(hObject, eventdata, handles)
% hObject    handle to blue_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of blue_text as text
%        str2double(get(hObject,'String')) returns contents of blue_text as a double


% --- Executes during object creation, after setting all properties.
function blue_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to blue_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function red_slider_Callback(hObject, eventdata, handles)
% hObject    handle to red_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global r_threshold
r_threshold = get(hObject, 'Value');
set(handles.red_text, 'String', num2str(r_threshold));


% --- Executes during object creation, after setting all properties.
function red_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to red_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function green_slider_Callback(hObject, eventdata, handles)
% hObject    handle to green_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global g_threshold
g_threshold = get(hObject, 'Value');
set(handles.green_text, 'String', num2str(g_threshold));


% --- Executes during object creation, after setting all properties.
function green_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to green_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function blue_slider_Callback(hObject, eventdata, handles)
% hObject    handle to blue_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global b_threshold
b_threshold = get(hObject, 'Value');
set(handles.blue_text, 'String', num2str(b_threshold));


% --- Executes during object creation, after setting all properties.
function blue_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to blue_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in preview_pushbutton.
function preview_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to preview_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global cam

preview(cam);



function root_text_Callback(hObject, eventdata, handles)
% hObject    handle to root_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of root_text as text
%        str2double(get(hObject,'String')) returns contents of root_text as a double


% --- Executes during object creation, after setting all properties.
function root_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to root_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function buffersize_text_Callback(hObject, eventdata, handles)
% hObject    handle to buffersize_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of buffersize_text as text
%        str2double(get(hObject,'String')) returns contents of buffersize_text as a double


% --- Executes during object creation, after setting all properties.
function buffersize_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to buffersize_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function soundinterval_text_Callback(hObject, eventdata, handles)
% hObject    handle to soundinterval_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of soundinterval_text as text
%        str2double(get(hObject,'String')) returns contents of soundinterval_text as a double


% --- Executes during object creation, after setting all properties.
function soundinterval_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to soundinterval_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in stop_pushbutton.
function stop_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to stop_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global finish
if ~finish
    cla;
    finish = true;
    errordlg('Recording session has ended.', 'End of session')
end


% --- Executes on button press in debug_pushbutton.
function debug_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to debug_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global debug finish;
if ~finish
    cla;
    debug = mod(debug + 1, 3);
end



function sizeslider_text_Callback(hObject, eventdata, handles)
% hObject    handle to sizeslider_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sizeslider_text as text
%        str2double(get(hObject,'String')) returns contents of sizeslider_text as a double


% --- Executes during object creation, after setting all properties.
function sizeslider_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sizeslider_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on slider movement.
function size_slider_Callback(hObject, eventdata, handles)
% hObject    handle to size_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
global size_threshold
size_threshold = get(hObject, 'Value');
set(handles.sizeslider_text, 'String', num2str(size_threshold));

% --- Executes during object creation, after setting all properties.
function size_slider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to size_slider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on selection change in sizes_list.
function sizes_list_Callback(hObject, eventdata, handles)
% hObject    handle to sizes_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns sizes_list contents as cell array
%        contents{get(hObject,'Value')} returns selected item from sizes_list


% --- Executes during object creation, after setting all properties.
function sizes_list_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sizes_list (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
