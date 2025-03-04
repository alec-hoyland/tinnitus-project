% ### survey_viz
% This script collects and analyzes subjective rankings from ompare_recons.m
% End of documentation

%% Data setup
data_dir = '~/Desktop/Lammert_Lab/Tinnitus/resynth_test_data';
d = dir(fullfile(data_dir, 'survey_*.csv'));
d_configs = dir(fullfile(data_dir, 'config*.yaml'));

%% Load
fname = d(1).name;
underscores = find(fname == '_');
user_id = fname(underscores(end)+1:end-4);
T = readtable(fullfile(data_dir, d(1).name));
T.user_id = {user_id};

for ii = 2:length(d)
    fname = d(ii).name;
    underscores = find(fname == '_');
    user_id = fname(underscores(end)+1:end-4);
    T2 = readtable(fullfile(d(ii).folder, d(ii).name));
    T2.user_id = {user_id};
    T = [T; T2];
end

% Collect target signal names
hash = cell(length(d_configs), 1);
tsn = cell(length(d_configs), 1);
for ii = 1:length(d_configs)
    config = parse_config(fullfile(data_dir, d_configs(ii).name));
    hash{ii} = get_hash(config);
    tsn{ii} = config.target_signal_name;
end

% Add r-scores and target signal names
T_rvals = readtable(fullfile(data_dir,'rvals.csv'));
T = outerjoin(T,T_rvals,'MergeKeys',true);
T = outerjoin(T,table(hash,tsn),'MergeKeys',true);
T = sortrows(T, {'tsn', 'r_lr'}, 'ascend');

%% Plot setup
unique_ids = unique(T.user_id);
unique_hashes = unique(T.hash, 'stable');
lbl = {'white noise', 'standard', 'sharpened'};

%% Bar ratings
figure
tiledlayout('flow')
for ii = 1:length(unique_hashes)
    this_hash = unique_hashes(ii);
    ind = strcmp(T.hash,this_hash);
    y = [T.whitenoise(ind, :), ...
        T.recon_standard(ind, :), ...
        T.recon_adjusted(ind, :)]';
    r = T.r_lr(ind,:);
    target_name = T.tsn(ind,:);
    
    [~,p12] = ttest(y(1,:),y(2,:));
    [~,p23] = ttest(y(2,:),y(3,:));
    [~,p13] = ttest(y(1,:),y(3,:));

    if ~isempty(target_name{1})
        ttl = {[target_name{1}, '. hash: ', this_hash{:}, '. r: ', num2str(r(1))], ...
            ['p(w-st): ', num2str(p12,3), '. p(w-sh): ', num2str(p13,3), '. p(st-sh): ', num2str(p23,3)]};
    else
        ttl = {[this_hash{:}], ...
            ['p(w-st): ', num2str(p12,3), '. p(w-sh): ', num2str(p13,3), '. p(st-sh): ', num2str(p23,3)]};
    end

    nexttile
    bar(y)
    hold on
    scatter(1:size(y,1),mean(y,2),'k','filled')
    set(gca, 'XTickLabel', lbl, 'XTick', 1:length(lbl), 'YTick', 1:7)
    ylim([0,7])
    title(ttl, 'FontSize', 16)
    grid on
%     legend(unique_ids,'Location','northwestoutside')
end
leg = legend(unique_ids,'Orientation','horizontal');
leg.Layout.Tile = 'north';

leg = legend(unique_ids,'Orientation','horizontal','Fontsize',14);
leg.Layout.Tile = 'north';

%% Scatter params
figure
for ii = 1:length(unique_ids)
    ind = strcmp(T.user_id,unique_ids(ii));
    scatter(T.mult(ind,:), T.binrange(ind,:), 'filled');
    hold on
end
legend(unique_ids)
xlabel('Mult param', 'FontSize', 16)
ylabel('Binrange param', 'FontSize', 16)
