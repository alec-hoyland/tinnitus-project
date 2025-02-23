% ### crossval_rc_adjusted
%
% Generate the cross-validated response predictions for a given
% config file using the upsampled and peak sharpened representation in bin form.
% Config file must have an associated survey with mult and binrange values.
% Reconstruction methods can be the classical reverse correlation model
% y = sign(Psi * x) or y = sign(Psi * x + thresh).
%
% ```matlab
%   [pred_resps, true_resps, pred_resps_train, true_resps_train] = crossval_rc_adjusted(folds, thresh, 'config', config, 'data_dir', data_dir)
% ```
%
% **ARGUMENTS:**
%
%   - folds: `scalar` positive integer, must be greater than 3,
%       representing the number of cross validation folds to complete.
%       Data will be partitioned into `1/folds` for `test` and `dev` sets
%       and the remaining for the `train` set.
%   - thresh: `1 x p` numerical vector or `scalar`,
%       representing the threshold value in the estimate to response
%       conversion: `sign(X*b + threshold)`.
%       If there are multiple values,
%       it will be optimized in the development section.
%   - config: `struct`, name-value, deafult: `[]`
%       config struct from which to find responses and stimuli
%   - data_dir: `char`, name-value, deafult: `''`
%       the path to directory in which the data corresponding to the
%       config structis stored.
%   - ridge: `bool`, name-value, default: `false`,
%       flag to use ridge regression instead of standard linear regression
%       for reconstruction.
%   - mean_zero: `bool`, name-value, default: `false`,
%       flag to set the mean of the stimuli to zero when computing the
%       reconstruction and both the mean of the stimuli and the
%       reconstruction to zero when generating the predictions.
%   - verbose: `bool`, name-value, default: `true`,
%       flag to print information messages.
%
% **OUTPUTS:**
%
%   - pred_resps: `n x 1` vector,
%       the predicted responses.
%   - true_resps: `n x 1` vector,
%       the original subject responses in the order corresponding
%       to the predicted responses, i.e., a shifted version of the
%       original response vector.
%   - pred_resps_train: `folds*(n-round(n/folds)) x 1` vector,
%       OR `folds*(2*(n-round(n/folds))) x 1` vector if dev is run.
%       the predicted responses on the training data.
%   - true_resps_train: `folds*(n-round(n/folds)) x 1` vector,
%       OR `folds*(2*(n-round(n/folds))) x 1` vector if dev is run.
%       the predicted responses on the training data.
%       the original subject responses in the order corresponding
%       to the predicted responses on the training data,

function [pred_resps, true_resps, pred_resps_train, true_resps_train] = crossval_rc_adjusted(folds, thresh, options)
    arguments
        folds (1,1) {mustBeInteger, mustBePositive}
        thresh (1,:) {mustBeReal}
        options.config struct = []
        options.data_dir char = ''
        options.ridge logical = false
        options.mean_zero logical = false
        options.verbose logical = true
    end

    [resps, stimuli_matrix] = collect_data('config', options.config, 'verbose', options.verbose, 'data_dir', options.data_dir);
    T_follow_up = collect_data_follow_up('config',options.config,'data_dir',options.data_dir,'verbose',options.verbose);

    mult = T_follow_up.mult(1);
    binrange = T_follow_up.binrange(1);

    stimgen = eval([char(options.config.stimuli_type), 'StimulusGeneration()']);
    stimgen = stimgen.from_config(options.config);

    % Useful
    n = length(resps);
    n_test = round(n / folds);
    test_inds = n-n_test+1:n;

    % Flag to optimize thresh values
    rundev = ~isscalar(thresh);

    if rundev
        train_inds = 1:n-(2*n_test);
        dev_inds = n-(2*n_test)+1:n-n_test;
    else
        train_inds = 1:n-n_test;
    end

    % Containers
    pred_resps = NaN(n,1);
    true_resps = NaN(n,1);
    pred_resps_train = NaN(length(train_inds)*folds,1);
    true_resps_train = NaN(length(train_inds)*folds,1);

    stimuli_matrix_interp = interp1(1:stimgen.n_bins,stimuli_matrix,linspace(1,stimgen.n_bins,256),'spline');

    for ii = 1:folds
        resps = circshift(resps, n_test);
        stimuli_matrix = circshift(stimuli_matrix, n_test, 2);
        stimuli_matrix_interp = circshift(stimuli_matrix_interp, n_test, 2);

        % Create reconstructions
        recon = gs(resps(train_inds), stimuli_matrix(:,train_inds)', 'ridge', options.ridge, ...
            'mean_zero', options.mean_zero);
        [~, ~, recon] = stimgen.binnedrepr2wav(recon, mult, binrange);

        if rundev
            preds_dev = rc(stimuli_matrix_interp(:,dev_inds)', recon, thresh, options.mean_zero);
            [~, bal_acc_dev, ~, ~] = get_accuracy_measures(resps(dev_inds), preds_dev);
            [~, thresh_ind] = max(bal_acc_dev);
        else
            thresh_ind = 1;
        end

        % fprintf(['thresh = ', num2str(thresh(thresh_ind)), '\n'])

        preds_test = rc(stimuli_matrix_interp(:,test_inds)', recon, thresh(thresh_ind), options.mean_zero);
        preds_train = rc(stimuli_matrix_interp(:,train_inds)', recon, thresh(thresh_ind), options.mean_zero);

        % Store
        filled = sum(~isnan(pred_resps));
        filled_train = sum(~isnan(pred_resps_train));

        pred_resps(filled+1:filled+length(preds_test)) = preds_test;
        true_resps(filled+1:filled+length(preds_test)) = resps(test_inds);
        pred_resps_train(filled_train+1:filled_train+length(preds_train)) = preds_train;
        true_resps_train(filled_train+1:filled_train+length(preds_train)) = resps(train_inds);
    end
end

function p = rc(stimuli, representation, thresh, mean_zero)
    arguments
        stimuli
        representation
        thresh (1,:)
        mean_zero logical = false
    end

    % Projection
    if mean_zero
        e = (stimuli - mean(stimuli,2)) * (representation(:) - mean(representation(:)));
    else
        e = stimuli * representation(:);
    end
    %     fprintf(['max(e) = ', num2str(max(e)), '\n'])
    %     fprintf(['min(e) = ', num2str(min(e)), '\n'])

    % Convert to response
    p = sign(e + thresh);
end
