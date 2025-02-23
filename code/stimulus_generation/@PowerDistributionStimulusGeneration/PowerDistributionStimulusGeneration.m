classdef PowerDistributionStimulusGeneration < AbstractBinnedStimulusGenerationMethod
    % Stimulus generation method
    % in which the frequencies in each bin are sampled
    % from a power distribution learned
    % from tinnitus examples

    properties
        % n_bins (1,1) {mustBePositive, mustBeInteger, mustBeReal} = 100
        distribution (:,1) {mustBeReal} = []
        distribution_filepath (1,:) char = ''
    end

end % classdef