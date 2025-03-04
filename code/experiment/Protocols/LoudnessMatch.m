%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ### LoudnessMatch
% 
% Protocol for matching perceived loudness of tones to tinnitus level.
% 
% ```matlab
%   LoudnessMatch(cal_dB) 
%   LoudnessMatch(cal_dB, 'config', 'path2config')
%   LoudnessMatch(cal_dB, 'verbose', false, 'fig', gcf, 'del_fig', false)
% ```
% 
% **ARGUMENTS:**
% 
%   - cal_dB, `1x1` scalar, the externally measured decibel level of a 
%       1kHz tone at the system volume that will be used during the
%       protocol.
%   - max_dB_allowed_, `1x1` scalar, name-value, default: `95`.
%       The maximum dB value at which tones can be played. 
%       `cal_dB` must be greater than this value. Not intended to be changed from 95.
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
%   - Three `CSV` files: `loudness_dBs`, `loudness_noise_dB`, `loudness_tones`
%       saved to config.data_dir.

function LoudnessMatch(cal_dB, options)
    arguments
        cal_dB (1,1) {mustBeReal}
        options.max_dB_allowed_ (1,1) {mustBeReal} = 95
        options.fig matlab.ui.Figure
        options.config_file char = []
        options.del_fig logical = true
        options.verbose (1,1) {mustBeNumericOrLogical} = true
    end

    assert(cal_dB > options.max_dB_allowed_, ...
        ['cal_dB must be greater than ', num2str(options.max_dB_allowed_), ' dB.'])

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
    Fs = 44100;
    err = false; % Shared error flag variable
    noise_trial = false; % Flag for if trial was noise
    duration = 2; % seconds to play the tone for
    tone_played = false;

    %%% Slider values
    dB_min = -options.max_dB_allowed_-cal_dB;
    dB_max = options.max_dB_allowed_-cal_dB;


    % Load just noticable dBs and test freqs from threshold data
    [jn_vals, ~, test_freqs] = collect_data_thresh_or_loud('threshold','config',config);

    if isempty(jn_vals) || isempty(test_freqs)
        corelib.verb(options.verbose,'INFO: LoudnessMatch','Generating test frequencies and starting at 60dB')
        test_freqs = gen_octaves(config.min_tone_freq,config.max_tone_freq,2,'semitone');
        init_dBs = 60*ones(length(test_freqs),1);
    else
        init_dBs = jn_vals + 10;
    end

    % config.max_tone_freq might not always be in test_freqs, but
    % config.min_tone_freq will (start from min freq and double)
    if ~ismember(round(config.max_tone_freq),round(test_freqs))
        test_freqs(end+1) = config.max_tone_freq;
    end

    % Subtract calibraiton dB so that sounds are presented at correct level
    init_dBs = init_dBs - cal_dB;

    % Make sure nothing went above max playable level
    init_dBs(init_dBs > dB_max) = dB_max;

    % Set init slider position
    curr_dB = init_dBs(1);

    %%% Create and open data file
    file_hash = [hash_prefix '_', rand_str()];
    filename_dB  = fullfile(config.data_dir, ['loudness_dBs_', file_hash, '.csv']);
    filename_noise_dB  = fullfile(config.data_dir, ['loudness_noise_dB_', file_hash, '.csv']);
    fid_dB = fopen(filename_dB,'w');

    % Save test frequencies 
    % Double each b/c protocol is jndB -> jn, jn+10dB -> jn
    filename_testfreqs = fullfile(config.data_dir, ['loudness_tones_', file_hash, '.csv']);
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
        sldWidth sldHeight], ...
        'min', dB_min, 'max', dB_max, ...
        'SliderStep', [1/150 1/150], ...
        'Value', curr_dB, 'Callback', @getValue);

    instrWidth = 500;
    instrHeight = 100;
    uicontrol(hFig, 'Style', 'text', 'String', ...
        ['Adjust the volume of the audio via the slider ' ...
        'until it matches the loudness of your tinnitus. ' ...
        'Press "Play Tone" to hear the adjusted audio. ' ...
        'Press "Save Choice" when satisfied. ' ...
        'If you cannot hear the sound with the volume at "Max", check the "Can''t hear" box.'], ...
        'Position', [(screenWidth/2)-(instrWidth/2), ...
        (2*screenHeight/3)-instrHeight, ...
        instrWidth, instrHeight], ...
        'FontSize', 16, 'HorizontalAlignment','left');

    %%%%% Buttons
    btnWidthReg = 80;
    btnWidthLong = 120;
    btnHeight = 20;
    
    play_btn = uicontrol(hFig,'Style','pushbutton', ...
        'position', [(screenWidth/2)-(sldWidth/4)-(btnWidthReg/2), ...
                    sld.Position(2)-(2*btnHeight), ...
                    btnWidthReg, btnHeight], ...
        'String', 'Play Tone', 'Callback', @playTone);

    save_btn_pos_1 = [(screenWidth/2)+(sldWidth/4)-(btnWidthLong/2), ...
                    sld.Position(2)-(2*btnHeight), ...
                    btnWidthLong, btnHeight];

    save_btn_pos_2 = [(screenWidth/2)+(sldWidth/4)-(btnWidthReg/2), ...
                    save_btn_pos_1(2), btnWidthReg, save_btn_pos_1(4)];

    save_btn = uicontrol(hFig,'Style','pushbutton', ...
        'position', save_btn_pos_1, ...
        'String', 'Play sound to activate', 'Enable', 'off', ...
        'Callback', {@saveChoice hFig});

    %%%%% Checkbox
    bxWidth = 80;
    bxHeight = 20;
    checkbox = uicontrol(hFig,'Style','checkbox','String','Can''t hear',...
        'Position',[(screenWidth/2)+(sldWidth/2)+10, sld.Position(2)+(bxHeight/4), ...
        bxWidth, bxHeight], 'Enable', 'off', 'Callback', @cantHear);


    %% Run protocol
    for ii = 1:length(test_freqs)+1
        %%%%% Setup sound
        if ii == length(test_freqs)+1
            noise = white_noise(duration,Fs);
            curr_tone = noise / rms(noise);
            win = tukeywin(length(curr_tone),0.08);
            curr_init_dB = 30-cal_dB;
            noise_trial = true;
        else
            curr_tone = pure_tone(test_freqs(ii),duration,Fs);
            curr_init_dB = init_dBs(ii);
        end

        % Length and window is same every time so only compute once
        if ii == 1
            win = tukeywin(length(curr_tone),0.08);
        end

        % Apply tukey window to tone
        curr_tone = win .* curr_tone;

        % Reset screen
        resetScreen();
        uiwait(hFig)
        if err
            return
        end

        % Repeat
        resetScreen();
        uiwait(hFig)
        if err
            return
        end
    end

    fclose(fid_dB);

    % Show completion screen
    disp_fullscreen(ScreenEnd, hFig);
    % Use instead of waitforkeypress b/c this allows for mouse click. 
    % When run from RunAllExp, button clicks don't register on this function in particular
    % this prevents awkwardness having to click the figure then press a button.
    waitforbuttonpress 

    if options.del_fig
        delete(hFig)
    end
    
    %% Callback Functions
    function getValue(~,~)
        curr_dB = sld.Value;
        if curr_dB == dB_max && tone_played
            set(checkbox, 'Enable', 'on')
        else
            set(checkbox, 'Enable', 'off')
        end
    end % getValue

    function playTone(~, ~)
        % Stop the sound
        clear sound
        % Convert dB to gain and play sound
        gain = 10^(curr_dB/20);
        tone_to_play = gain*curr_tone;
        if min(tone_to_play) < -1 || max(tone_to_play) > 1
            disp_fullscreen(ScreenError, hFig);
            warning('Sound is clipping. Recalibrate dB level.')
            err = true;
            uiresume(hFig)
            return
        end
        sound(tone_to_play,Fs,24)

        tone_played = true;

        % Activate save button
        if strcmp(save_btn.Enable, 'off')
            set(save_btn, 'Enable', 'on', ...
                'String', 'Save Choice', ...
                'Position',save_btn_pos_2)
        end

        % Activate can't hear (needed if tone set to max right away).
        if curr_dB == dB_max && tone_played
            set(checkbox, 'Enable', 'on')
        else
            set(checkbox, 'Enable', 'off')
        end
    end % playTone

    function saveChoice(~,~,hFig)
        % Stop the sound
        clear sound
        % Save the just noticable value
        jn_dB = curr_dB+cal_dB;
        jn_amp = 10^(jn_dB/20);
        if noise_trial
            writematrix([jn_dB, jn_amp], filename_noise_dB);
        else
            fprintf(fid_dB, [num2str(jn_dB), ',', num2str(jn_amp), '\n']);
        end
        uiresume(hFig)
    end

    function cantHear(~,~)
        % Value = 1 if checked, 0 if not
        if checkbox.Value
            set(sld,'Enable','off');
            set(play_btn,'Enable','off');
            curr_dB = NaN;
        else
            set(sld,'Enable','on');
            set(play_btn,'Enable','on');
            curr_dB = sld.Value;
        end

        if strcmp(save_btn.Enable, 'off')
            set(save_btn, 'Enable', 'on', ...
                'String', 'Save Choice', ...
                'Position',save_btn_pos_2)
        end
    end

    function resetScreen()
        set(save_btn, 'Enable', 'off', ...
            'String', 'Play sound to activate', ...
            'Position', save_btn_pos_1);
        set(play_btn,'Enable','on');
        set(sld,'Enable','on')
        checkbox.Value = 0;
        set(checkbox, 'Enable', 'off')
        curr_dB = curr_init_dB;
        sld.Value = curr_dB;
        tone_played = false;
    end
end

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
