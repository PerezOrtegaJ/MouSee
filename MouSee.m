classdef MouSee < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        MouSeeUIFigure                  matlab.ui.Figure
        StimuliPanel                    matlab.ui.container.Panel
        RunButton                       matlab.ui.control.StateButton
        GenerategratingsButton          matlab.ui.control.StateButton
        TrialLabel                      matlab.ui.control.Label
        DirectionLabel                  matlab.ui.control.Label
        PreviewImage                    matlab.ui.control.Image
        TimeLabel                       matlab.ui.control.Label
        DirectionsLabel                 matlab.ui.control.Label
        DurationPanel                   matlab.ui.container.Panel
        RepetitionsEditField            matlab.ui.control.NumericEditField
        GrayRndSpinner                  matlab.ui.control.Spinner
        GrayEditField                   matlab.ui.control.NumericEditField
        StimulusEditField               matlab.ui.control.NumericEditField
        Label                           matlab.ui.control.Label
        RepetitionsEditFieldLabel       matlab.ui.control.Label
        GraysLabel                      matlab.ui.control.Label
        StimulussLabel                  matlab.ui.control.Label
        GratingsconfigurationPanel      matlab.ui.container.Panel
        OutputDropDown                  matlab.ui.control.DropDown
        OutputvoltageDropDownLabel      matlab.ui.control.Label
        SinusoidalCheckBox              matlab.ui.control.CheckBox
        FrequencyHzEditFieldLabel       matlab.ui.control.Label
        GratingssizepixelsLabel         matlab.ui.control.Label
        RandomCheckBox                  matlab.ui.control.CheckBox
        FrequencyHzEditField            matlab.ui.control.NumericEditField
        DriftingCheckBox                matlab.ui.control.CheckBox
        SizeEditField                   matlab.ui.control.NumericEditField
        DirectionsDropDown              matlab.ui.control.DropDown
        DirectionsDropDownLabel         matlab.ui.control.Label
        ActivatestimulationwindowPanel  matlab.ui.container.Panel
        ScreenSizeLabel                 matlab.ui.control.Label
        DefaultscreenDropDown           matlab.ui.control.DropDown
        DefaultscreenDropDownLabel      matlab.ui.control.Label
        SelectscreenLabel               matlab.ui.control.Label
        WindowLamp                      matlab.ui.control.Lamp
        StimulationWindowSwitch         matlab.ui.control.RockerSwitch
        SkipCheckBox                    matlab.ui.control.CheckBox
        MonitorDropDown                 matlab.ui.control.DropDown
    end

    
    properties (Access = public)
        skip_test = 0;
        screen_number = 1;
        window = 0;
        default_screen = 128;
        static_gratings = [];
        default_screen_image = [];
        static_gratings_image = [];
        external_texture = [];
        half_width_w = 0;
        half_height_w = 0;
        gray = 128;
        increment = 128;
        real_degrees = [0 45 90 135 180 225 270 315];
        num_stim = 8;
        grating_pixels = 200;
        stim_duration = 2;
        gray_duration = 3;
        gray_rnd = 0;
        repetitions = 10;
        cycles_per_second = 5;
        rand_stim = true;
        sinusoidal = true;
        output_stims = false;
        rotating = false;
        rotation_angles = [];
        workspace_stim = false;
        workspace_data = [];
        
        % textures
        tex = [];
        movie_frames = [];
        movie_IDs = [];
        image = [];
        
        ni
        cancel = false;
    end
    
    methods (Access = private)
        
        function ComputeFinalTime(app)
            total = (app.stim_duration+app.gray_duration)*app.num_stim*app.repetitions;
            app.TimeLabel.Text = sprintf('Total time:\n %.1f s = %.1f min',total,total/60);
            
            % Set properties
            app.GenerategratingsButton.Text = 'Generate gratings';
            app.GenerategratingsButton.BackgroundColor = [0.95 0.95 0.95];
            app.RunButton.Enable = false;
        end
        
        function UpdatePreview(app)
            f = app.grating_pixels/(2*pi);
            angle = 0;
            phase = 2*pi;
            
            % generate grating frame
            [x,y] = meshgrid(-app.half_width_w:app.half_width_w,-app.half_height_w:app.half_height_w);
            a = cos(angle)/f;
            b = sin(angle)/f;
            
            % get sinusoidal or square gratings
            if app.sinusoidal
                m = sin(a*x+b*y+phase);
            else
                m = sign(sin(a*x+b*y+phase));
            end
            
            % Set properties
            app.DirectionLabel.Text = 'preview';
            app.PreviewImage.ImageSource = repmat(mat2gray(round(app.gray+app.increment*m)),1,1,3);
            app.GenerategratingsButton.Text = 'Generate gratings';
            app.GenerategratingsButton.BackgroundColor = [0.95 0.95 0.95];
            app.RunButton.Enable = false;
        end

        function Set_Default_Screen(app)
            % Set properties
            app.PreviewImage.ImageSource = app.default_screen_image;
            app.DirectionLabel.Text = '';
        end
    
        function GetMonitors(app)
            % Get the list of screens and choose the one with the highest screen number
            screens = Screen('Screens');
            if ismac
                n_screens = length(screens);
                app.screen_number = n_screens-1;
            else
                n_screens = max(screens);
                app.screen_number = n_screens;
            end
            
            if n_screens<=1
                msgbox(['This app requires at least 2 monitors: one for stimulating ' ...
                    'and other for controling.'],'Error','error')
            else
                app.MonitorDropDown.Items = cellstr(num2str((1:n_screens)'));
                app.MonitorDropDown.Value = num2str(n_screens);
            end
        end
        
        function  [tex,movie_frames,movie_IDs,image] = GetTextureDrifting(app,angle)
            % Set the angle
            angleRad = mod(180-angle,360)*pi/180;
            
            % Run the movie animation for a fixed period
            fpsScreen = Screen('FrameRate',app.screen_number);
            if ~fpsScreen
                fpsScreen = 60;
            end
                    
            % Get number of frames and spatial frequency
            nFrames = round(fpsScreen/app.FrequencyHzEditField.Value);
            f = app.SizeEditField.Value/(2*pi);
            
            % Convert movie duration in seconds to duration in frames to draw:
            movie_frames = round(app.StimulusEditField.Value*fpsScreen);
            movie_IDs = mod(0:(movie_frames-1),nFrames)+1;
                    
            % Compute each frame of the movie
            tex = zeros(1,nFrames);
            for i = 1:nFrames
                phase = (i/nFrames)*2*pi;
                
                % generate grating frame
                [x,y] = meshgrid(-app.half_width_w:app.half_width_w,...
                    -app.half_height_w:app.half_height_w);
                a = cos(angleRad)/f;
                b = sin(angleRad)/f;
                
                % get sinusoidal or square gratings
                if app.sinusoidal
                    m = sin(a*x+b*y+phase);
                else
                    m = sign(sin(a*x+b*y+phase));
                end
                if i==1
                    image = mat2gray(repmat(round(app.gray+app.increment*m),1,1,3));
                end
                tex(i) = Screen('MakeTexture',app.window,round(app.gray+app.increment*m));
            end
        end
        
        function  [tex,image] = GetTexture(app,angle)
            % Set the angle
            angleRad = mod(180-angle,360)*pi/180;
            
            % Get spatial frequency
            f = app.SizeEditField.Value/(2*pi);
                    
            % Generate grating frame
            phase = 2*pi;
            [x,y] = meshgrid(-app.half_width_w:app.half_width_w,...
                -app.half_height_w:app.half_height_w);
            a = cos(angleRad)/f;
            b = sin(angleRad)/f;
            
            % get sinusoidal or square gratings
            if app.sinusoidal
                m = sin(a*x+b*y+phase);
            else
                m = sign(sin(a*x+b*y+phase));
            end
            image = mat2gray(repmat(round(app.gray+app.increment*m),1,1,3));
            
            tex = Screen('MakeTexture',app.window,round(app.gray+app.increment*m));
        end
        
        function Canceling(app)
            app.RunButton.Text = 'Run';

            % Default screen color
            if strfind(app.DefaultscreenDropDown.Value,'%')
                Screen('FillRect',app.window,app.default_screen);
            elseif strfind(app.DefaultscreenDropDown.Value,'º')
                Screen('DrawTexture',app.window,app.static_gratings);
            else
                Screen('DrawTexture',app.window,app.default_screen);
            end
            Screen('Flip',app.window);
            if app.output_stims
                app.ni.write(0);
            end
            app.DirectionLabel.Text = '';
            app.PreviewImage.ImageSource = app.default_screen_image;
            drawnow

            % Enable controls
            app.GratingsconfigurationPanel.Enable = 'on';
            app.DurationPanel.Enable = 'on';
            app.ActivatestimulationwindowPanel.Enable = 'on';
        end
        
        function [tex,movie_frames,movie_IDs,image,rotation_angles] = GetTextureRotating(app,angle,clockwise)
            rotation_angle = app.FrequencyHzEditField.Value;

            % Run the movie animation for a fixed period
            fpsScreen = Screen('FrameRate',app.screen_number);
            if ~fpsScreen
                fpsScreen = 60;
            end
                    
            % Get number of frames and spatial frequency
            period_rotation = app.StimulusEditField.Value;
            frequency_rotation = 1/period_rotation;
            n_frames = round(fpsScreen/frequency_rotation);
            spatial_frequency = app.SizeEditField.Value/(2*pi);

            % Set initial and final angle
            ini_angle_rad = angle*pi/180;
            if clockwise
                fin_angle_rad = (angle+rotation_angle)*pi/180;
            else
                fin_angle_rad = (angle-rotation_angle)*pi/180;
            end
            step = (fin_angle_rad-ini_angle_rad)/n_frames;
            rotation_angle_rad = ini_angle_rad:step:fin_angle_rad;
            rotation_angles = rotation_angle_rad*180/pi;

            % Convert movie duration in seconds to duration in frames to draw:
            movie_frames = round(period_rotation*fpsScreen);
            movie_IDs = mod(0:(movie_frames-1),n_frames)+1;
                    
            % Compute each frame of the movie
            tex = zeros(1,n_frames);
            for i = 1:n_frames
                % generate grating frame
                [x,y] = meshgrid(-app.half_width_w:app.half_width_w,...
                    -app.half_height_w:app.half_height_w);
                a = cos(rotation_angle_rad(i))/spatial_frequency;
                b = sin(rotation_angle_rad(i))/spatial_frequency;
                
                % get sinusoidal or square gratings
                if app.sinusoidal
                    m = sin(a*x+b*y);
                else
                    m = sign(sin(a*x+b*y));
                end
                if i==1
                    image = mat2gray(repmat(round(app.gray+app.increment*m),1,1,3));
                end
                tex(i) = Screen('MakeTexture',app.window,round(app.gray+app.increment*m));
            end
        end
        
        function [tex,image] = GetWorkspaceImage(app,index)
            % Set the angle
            if length(size(app.workspace_data))==3
                mat = repmat(app.workspace_data(:,:,index),1,1,3);
                mat = imresize(mat,[app.half_height_w*2 app.half_width_w*2]);
                image = mat2gray(mat);
            elseif length(size(app.workspace_data))==4
                mat = app.workspace_data(:,:,:,index);
                mat = imresize(mat,[app.half_height_w*2 app.half_width_w*2]);
                image = mat2gray(mat);
            end
            tex = Screen('MakeTexture',app.window,mat);
        end
    end
    

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            GetMonitors(app)
            StimulationWindowSwitchValueChanged(app,[])        
            ComputeFinalTime(app)
            if app.half_width_w
                UpdatePreview(app)
            end
        end

        % Value changed function: RunButton
        function RunButtonPushed(app, event)
            if app.RunButton.Value
                % change text
                app.RunButton.Text = 'Stop';
                
                % Disable controls
                app.GratingsconfigurationPanel.Enable = 'off';
                app.DurationPanel.Enable = 'off';
                app.ActivatestimulationwindowPanel.Enable = 'off';
                
                % Use realtime priority for better timing precision:
                priorityLevel = MaxPriority(app.window);
                Priority(priorityLevel);
                
                % Start the stimuli generation
                app.cancel = false;
                nTrials = 1;
                tic
                for k = 1:app.repetitions
                    
                    % Do a random permutation of the stimuli
                    if app.rand_stim
                        stimOutput = randperm(app.num_stim);
                    else
                        stimOutput = 1:app.num_stim;
                    end
                                        
                    for j = 1:app.num_stim
                        if app.cancel
                            Canceling(app)
                            return;
                        end
                        
                        % Get current stim
                        stim = stimOutput(j);
                        
                        % Animation loop
                        delay = app.gray_duration+rand*app.gray_rnd*2-app.gray_rnd;
                        t = toc;
                        if t<delay
                            app.TrialLabel.Text = ['   delay of ' num2str(delay,'%.1f') ' s'...
                                newline 'trial ' num2str(nTrials)];
                            drawnow
                            pause(delay-t)
                        else
                            app.TrialLabel.Text = ['It couldn''t achieve the time: ' ...
                                num2str(t-delay) 's extra'];
                        end
                        real_angle = app.real_degrees(stim);
                        
                        % Plot next gratings 
                        app.PreviewImage.ImageSource = app.image{stim};

                        % Rotating gratings
                        if app.rotating
                            % Plot angle
                            app.DirectionLabel.Text = [num2str(real_angle) '° ' app.DirectionsDropDown.Value(1)];
                            drawnow
                            
                            % Plot movie gratings
                            for i = 1:app.movie_frames{stim}
                                if app.cancel
                                    Canceling(app)
                                    return;
                                end
                                
                                % Draw image
                                id = app.movie_IDs{stim};
                                tex_i = app.tex{stim};
                                Screen('DrawTexture',app.window,tex_i(id(i)));
                                Screen('Flip',app.window);
                                
                                if app.output_stims
                                    % 0deg = 0.5V, 45deg = 1V, ..., 315deg = 4V
                                    app.ni.write(mod(app.rotation_angles{stim}(i),360)/90+0.5);
                                end
                            end
                        elseif app.workspace_stim
                            % Static gratings
                            % Plot angle
                            app.DirectionLabel.Text = ['image ' num2str(stim)];
                            drawnow
                            
                            % Draw static image
                            tex_i = app.tex{stim};
                            Screen('DrawTexture',app.window,tex_i);
                            Screen('Flip',app.window);
                            
                            if app.output_stims
                                % 0deg = 0.5V, 45deg = 1V, ..., 315deg = 4V
                                app.ni.write(real_angle/90+0.5);
                            end
                            pause(app.StimulusEditField.Value)

                        elseif app.DriftingCheckBox.Value
                            % Drifitng gratings
                            % Plot direction and angle
                            app.DirectionLabel.Text = [app.DirectionsLabel.Text(stim) newline...
                                num2str(real_angle) '°'];
                            drawnow
                            
                            % Plot movie gratings
                            for i = 1:app.movie_frames{stim}
                                if app.cancel
                                    Canceling(app)
                                    return;
                                end
                                
                                % Draw image
                                id = app.movie_IDs{stim};
                                tex_i = app.tex{stim};
                                Screen('DrawTexture',app.window,tex_i(id(i)));
                                Screen('Flip',app.window);
                                
                                if app.output_stims
                                    % 0deg = 0.5V, 45deg = 1V, ..., 315deg = 4V
                                    app.ni.write(real_angle/90+0.5);
                                end
                            end
                        else
                            % Static gratings
                            % Plot angle
                            app.DirectionLabel.Text = [num2str(real_angle) '°'];
                            drawnow
                            
                            % Draw static image
                            tex_i = app.tex{stim};
                            Screen('DrawTexture',app.window,tex_i);
                            Screen('Flip',app.window);
                            
                            if app.output_stims
                                % 0deg = 0.5V, 45deg = 1V, ..., 315deg = 4V
                                app.ni.write(real_angle/90+0.5);
                            end
                            pause(app.StimulusEditField.Value)
                        end
                        
                        % Default screen color
                        if strfind(app.DefaultscreenDropDown.Value,'%')
                            Screen('FillRect',app.window,app.default_screen);
                        elseif strfind(app.DefaultscreenDropDown.Value,'º')
                            Screen('DrawTexture',app.window,app.static_gratings);
                        end
                        Screen('Flip',app.window);
                        if app.output_stims
                            app.ni.write(0);
                        end
                        app.DirectionLabel.Text = '';
                        app.PreviewImage.ImageSource = app.default_screen_image;
                        drawnow
                        nTrials = nTrials+1;
                        tic
                    end
                end
                app.RunButton.Text = 'Run';
                app.RunButton.Value = false;
                app.DirectionLabel.Text = '';
                app.TrialLabel.Text = '';
                
                % Enable controls
                app.GratingsconfigurationPanel.Enable = 'on';
                app.DurationPanel.Enable = 'on';
                app.ActivatestimulationwindowPanel.Enable = 'on';
            else
                app.cancel = true;
            end
        end

        % Value changed function: StimulationWindowSwitch
        function StimulationWindowSwitchValueChanged(app, event)
            value = app.StimulationWindowSwitch.Value;
            if strcmp(value,'On')
                % Skip test on Mac
                Screen('Preference', 'SkipSyncTests', app.skip_test);
                
                % OpenGL Psychtoolbox
                AssertOpenGL;
            
                % Get black and white color values
                try
                    white = WhiteIndex(app.screen_number);
                    black = BlackIndex(app.screen_number);
                catch
                    white = 255;
                    black = 0;
                end

                if white==1
                    white = 255;
                end
            
                % Make gray
                app.gray = round((white+black)/2);
                
                % Contrast 'app.increment' range for given white and gray values:
                app.increment = white-app.gray;
            
                % Open fullscreen gray window
                try
                    [app.window,rect] = Screen('OpenWindow',app.screen_number,app.default_screen);
                    app.half_width_w = round(rect(3)/2);
                    app.half_height_w = round(rect(4)/2);
                    DefaultscreenDropDownValueChanged(app,[])
                    UpdatePreview(app)
                    
                    % Change property values
                    app.WindowLamp.Color = [0,1,0];
                    app.SkipCheckBox.Enable = false;
                    app.MonitorDropDown.Enable = false;
                    app.GenerategratingsButton.Enable = true;
                    app.DefaultscreenDropDown.Enable = true;
                    app.ScreenSizeLabel.Text = ['screen size: ' num2str(rect(3)) 'x' num2str(rect(4))];
                catch
                    % Close window:
                    Priority(0);
                    Screen('CloseAll')

                    % Change property values
                    app.WindowLamp.Color = [1,0,0];
                    app.StimulationWindowSwitch.Value = 'Off';
                    app.SkipCheckBox.Enable = true;
                    app.MonitorDropDown.Enable = true;
                    app.GenerategratingsButton.Enable = false;
                    app.DefaultscreenDropDown.Enable = false;
                end
            else
                % Close window:
                Priority(0);
                Screen('CloseAll')
                
                % Change property values
                app.WindowLamp.Color = [0.5,0.5,0.5];
                app.ScreenSizeLabel.Text = 'screen size: ----x----';
                app.GenerategratingsButton.Text = 'Generate gratings';
                app.GenerategratingsButton.BackgroundColor = [0.95 0.95 0.95];
                app.GenerategratingsButton.Enable = false;
                app.SkipCheckBox.Enable = true;
                app.MonitorDropDown.Enable = true;
                app.RunButton.Enable = false;
                app.DefaultscreenDropDown.Enable = false;
            end
            
        end

        % Value changed function: DirectionsDropDown
        function DirectionsDropDownValueChanged(app, event)
            value = app.DirectionsDropDown.Value;
            app.DirectionsLabel.Text = value;
            app.DirectionsDropDown.BackgroundColor = [0.96 0.96 0.96];
            if value(1)=='↻'||value(1)=='↺'
                % Enable/disable controls
                app.SizeEditField.Enable = 'on';
                app.DriftingCheckBox.Enable = 'off';
                app.FrequencyHzEditField.Enable = 'on';
                app.SinusoidalCheckBox.Enable = 'on';

                % Set properties
                app.FrequencyHzEditFieldLabel.Text = 'Rotation (º):';
                app.FrequencyHzEditField.Value = 180;
                app.rotating = true;
                app.workspace_stim = false;
                value = value(2:end);
            elseif value(1)=='→'||value(1)=='↗'||value(1)=='↑'||value(1)=='↖'||...
                   value(1)=='←'||value(1)=='↙'||value(1)=='↓'||value(1)=='↘'
                % Enable/disable controls
                app.SizeEditField.Enable = 'on';
                app.DriftingCheckBox.Enable = 'on';
                app.SinusoidalCheckBox.Enable = 'on';
                if ~app.DriftingCheckBox.Value
                    app.FrequencyHzEditField.Enable = 'off';
                end

                % Set properties
                app.FrequencyHzEditFieldLabel.Text = 'Frequency (Hz):';
                app.FrequencyHzEditField.Value = 2;
                app.rotating = false;
                app.workspace_stim = false;
            else
                % Enable/disable controls
                app.SizeEditField.Enable = 'off';
                app.DriftingCheckBox.Enable = 'off';
                app.FrequencyHzEditField.Enable = 'off';
                app.SinusoidalCheckBox.Enable = 'off';

                % Set properties
                app.rotating = false;
                app.workspace_stim = true;
            end

            if app.workspace_stim
                % Check if variable exist
                if evalin('base',['exist(''' value ''',''var'')'])
                    app.workspace_data = evalin('base',value);
                    if length(size(app.workspace_data))==3
                        app.num_stim = size(app.workspace_data,3);
                    elseif length(size(app.workspace_data))==4
                        app.num_stim = size(app.workspace_data,4);
                    end
                    app.real_degrees = (1:app.num_stim)*360/app.num_stim;
                    app.DirectionsDropDown.BackgroundColor = [0 1 0];
                else
                    app.num_stim = 0;
                    app.DirectionsDropDown.BackgroundColor = [1 0 0];
                end
            else
                real_deg = [0 45 90 135 180 225 270 315];
                arrows = '→↗↑↖←↙↓↘';
                app.real_degrees = [];
                for i = 1:8
                    if contains(value,arrows(i))
                        app.real_degrees(end+1) = real_deg(i);
                    end
                end
                app.num_stim = length(app.real_degrees);
            end            
            ComputeFinalTime(app)
        end

        % Value changed function: SizeEditField
        function SizeEditFieldValueChanged(app, event)
            app.grating_pixels = app.SizeEditField.Value;
            DefaultscreenDropDownValueChanged(app,event)
            UpdatePreview(app)
        end

        % Value changed function: FrequencyHzEditField
        function FrequencyHzEditFieldValueChanged(app, event)
            app.cycles_per_second = app.FrequencyHzEditField.Value;
            UpdatePreview(app)
        end

        % Value changed function: RandomCheckBox
        function RandomCheckBoxValueChanged(app, event)
            app.rand_stim = app.RandomCheckBox.Value;
        end

        % Value changed function: SinusoidalCheckBox
        function SinusoidalCheckBoxValueChanged(app, event)
            app.sinusoidal = app.SinusoidalCheckBox.Value;
            UpdatePreview(app)
        end

        % Value changed function: SkipCheckBox
        function SkipCheckBoxValueChanged(app, event)
            if app.SkipCheckBox.Value
                app.skip_test = 1;
                app.SkipCheckBox.FontColor = [1 0 0];
            else
                app.skip_test = 0;
                app.SkipCheckBox.FontColor = [0 0 0];
            end
        end

        % Value changed function: OutputDropDown
        function OutputDropDownValueChanged(app, event)
            value = app.OutputDropDown.Value;
            if strcmp(value,'None')
                app.output_stims = false;
                app.OutputDropDown.BackgroundColor = [0.96 0.96 0.96];
            else
                app.output_stims = true;
                device = value(1:4);
                channel = value(8:10);
                try
                    app.ni = daq('ni');
                    app.ni.addoutput(device,channel,'Voltage');
                    app.ni.IsContinuous = true;
                    app.ni.write(0);
                    app.OutputDropDown.BackgroundColor = [0 1 0];
                catch me
                    app.OutputDropDown.BackgroundColor = [1 1 0];
                    msgbox(me.identifier,"Warning","warn","modal")
                end
            end
        end

        % Value changed function: StimulusEditField
        function StimulusEditFieldValueChanged(app, event)
            app.stim_duration = app.StimulusEditField.Value;
            ComputeFinalTime(app)
        end

        % Value changed function: GrayEditField
        function GrayEditFieldValueChanged(app, event)
            app.gray_duration = app.GrayEditField.Value;
            if app.gray_duration>0
                app.GrayRndSpinner.Limits = [0 app.gray_duration];
                app.GrayRndSpinner.Enable = true;
            else
                app.GrayRndSpinner.Limits = [0 inf];
                app.GrayRndSpinner.Enable = false;
            end
            ComputeFinalTime(app)
        end

        % Value changed function: RepetitionsEditField
        function RepetitionsEditFieldValueChanged(app, event)
            app.repetitions = app.RepetitionsEditField.Value;
            ComputeFinalTime(app)
        end

        % Close request function: MouSeeUIFigure
        function MouSeeUIFigureCloseRequest(app, event)
            try
                Priority(0);
                Screen('CloseAll')
                delete(app)
            catch
                delete(app)
            end
            
        end

        % Value changed function: MonitorDropDown
        function MonitorDropDownValueChanged(app, event)
            if ismac
                app.screen_number = str2double(app.MonitorDropDown.Value)-1;
            else
                app.screen_number = str2double(app.MonitorDropDown.Value);
            end
        end

        % Value changed function: GrayRndSpinner
        function GrayRndSpinnerValueChanged(app, event)
            app.gray_rnd = app.GrayRndSpinner.Value;
        end

        % Value changed function: DriftingCheckBox
        function DriftingCheckBoxValueChanged(app, event)
            if app.DriftingCheckBox.Value
                app.FrequencyHzEditField.Enable = true;
            else
                app.FrequencyHzEditField.Enable = false;
            end
            UpdatePreview(app)
        end

        % Value changed function: GenerategratingsButton
        function GenerategratingsButtonValueChanged(app, event)
            value = app.GenerategratingsButton.Value;
            if value
                for i = 1:app.num_stim
                    % Rotating gratings
                    if app.workspace_stim
                        [app.tex{i},app.image{i}] = GetWorkspaceImage(app,i);
                    elseif app.DirectionsDropDown.Value(1)=='↺'
                        [app.tex{i},app.movie_frames{i},app.movie_IDs{i},app.image{i},...
                            app.rotation_angles{i}] = ...
                            GetTextureRotating(app,app.real_degrees(i),false);
                    elseif app.DirectionsDropDown.Value(1)=='↻'
                        [app.tex{i},app.movie_frames{i},app.movie_IDs{i},app.image{i},...
                            app.rotation_angles{i}] = ...
                            GetTextureRotating(app,app.real_degrees(i),true);
                    elseif app.DriftingCheckBox.Value
                        [app.tex{i},app.movie_frames{i},app.movie_IDs{i},app.image{i}] = ...
                            GetTextureDrifting(app,app.real_degrees(i));
                    else
                        [app.tex{i},app.image{i}] = GetTexture(app,app.real_degrees(i));
                    end
                end
                app.RunButton.Enable = true;
                app.GenerategratingsButton.BackgroundColor = [0 1 0];
                app.GenerategratingsButton.Value = false;
                app.GenerategratingsButton.Text = 'Gratings generated!';
            end
        end

        % Value changed function: DefaultscreenDropDown
        function DefaultscreenDropDownValueChanged(app, event)
            value = app.DefaultscreenDropDown.Value;
            app.DefaultscreenDropDown.BackgroundColor = [0.96 0.96 0.96];
            switch value
                case {'0% - black','10% - gray','20% - gray','30% - gray','40% - gray',...
                      '50% - gray','60% - gray','70% - gray','80% - gray','90% - gray',...
                      '100% - white'}
                    % Grayscale
                    id = strfind(value,'%');
                    color = str2double(value(1:id-1));
                    app.default_screen = round(color/100*255)+1;
                    [~,im] = GetTexture(app,0);
                    app.default_screen_image = uint8(app.default_screen*ones(size(im)));
                    Screen('FillRect',app.window,app.default_screen);
                    Screen('Flip',app.window);
                case {'0º - gratings','45º - gratings','90º - gratings','135º - gratings'}
                    % Gratings
                    id = strfind(value,'º');
                    angle = str2double(value(1:id-1));
                    [app.static_gratings,app.default_screen_image] = GetTexture(app,angle);
                    Screen('DrawTexture',app.window,app.static_gratings);
                    Screen('Flip',app.window);
                case '...'
                    % Import image
                    [file_name,path] = uigetfile('*.png;*.jpg;*.jpeg;*.tiff','Select an image');
                    
                    if file_name
                       file = [path file_name];
                       im = imread(file);
                       app.external_texture = Screen('MakeTexture',app.window,uint8(im));
                    else
                       app.default_screen = 128;
                       app.DefaultscreenDropDown.Value = 6;
                    end
                otherwise
                    if evalin('base',['exist(''' value ''',''var'')'])
                        app.default_screen = evalin('base',value);
                        if length(size(app.default_screen))==2
                            app.default_screen = repmat(app.default_screen,1,1,3);
                        end
                        Screen('DrawTexture',app.window,app.default_screen);
                        Screen('Flip',app.window);
                        app.DefaultscreenDropDown.BackgroundColor = [0 1 0];
                    else
                        app.DefaultscreenDropDown.BackgroundColor = [1 0 0];
                    end

            end
            Set_Default_Screen(app)
        end

        % Drop down opening function: DirectionsDropDown
        function DirectionsDropDownOpening(app, event)
            basic_items = {'→↗↑↖←↙↓↘','→↗↑↖','←↙↓↘','→↑←↓','→↑','←↓','↗↖','↙↘',...
                           '→','↗','↑','↖','←','↙','↓','↘',...
                           '↻→↗↑↖','↻→↑','↻↗↖','↻→','↻↗','↻↑','↻↖',...
                           '↺→↗↑↖','↺→↑','↺↗↖','↺→','↺↗','↺↑','↺↖'};
            data_strings = evalin('base','who');
            app.DirectionsDropDown.Items = [basic_items data_strings'];
        end

        % Drop down opening function: DefaultscreenDropDown
        function DefaultscreenDropDownOpening(app, event)
            basic_items = {'0% - black','10% - gray','20% - gray','30% - gray','40% - gray',...
                           '50% - gray','60% - gray','70% - gray','80% - gray','90% - gray',...
                           '100% - white','0º - gratings','45º - gratings','90º - gratings',...
                           '135º - gratings'};
            data_strings = evalin('base','who');
            app.DirectionsDropDown.Items = [basic_items data_strings'];
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create MouSeeUIFigure and hide until all components are created
            app.MouSeeUIFigure = uifigure('Visible', 'off');
            app.MouSeeUIFigure.Position = [100 100 510 549];
            app.MouSeeUIFigure.Name = 'MouSee';
            app.MouSeeUIFigure.CloseRequestFcn = createCallbackFcn(app, @MouSeeUIFigureCloseRequest, true);

            % Create ActivatestimulationwindowPanel
            app.ActivatestimulationwindowPanel = uipanel(app.MouSeeUIFigure);
            app.ActivatestimulationwindowPanel.AutoResizeChildren = 'off';
            app.ActivatestimulationwindowPanel.Title = 'Activate stimulation window';
            app.ActivatestimulationwindowPanel.Position = [8 365 226 170];

            % Create MonitorDropDown
            app.MonitorDropDown = uidropdown(app.ActivatestimulationwindowPanel);
            app.MonitorDropDown.Items = {'1'};
            app.MonitorDropDown.ValueChangedFcn = createCallbackFcn(app, @MonitorDropDownValueChanged, true);
            app.MonitorDropDown.Position = [103 120 101 22];
            app.MonitorDropDown.Value = '1';

            % Create SkipCheckBox
            app.SkipCheckBox = uicheckbox(app.ActivatestimulationwindowPanel);
            app.SkipCheckBox.ValueChangedFcn = createCallbackFcn(app, @SkipCheckBoxValueChanged, true);
            app.SkipCheckBox.Tooltip = {'Windows users: If skip is selected this will seriously impair proper stimulus presentation and stimulus presentation timing!'; 'Mac users: must be skip in order to run the code.'};
            app.SkipCheckBox.Text = 'Skip synchronization test ⚠';
            app.SkipCheckBox.Position = [9 91 172 22];

            % Create StimulationWindowSwitch
            app.StimulationWindowSwitch = uiswitch(app.ActivatestimulationwindowPanel, 'rocker');
            app.StimulationWindowSwitch.Orientation = 'horizontal';
            app.StimulationWindowSwitch.ValueChangedFcn = createCallbackFcn(app, @StimulationWindowSwitchValueChanged, true);
            app.StimulationWindowSwitch.Position = [51 62 45 20];

            % Create WindowLamp
            app.WindowLamp = uilamp(app.ActivatestimulationwindowPanel);
            app.WindowLamp.Position = [154 39 45 45];
            app.WindowLamp.Color = [0.651 0.651 0.651];

            % Create SelectscreenLabel
            app.SelectscreenLabel = uilabel(app.ActivatestimulationwindowPanel);
            app.SelectscreenLabel.Position = [8 120 82 22];
            app.SelectscreenLabel.Text = 'Select screen:';

            % Create DefaultscreenDropDownLabel
            app.DefaultscreenDropDownLabel = uilabel(app.ActivatestimulationwindowPanel);
            app.DefaultscreenDropDownLabel.Enable = 'off';
            app.DefaultscreenDropDownLabel.Position = [8 10 86 22];
            app.DefaultscreenDropDownLabel.Text = 'Default screen:';

            % Create DefaultscreenDropDown
            app.DefaultscreenDropDown = uidropdown(app.ActivatestimulationwindowPanel);
            app.DefaultscreenDropDown.Items = {'0% - black', '10% - gray', '20% - gray', '30% - gray', '40% - gray', '50% - gray', '60% - gray', '70% - gray', '80% - gray', '90% - gray', '100% - white', '0º - gratings', '45º - gratings', '90º - gratings', '135º - gratings'};
            app.DefaultscreenDropDown.DropDownOpeningFcn = createCallbackFcn(app, @DefaultscreenDropDownOpening, true);
            app.DefaultscreenDropDown.ValueChangedFcn = createCallbackFcn(app, @DefaultscreenDropDownValueChanged, true);
            app.DefaultscreenDropDown.Enable = 'off';
            app.DefaultscreenDropDown.Position = [103 10 104 22];
            app.DefaultscreenDropDown.Value = '50% - gray';

            % Create ScreenSizeLabel
            app.ScreenSizeLabel = uilabel(app.ActivatestimulationwindowPanel);
            app.ScreenSizeLabel.HorizontalAlignment = 'center';
            app.ScreenSizeLabel.FontColor = [0.651 0.651 0.651];
            app.ScreenSizeLabel.Position = [2 38 143 22];
            app.ScreenSizeLabel.Text = 'screen size: ----x----';

            % Create GratingsconfigurationPanel
            app.GratingsconfigurationPanel = uipanel(app.MouSeeUIFigure);
            app.GratingsconfigurationPanel.AutoResizeChildren = 'off';
            app.GratingsconfigurationPanel.Title = 'Gratings configuration';
            app.GratingsconfigurationPanel.Position = [8 137 225 220];

            % Create DirectionsDropDownLabel
            app.DirectionsDropDownLabel = uilabel(app.GratingsconfigurationPanel);
            app.DirectionsDropDownLabel.Position = [7 167 63 22];
            app.DirectionsDropDownLabel.Text = 'Directions:';

            % Create DirectionsDropDown
            app.DirectionsDropDown = uidropdown(app.GratingsconfigurationPanel);
            app.DirectionsDropDown.Items = {'→↗↑↖←↙↓↘', '→↗↑↖', '←↙↓↘', '→↑←↓', '→↑', '←↓', '↗↖', '↙↘', '→', '↗', '↑', '↖', '←', '↙', '↓', '↘', '↻→↗↑↖', '↻→↑', '↻↗↖', '↻→', '↻↗', '↻↑', '↻↖', '↺→↗↑↖', '↺→↑', '↺↗↖', '↺→', '↺↗', '↺↑', '↺↖'};
            app.DirectionsDropDown.DropDownOpeningFcn = createCallbackFcn(app, @DirectionsDropDownOpening, true);
            app.DirectionsDropDown.ValueChangedFcn = createCallbackFcn(app, @DirectionsDropDownValueChanged, true);
            app.DirectionsDropDown.Position = [77 167 129 22];
            app.DirectionsDropDown.Value = '→↗↑↖←↙↓↘';

            % Create SizeEditField
            app.SizeEditField = uieditfield(app.GratingsconfigurationPanel, 'numeric');
            app.SizeEditField.Limits = [1 4000];
            app.SizeEditField.RoundFractionalValues = 'on';
            app.SizeEditField.ValueChangedFcn = createCallbackFcn(app, @SizeEditFieldValueChanged, true);
            app.SizeEditField.Position = [133 140 73 22];
            app.SizeEditField.Value = 200;

            % Create DriftingCheckBox
            app.DriftingCheckBox = uicheckbox(app.GratingsconfigurationPanel);
            app.DriftingCheckBox.ValueChangedFcn = createCallbackFcn(app, @DriftingCheckBoxValueChanged, true);
            app.DriftingCheckBox.Text = 'Drifting';
            app.DriftingCheckBox.Position = [7 113 78 22];
            app.DriftingCheckBox.Value = true;

            % Create FrequencyHzEditField
            app.FrequencyHzEditField = uieditfield(app.GratingsconfigurationPanel, 'numeric');
            app.FrequencyHzEditField.Limits = [0.001 Inf];
            app.FrequencyHzEditField.ValueChangedFcn = createCallbackFcn(app, @FrequencyHzEditFieldValueChanged, true);
            app.FrequencyHzEditField.Position = [133 86 73 22];
            app.FrequencyHzEditField.Value = 2;

            % Create RandomCheckBox
            app.RandomCheckBox = uicheckbox(app.GratingsconfigurationPanel);
            app.RandomCheckBox.ValueChangedFcn = createCallbackFcn(app, @RandomCheckBoxValueChanged, true);
            app.RandomCheckBox.Text = 'Random sequence';
            app.RandomCheckBox.Position = [7 33 189 22];
            app.RandomCheckBox.Value = true;

            % Create GratingssizepixelsLabel
            app.GratingssizepixelsLabel = uilabel(app.GratingsconfigurationPanel);
            app.GratingssizepixelsLabel.Position = [7 140 119 22];
            app.GratingssizepixelsLabel.Text = 'Gratings size (pixels):';

            % Create FrequencyHzEditFieldLabel
            app.FrequencyHzEditFieldLabel = uilabel(app.GratingsconfigurationPanel);
            app.FrequencyHzEditFieldLabel.Position = [23 86 103 22];
            app.FrequencyHzEditFieldLabel.Text = 'Frequency (Hz):';

            % Create SinusoidalCheckBox
            app.SinusoidalCheckBox = uicheckbox(app.GratingsconfigurationPanel);
            app.SinusoidalCheckBox.ValueChangedFcn = createCallbackFcn(app, @SinusoidalCheckBoxValueChanged, true);
            app.SinusoidalCheckBox.Text = 'Sinusoidal';
            app.SinusoidalCheckBox.Position = [7 59 78 22];
            app.SinusoidalCheckBox.Value = true;

            % Create OutputvoltageDropDownLabel
            app.OutputvoltageDropDownLabel = uilabel(app.GratingsconfigurationPanel);
            app.OutputvoltageDropDownLabel.Position = [8 7 88 22];
            app.OutputvoltageDropDownLabel.Text = 'Output voltage:';

            % Create OutputDropDown
            app.OutputDropDown = uidropdown(app.GratingsconfigurationPanel);
            app.OutputDropDown.Items = {'None', 'Dev1 - ao0', 'Dev1 - ao1', 'Dev1 - ao2', 'Dev1 - ao3', 'Dev2 - ao0', 'Dev2 - ao1', 'Dev2 - ao2', 'Dev2 - ao3'};
            app.OutputDropDown.ValueChangedFcn = createCallbackFcn(app, @OutputDropDownValueChanged, true);
            app.OutputDropDown.Position = [102 7 105 22];
            app.OutputDropDown.Value = 'None';

            % Create DurationPanel
            app.DurationPanel = uipanel(app.MouSeeUIFigure);
            app.DurationPanel.AutoResizeChildren = 'off';
            app.DurationPanel.Title = 'Duration';
            app.DurationPanel.Position = [8 10 224 114];

            % Create StimulussLabel
            app.StimulussLabel = uilabel(app.DurationPanel);
            app.StimulussLabel.Position = [8 63 71 22];
            app.StimulussLabel.Text = 'Stimulus (s):';

            % Create GraysLabel
            app.GraysLabel = uilabel(app.DurationPanel);
            app.GraysLabel.Position = [8 35 93 22];
            app.GraysLabel.Text = 'Interstimulus (s):';

            % Create RepetitionsEditFieldLabel
            app.RepetitionsEditFieldLabel = uilabel(app.DurationPanel);
            app.RepetitionsEditFieldLabel.Position = [8 8 70 22];
            app.RepetitionsEditFieldLabel.Text = 'Repetitions:';

            % Create Label
            app.Label = uilabel(app.DurationPanel);
            app.Label.HorizontalAlignment = 'right';
            app.Label.Position = [123 35 25 22];
            app.Label.Text = '±';

            % Create StimulusEditField
            app.StimulusEditField = uieditfield(app.DurationPanel, 'numeric');
            app.StimulusEditField.Limits = [0.02 100];
            app.StimulusEditField.ValueChangedFcn = createCallbackFcn(app, @StimulusEditFieldValueChanged, true);
            app.StimulusEditField.Position = [98 63 41 22];
            app.StimulusEditField.Value = 2;

            % Create GrayEditField
            app.GrayEditField = uieditfield(app.DurationPanel, 'numeric');
            app.GrayEditField.Limits = [0 Inf];
            app.GrayEditField.ValueChangedFcn = createCallbackFcn(app, @GrayEditFieldValueChanged, true);
            app.GrayEditField.Position = [98 35 41 22];
            app.GrayEditField.Value = 3;

            % Create GrayRndSpinner
            app.GrayRndSpinner = uispinner(app.DurationPanel);
            app.GrayRndSpinner.Step = 0.1;
            app.GrayRndSpinner.Limits = [0 2];
            app.GrayRndSpinner.ValueChangedFcn = createCallbackFcn(app, @GrayRndSpinnerValueChanged, true);
            app.GrayRndSpinner.Position = [151 35 57 22];

            % Create RepetitionsEditField
            app.RepetitionsEditField = uieditfield(app.DurationPanel, 'numeric');
            app.RepetitionsEditField.Limits = [1 1000];
            app.RepetitionsEditField.RoundFractionalValues = 'on';
            app.RepetitionsEditField.ValueChangedFcn = createCallbackFcn(app, @RepetitionsEditFieldValueChanged, true);
            app.RepetitionsEditField.Position = [98 8 41 22];
            app.RepetitionsEditField.Value = 10;

            % Create StimuliPanel
            app.StimuliPanel = uipanel(app.MouSeeUIFigure);
            app.StimuliPanel.Title = 'Stimuli';
            app.StimuliPanel.Position = [242 10 260 525];

            % Create DirectionsLabel
            app.DirectionsLabel = uilabel(app.StimuliPanel);
            app.DirectionsLabel.HorizontalAlignment = 'center';
            app.DirectionsLabel.FontSize = 24;
            app.DirectionsLabel.Position = [43 464 173 33];
            app.DirectionsLabel.Text = '→↗↑↖←↙↓↘';

            % Create TimeLabel
            app.TimeLabel = uilabel(app.StimuliPanel);
            app.TimeLabel.HorizontalAlignment = 'center';
            app.TimeLabel.FontSize = 20;
            app.TimeLabel.Position = [19 403 221 48];
            app.TimeLabel.Text = 'Total time:';

            % Create PreviewImage
            app.PreviewImage = uiimage(app.StimuliPanel);
            app.PreviewImage.Tooltip = {''};
            app.PreviewImage.Position = [18 174 225 225];

            % Create DirectionLabel
            app.DirectionLabel = uilabel(app.StimuliPanel);
            app.DirectionLabel.HorizontalAlignment = 'center';
            app.DirectionLabel.FontSize = 48;
            app.DirectionLabel.FontColor = [0.851 0.1294 0.1294];
            app.DirectionLabel.Position = [19 210 219 152];
            app.DirectionLabel.Text = '';

            % Create TrialLabel
            app.TrialLabel = uilabel(app.StimuliPanel);
            app.TrialLabel.HorizontalAlignment = 'center';
            app.TrialLabel.FontSize = 20;
            app.TrialLabel.FontColor = [0.2824 0.749 0.1882];
            app.TrialLabel.Position = [17 127 221 48];
            app.TrialLabel.Text = '';

            % Create GenerategratingsButton
            app.GenerategratingsButton = uibutton(app.StimuliPanel, 'state');
            app.GenerategratingsButton.ValueChangedFcn = createCallbackFcn(app, @GenerategratingsButtonValueChanged, true);
            app.GenerategratingsButton.Enable = 'off';
            app.GenerategratingsButton.Text = 'Generate gratings';
            app.GenerategratingsButton.FontSize = 18;
            app.GenerategratingsButton.Position = [14 82 226 37];

            % Create RunButton
            app.RunButton = uibutton(app.StimuliPanel, 'state');
            app.RunButton.ValueChangedFcn = createCallbackFcn(app, @RunButtonPushed, true);
            app.RunButton.Enable = 'off';
            app.RunButton.Text = 'Run';
            app.RunButton.FontSize = 24;
            app.RunButton.Position = [14 8 226 71];

            % Show the figure after all components are created
            app.MouSeeUIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = MouSee

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.MouSeeUIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.MouSeeUIFigure)
        end
    end
end