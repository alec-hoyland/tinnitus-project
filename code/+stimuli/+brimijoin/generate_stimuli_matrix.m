function [stimuli_matrix, Fs, binned_repr_matrix] = generate_stimuli_matrix(options)
    % Generate a matrix of stimuli,
    % where the matrix is of size nfft x n_trials.
    
    arguments
        options.min_freq (1,1) {mustBeNumeric} = 100
        options.max_freq (1,1) {mustBeNumeric} = 22e3
        options.n_bins (1,1) {mustBeNumeric} = 100
        options.bin_duration (1,1) {mustBeNumeric} = 0.4
        % options.prob_f (1,1) {mustBeNumeric} = 0.4
        options.n_trials (1,1) {mustBeNumeric} = 80
        options.amplitude_values {mustBeNumeric} = linspace(-20, 0, 6)
    end

    % generate first stimulus
    binned_repr_matrix = zeros(options.n_bins, options.n_trials);
    [stim1, Fs, ~, binned_repr_matrix(:, 1)] = stimuli.brimijoin.generate_stimuli(...
        'min_freq', options.min_freq, ...
        'max_freq', options.max_freq, ...
        'n_bins', options.n_bins, ...
        'bin_duration', options.bin_duration, ...
        'amplitude_values', options.amplitude_values);

    % instantiate stimuli matrix
    stimuli_matrix = zeros(length(stim1), options.n_trials);
    stimuli_matrix(:, 1) = stim1;
    for ii = 2:options.n_trials
        [stimuli_matrix(:, ii), ~, ~, binned_repr_matrix(:, ii)] = stimuli.brimijoin.generate_stimuli(...
            'min_freq', options.min_freq, ...
            'max_freq', options.max_freq, ...
            'n_bins', options.n_bins, ...
            'bin_duration', options.bin_duration, ...
            'amplitude_values', options.amplitude_values);
    end
