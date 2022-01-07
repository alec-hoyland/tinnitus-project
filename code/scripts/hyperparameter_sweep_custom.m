%% Hyperparameter Sweep Custom Stimulus
% Evaluate hyperparameters of stimulus generation
% using the 'custom' stimulus paradigm.
% Evaluate hyperparameters over different
% target signals.

%% Preamble

RUN = true;
OVERWRITE = true;

% Set random number seed
rng(1234);

% Parameters
n_bins_filled_mean      = [1, 3, 10, 20, 30];
n_bins_filled_var       = [0.01, 1, 3, 10];
n_bins                  = 100;
data_dir                = '/home/alec/data/stimulus-hyperparameter-sweep';
verbose                 = true;

mkdir(data_dir)

% Target signals
sound_dir = '/home/alec/data/sounds/';
data_files = {
    'ATA_Tinnitus_Buzzing_Tone_1sec.wav', ...
    'ATA_Tinnitus_Electric_Tone_1sec.wav', ...
    'ATA_Tinnitus_Roaring_Tone_1sec.wav', ...
    'ATA_Tinnitus_Static_Tone_1sec.wav', ...
    'ATA_Tinnitus_Tea_Kettle_Tone_1sec.wav'
};
data_names = {
    'buzzing', ...
    'electric', ...
    'roaring', ...
    'static', ...
    'teakettle'
};
s = cell(5, 1);
f = cell(5, 1);
for ii = 1:length(data_files)
    [s{ii}, f{ii}] = wav2spect([sound_dir, data_files{ii}]);
end
target_signal = [s{:}];
f = [f{:}];

% Collect all combinations of parameters
param_sets = allcomb(n_bins_filled_mean, n_bins_filled_var, n_bins, 1:size(target_signal, 2));

% Remove combinations of parameters where the s.e.m. is > 1
param_sets((param_sets(:, 1) ./ param_sets(:, 2)) <= 1.5, :) = [];

% Remove combinations of parameters where the mean is too close to the maximum
param_sets(param_sets(:, 1) ./ param_sets(:, 3) >= 2/3, :) = []; 

% % Plot the parameter sets of n_bins_filled_mean vs n_bins_filled_var
% fig = new_figure();
% axis square
% scatter(param_sets(:, 1), param_sets(:, 2))
% xlabel('n bins filled mean')
% ylabel('n bins filled var')
% figlib.pretty()

%% Run experiment

params_to_do = [];

% Check if any parameter sets have been evaluated before.
% If so, skip them.
for ii = 1:size(param_sets, 1)
    file_ID =   ['n_bins_filled_mean=', num2str(param_sets(ii, 1)), '-', ...
                'n_bins_filled_var=', num2str(param_sets(ii, 2)), '-', ...
                'n_bins=', num2str(param_sets(ii, 3)), '-', ...
                'target_signal=', data_names{param_sets(ii, 4)}, ...
                '.csv'];
    param_string = file_ID(1:end-4);
    
    stimulus_filepath       = pathlib.join(data_dir, ['stimulus-', file_ID]);
    response_filepath       = pathlib.join(data_dir, ['response-', file_ID]);
    reconstruction_filepath = pathlib.join(data_dir, ['reconstruction-', file_ID]);

    if OVERWRITE || ~(isfile(stimulus_filepath) && isfile(response_filepath) && isfile(reconstruction_filepath))
        corelib.verb(verbose, 'INFO', ['Output files containing parameter set #', num2str(ii), ': "', param_string, '"', ...
                                       'unable to be acquired. Will reacquire.'])
        params_to_do(end+1, :) = param_sets(ii, :);
    else
        corelib.verb(verbose, 'INFO', ['Output files associated with parameter set #', num2str(ii), ': "', param_string, '" acquired.'])
    end
end

corelib.verb(verbose, 'INFO', [num2str(size(params_to_do, 1)), ' parameter sets to evaluate.'])

% Run all parameter sets identified in `params_to_do`
% progress_bar = ProgressBar(size(params_to_do, 1), 'IsParallel', true, 'Title', 'hyperparameter sweep');

if RUN
    % progress_bar.setup([], [], []);
    for ii = progress(1:size(params_to_do, 1))
    % parfor ii = 1:size(params_to_do, 1)
        try
            % Stimulus generation options
            options = struct;
            options.min_freq            = 100;
            options.max_freq            = 22e3;
            options.bin_duration        = size(target_signal, 1) / options.max_freq;
            options.n_trials            = 2e3;
            options.n_bins_filled_mean  = params_to_do(ii, 1);
            options.n_bins_filled_var   = params_to_do(ii, 2);
            options.n_bins              = params_to_do(ii, 3);
            options.amplitude_values    = linspace(-20, 0, 6);

            % Create stimulus generation object
            stimuli = Stimuli(options);

            % Generate the stimuli and response data
            % using a model of subject decision process
            [y, X] = stimuli.subject_selection_process(target_signal(:, params_to_do(ii, 4)), 'custom');

            % Get the reconstruction using compressed sensing (with basis)
            reconstruction = cs(y, X');
            % Get the reconstruction using compressed sensing (no basis)
            reconstruction_nb = cs_no_basis(y, X');

            % Save to directory
            file_ID =   ['n_bins_filled_mean=', num2str(param_sets(ii, 1)), '-', ...
                        'n_bins_filled_var=', num2str(param_sets(ii, 2)), '-', ...
                        'n_bins=', num2str(param_sets(ii, 3)), '-', ...
                        'target_signal=', data_names{param_sets(ii, 4)}, ...
                        '.csv'];
            csvwrite(pathlib.join(data_dir, ['stimulus-', file_ID]), X);
            csvwrite(pathlib.join(data_dir, ['response-', file_ID]), y);
            csvwrite(pathlib.join(data_dir, ['reconstruction-', file_ID]), reconstruction);
            csvwrite(pathlib.join(data_dir, ['reconstruction_nb', file_ID]), reconstruction_nb);
        catch
            corelib.verb(verbose, 'WARN', ['Failed to compute for parameter set: "', param_string, '".'])
        end

        % updateParallel([], pwd);
    end 
    % progress_bar.release();
end

% TODO

%% Evaluation

% Get reconstruction files
file_glob = pathlib.join(data_dir, 'reconstruction*n_bins_filled_mean=*-n_bins_filled_var=*-n_bins=*-target_signal=*');
file_glob_nb = pathlib.join(data_dir, 'reconstruction_nb*n_bins_filled_mean=*-n_bins_filled_var=*-n_bins=*-target_signal=*');
[reconstructions, reconstruction_files] = collect_reconstructions(file_glob);
[reconstructions_nb, reconstruction_files_nb] = collect_reconstructions(file_glob_nb);

% Get the parameter values from the files
pattern = 'n_bins_filled_mean=(\d*)-n_bins_filled_var=(\d*)-n_bins=(\d*)-target_signal=(\w*)';

params = collect_parameters(reconstruction_files, pattern, 4);
params_nb = collect_parameters(reconstruction_files_nb, pattern, 4);

% Combine parameters using different bases
basis = [true(size(params, 1), 1); false(size(params_nb, 1), 1)];

% Convert to a data table
T = cell2table(params, 'VariableNames', {'n_bins_filled_mean', 'n_bins_filled_var', 'n_bins', 'target_signal'});
T.n_bins_filled_mean = str2double(T.n_bins_filled_mean);
T.n_bins_filled_var = str2double(T.n_bins_filled_var);
T.n_bins = str2double(T.n_bins);

% Add basis as new column
T.basis = basis;

% Compute reconstruction quality (r^2)

% with basis
r2 = zeros(length(reconstruction_files), 1);
for ii = 1:length(reconstruction_files)
    r2(ii) = corr(target_signal(:, strcmp(data_names, T.target_signal{ii})), reconstructions(:, ii));
end

% no basis
r2_nb = zeros(length(reconstruction_files), 1);
for ii = 1:length(reconstruction_files)
    r2_nb(ii) = corr(target_signal(:, strcmp(data_names, T.target_signal{ii})), reconstructions_nb(:, ii));
end

T.r2 = r2 .^2;
T.r2_nb = r2_nb .^2;

T = sortrows(T, 'r2', 'descend');
T2 = varfun(@mean, T, 'InputVariables', 'r2', 'GroupingVariables', {'n_bins_filled_mean', 'n_bins_filled_var', 'n_bins'});
T2 = sortrows(T2, 'mean_r2', 'descend');
T3 = varfun(@mean, T, 'InputVariables', 'r2', 'GroupingVariables', {'target_signal', 'n_bins'});
T3 = sortrows(T3, 'mean_r2', 'descend');
T4 = T(T.n_bins == 100, :);


fig2 = new_figure();
heatmap(T, 'n_bins_filled_mean', 'n_bins_filled_var', 'ColorVariable', 'r2', 'FontSize', 36)
title('r^2 as a fcn of stimulus parameters')
figlib.pretty('FontSize', 36)

fig3 = new_figure();
boxchart(categorical(T.n_bins), T.r2)
xlabel('n bins')
ylabel('r^2')
title('number of bins vs. r^2')
figlib.pretty('FontSize', 36);

fig3a = new_figure();
boxchart(categorical(T2.n_bins), T2.mean_r2)
xlabel('n bins')
ylabel('r^2')
title('number of bins vs. mean r^2')
figlib.pretty('FontSize', 36);

fig4 = new_figure();
scatter(T2.n_bins, T2.mean_r2)
xlabel('n bins')
ylabel('r^2')
title('number of bins vs. mean r^2')
figlib.pretty('FontSize', 36);

fig5 = new_figure();
heatmap(T4, 'n_bins_filled_mean', 'n_bins_filled_var', 'ColorVariable', 'r2', 'FontSize', 36)
title('r^2 as a fcn of stimulus parameters (n bins = 300)')
figlib.pretty('FontSize', 36)