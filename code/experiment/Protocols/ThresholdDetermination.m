%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ### ThresholdDetermination
% 
% Protocol for identifying the hearing threshold level over a range of frequencies
% 
% ```matlab
%   ThresholdDetermination(cal_dB) 
%   ThresholdDetermination(cal_dB, 'config', 'path2config')
%   ThresholdDetermination(cal_dB, 'verbose', false, 'fig', gcf, 'del_fig', false
% ```
% 
% **ARGUMENTS:**
% 
%   - cal_dB, `1x1` scalar, the externally measured decibel level of a 
%       1kHz tone at the system volume that will be used during the
%       protocol.
%   - config_file, `character vector`, name-value, default: `''`
%       Path to the desired config file.
%       GUI will open for the user to select a config if no path is supplied.
%   - verbose, `logical`, name-value, default: `true`,
%       Flag to show informational messages.
%   - del_fig, `logical`, name-value, default: `true`,
%       Flag to delete figure at the end of the experiment.
%   - fig, `matlab.ui.Figure`, name-value.
%       Handle to figure window in which to display instructions
%       Function will create a new figure if none is supplied.
% 
% **OUTPUTS:**
% 
%   - Two `CSV` files: `threshold_dBs`, `threshold_tones` saved to config.data_dir.

function ThresholdDetermination(cal_dB, options)
    arguments
        cal_dB (1,1) {mustBeReal}
        options.fig matlab.ui.Figure
        options.config_file char = []
        options.del_fig logical = true
        options.verbose (1,1) {mustBeNumericOrLogical} = true
    end

    % Get the datetime and posix time
    % for the start of the experiment
    this_datetime = datetime('now', 'Timezone', 'local');
    posix_time = num2str(floor(posixtime(this_datetime)));

    % Is a config file provided?
    %   If so, read it.
    %   If not, open a GUI dialog window to find it.
    [config, config_path] = parse_config(options.config_file);

    % Hash the config struct to get a unique string representation
    % Get the hash before modifying the config at all
    config_hash = get_hash(config);

    % Get the hash prefix for file naming
    hash_prefix = [config_hash, '_', posix_time];

    % Try to create the data directory if it doesn't exist
    mkdir(config.data_dir);

    % Add config file to data directory
    try
        copyfile(config_path, config.data_dir);
    catch
        warning('Config file already exists in data directory');
    end

    %% Setup

    %%% Important variables
    Fs = 44100;
    init_dB = 60;
    dB_min = -100-cal_dB;
    dB_max = 100-cal_dB;
    sld_incr = 1/200;
    duration = 1; % seconds to play the tone for

    % Define dB value so it can be referenced in slider creation
    curr_dB = init_dB-cal_dB;
    
    %%% Build test frequencies
    test_freqs = gen_octaves(config.min_tone_freq,config.max_tone_freq,2,'semitone');

    % config.max_tone_freq might not always be in test_freqs, but
    % config.min_tone_freq will (start from min freq and double)
    if ~ismember(config.max_tone_freq,test_freqs)
        test_freqs(end+1) = config.max_tone_freq;
    end

    %%% Create and open data file
    file_hash = [hash_prefix '_', rand_str()];
    filename_dB  = fullfile(config.data_dir, ['threshold_dBs_', file_hash, '.csv']);
    fid_dB = fopen(filename_dB,'w');

    % Save test frequencies 
    % Double each b/c protocol is 60dB -> jn, jn+10dB -> jn
    filename_testfreqs = fullfile(config.data_dir, ['threshold_tones_', file_hash, '.csv']);
    writematrix(repelem(test_freqs,2,1), filename_testfreqs);

    % Load error and end screens
    project_dir = pathlib.strip(mfilename('fullpath'), 3);
    ScreenError = imread(fullfile(project_dir, 'experiment', 'fixationscreen', 'SlideError.png'));
    ScreenEnd = imread(fullfile(project_dir, 'experiment', 'fixationscreen', 'SlideExpEnd.png'));

    %% Show figure

    % Useful vars
    screenSize = get(0, 'ScreenSize');
    screenWidth = screenSize(3);
    screenHeight = screenSize(4);

    % Open full screen figure if none provided or the provided was deleted
    if ~isfield(options, 'fig') || ~ishandle(options.fig)
        hFig = figure('Numbertitle','off',...
            'Position', [0 0 screenWidth screenHeight],...
            'Color',[0.5 0.5 0.5],...
            'Toolbar','none', ...
            'MenuBar','none');
    else
        hFig = options.fig;
    end
    hFig.CloseRequestFcn = {@closeRequest hFig};
    clf(hFig)

    %% Fig contents
    sldWidth = 500;
    sldHeight = 20;
    sld = uicontrol(hFig, 'Style', 'slider', ...
        'Position', [(screenWidth/2)-(sldWidth/2), ...
                    (screenHeight/2)-sldHeight, ...
                    sldWidth, sldHeight], ...
        'min', dB_min, 'max', dB_max, ...
        'SliderStep', [sld_incr, sld_incr], ...
        'Value', curr_dB, 'Callback', @getValue);

    instrWidth = 300;
    instrHeight = 100;
    instr_txt = uicontrol(hFig, 'Style', 'text', 'String', ...
        ['Adjust the volume of the ' ...
        'audio via the slider until it is "just audible". Press "Play Tone" ' ...
        'to hear the adjusted audio. Press "Save Choice" when satisfied.'], ...
        'Position', [(screenWidth/2)-(instrWidth/2), ...
                    (2*screenHeight/3)-instrHeight, ...
                    instrWidth, instrHeight]);

    btnWidth = 80;
    btnHeight = 20;
    uicontrol(hFig,'Style','pushbutton', ...
        'position', [(screenWidth/2)-(sldWidth/4)-(btnWidth/2), ...
                    (screenHeight/2)-sldHeight-(2*btnHeight), ...
                    btnWidth, btnHeight], ...
        'String', 'Play Tone', 'Callback', @playTone);

    uicontrol(hFig,'Style','pushbutton', ...
        'position', [(screenWidth/2)+(sldWidth/4)-(btnWidth/2), ...
                    (screenHeight/2)-sldHeight-(2*btnHeight), ...
                    btnWidth, btnHeight], ...
        'String', 'Save Choice', 'Callback', {@saveChoice hFig});

    lblWidth = 60;
    lblHeight = 20;
    uicontrol(hFig, 'Style', 'text', 'String', 'Min', ...
        'Position', [(screenWidth/2)-(sldWidth/2)-lblWidth-10, ...
                    (screenHeight/2)-sldHeight-lblHeight, ...
                    lblWidth, lblHeight]);

    uicontrol(hFig, 'Style', 'text', 'String', 'Max', ...
        'Position', [(screenWidth/2)+(sldWidth/2)+10, ...
                    (screenHeight/2)-sldHeight-lblHeight, ...
                    lblWidth, lblHeight]);


    %% Run protocol
    for ii = 1:length(test_freqs)
        curr_tone = pure_tone(test_freqs(ii),duration,Fs);

        % Reset slider value to 60dB
        curr_dB = init_dB-cal_dB;
        sld.Value = curr_dB;

        instr_txt.String = ['Adjust the volume of the ' ...
            'audio via the slider until it is "just audible". Press "Play Tone" ' ...
            'to hear the adjusted audio. Press "Save Choice" when satisfied.'];

        uiwait(hFig)

        % Play tone again at "just noticable" + 10 dB
        curr_dB = curr_dB + 10;
        sld.Value = curr_dB;

        % Update instructions
        instr_txt.String = ['Please repeat the same steps as before:' ...
            'Adjust the volume of the ' ...
            'audio via the slider until it is "just audible". Press "Play Tone" ' ...
            'to hear the adjusted audio. Press "Save Choice" when satisfied.'];

        uiwait(hFig)
    end

    fclose(fid_dB);

    % Show completion screen 
    disp_fullscreen(ScreenEnd, hFig);
    k = waitforkeypress();
    if k < 0
        corelib.verb(options.verbose, 'INFO PitchMatch', 'Exiting...')
        return
    end

    if options.del_fig
        delete(hFig)
    end
    
    %% Callback Functions
    function getValue(~,~)
        curr_dB = sld.Value;
    end % getValue

    function playTone(~, ~)
        % Convert dB to gain and play sound
        gain = 10^(curr_dB/20);
        tone_to_play = gain*curr_tone;
        if min(tone_to_play) < -1 || max(tone_to_play) > 1
            disp_fullscreen(ScreenError, hFig);
            warning('Sound is clipping. Recalibrate dB level.')
            keyboard
            return
        end
        sound(tone_to_play,Fs)
    end % playTone

    function saveChoice(~,~,hFig)
        % Save the just noticable value
        jn_dB = curr_dB+cal_dB;
        jn_amp = 10^(jn_dB/20);
        fprintf(fid_dB, [num2str(jn_dB), ',', num2str(jn_amp), '\n']);
        uiresume(hFig)
    end
end % ThresholdDetermination

function closeRequest(~,~,hFig)
    ButtonName = questdlg('Are you sure you want to end the experiment?',...
        'Confirm', ...
        'Yes', 'No', 'Yes');
    switch ButtonName
        case 'Yes'
            delete(hFig);
        case 'No'
            return
    end
end % closeRequest
