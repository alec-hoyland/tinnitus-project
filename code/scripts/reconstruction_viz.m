% ### reconstruction_viz
% Visualization for reconstructions
% Run ``pilot_reconstructions.m`` first to generate recons, etc.
% End of documentation

%% Plotting the bin-representation of the target signal vs. the reconstructions

alpha = 0.5;

% Regular experiments (no 2-AFC or resynth)

% Subset the data table
index_normal = ~(contains(T.experiment_name, 'resynth') | contains(T.experiment_name, '2afc'));
these_bins = table2array(unique(T(index_normal, "n_bins")));

for ii = 1:length(these_bins)
    this_T = T(index_normal & (T.n_bins == these_bins(ii, :)), :);

    plot_reconstructions(...
        this_T, ...
        binned_target_signal{this_T.ID(1)}, ...
        data_names, ...
        these_bins(ii), ...
        "lr", true, ...
        "cs", false, ...
        "figure", new_figure(), ...
        "alpha", alpha);

end
return
% Resynth experiments (no 2-AFC or regular)
fig2 = new_figure();

% Subset the data table
T2 = T(contains(T.experiment_name, 'resynth'), :);

% Get binned resynth target signal
% They are the reconstructions from the original signal
experiment_names = cellfun(@(x) strrep(x, '-resynth', ''), T2.experiment_name, 'UniformOutput', false);
T_filtered = T(contains(T.experiment_name, experiment_names), :);
binned_resynth_target_signal = [T_filtered.reconstructions_cs_1{:}];

fig2 = plot_reconstructions(...
    T2, ...
    binned_resynth_target_signal, ...
    data_names, ...
    "figure", fig2, ...
    "alpha", alpha, ...
    "resynth", true);


return
% 2-AFC experiments
fig3 = new_figure();

% Subset the data table
T2 = T(contains(T.experiment_name, '2afc'), :);

fig3 = plot_reconstructions(...
    "table", T2, ...
    "binned_target_signal", binned_target_signal, ...
    "data_names", data_names, ...
    "figure", fig3, ...
    "alpha", alpha, ...
    "two_afc", true);
return



return

% % Plotting the r^2 values vs. the trial numbers (using trial fractions)

% fig2 = new_figure();

% cmap = colormaps.linspecer(length(unique(T.subject_ID)));
% alpha = 1;

% subplot_labels = unique(T.target_signal_name)';

% for ii = length(subplot_labels):-1:1
%     ax(ii) = subplot(2, 1, ii, 'Parent', fig2);
%     hold on
% end

% for ii = 1:length(subplot_labels)
%     ylabel(ax(ii), 'r^2')

%     p = plot(ax(ii), 2e3 * [0, trial_fractions], [NaN, r2_synth(1, :)], '-xk', 'MarkerSize', 10);
%     p.Color(4) = alpha;

%     % Reconstructions from subjects
%     T2 = T(strcmp(T.target_signal_name, subplot_labels{ii}), :);
%     legend_labels = cell(2 * height(T2), 1);
%     for qq = 1:height(T2)
%         if PUBLISH
%             this_subject_ID = ['subject #', num2str(qq)];
%         else
%             this_subject_ID = T2.subject_ID{qq};
%         end

%         p = plot(ax(ii), 2e3 * [0, trial_fractions], [NaN, r2_cs_bins(qq, :)], '-x', 'MarkerSize', 10, 'Color', cmap(qq, :), 'MarkerFaceColor', cmap(qq, :), 'MarkerEdgeColor', cmap(qq, :));
%         legend_labels{2 * qq - 1} = [this_subject_ID, ' CS'];
%         p.Color(4) = alpha;
%         p = plot(ax(ii), 2e3 * [0, trial_fractions], [NaN, r2_lr_bins(qq, :)], '-o', 'MarkerSize', 10, 'Color', cmap(qq, :), 'MarkerFaceColor', cmap(qq, :), 'MarkerEdgeColor', cmap(qq, :));
%         legend_labels{2 * qq} = [this_subject_ID, ' LR'];
%         p.Color(4) = alpha;
%     end

%     xlabel(ax(end), 'number of trials')

%     % legend(ax(ii), [{'g.t.'}; legend_labels; {'baseline'}; {'synthetic'}], 'Location', 'eastoutside')
%     legend(ax(ii), [{'synthetic'}; legend_labels], 'Location', 'eastoutside')
% end

% if PUBLISH
%     figlib.pretty('PlotLineWidth', 3, 'EqualiseX', true, 'EqualiseY', true, 'FontSize', 36, 'PlotBuffer', 0.02)
%     figlib.tight();
%     figlib.label('XOffset', 0, 'YOffset', 0, 'FontSize', 36);
% else
%     figlib.pretty()
% end