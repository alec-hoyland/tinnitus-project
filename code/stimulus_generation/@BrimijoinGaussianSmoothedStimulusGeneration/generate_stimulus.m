% ### generate_stimulus
% 
% ```matlab
% [stim, Fs, spect, binned_repr, frequency_vector] = generate_stimulus(self)
% ```
% 
% TODO: write documentation
% 
% **OUTPUTS:**
% 
%   stim: `n x 1` numerical vector,
%       the stimulus waveform,
%       where `n` is `self.get_nfft() + 1`.
% 
%   Fs: `1x1` numerical scalar,
%       the sample rate in Hz.
% 
%   spect: `m x 1` numerical vector,
%       the half-spectrum,
%       where m is `self.get_nfft() / 2`,
%       in dB.
% 
%   binned_repr: `self.n_bins x 1` numerical vector,
%       the binned representation.
% 
%   frequency_vector: `m x 1` numerical vector,
%       the frequencies associated with the spectrum,
%       where `m` is `self.get_nfft() / 2`,
%       in Hz.
% 
% Class Properties Used:
% 
% ```
%   n_bins
%   amplitude_values
% ```
% 
% See Also: 
% AbstractBinnedStimulusGenerationMethod.get_freq_bins
% AbstractStimulusGenerationMethod.generate_stimuli_matrix

function [stim, Fs, spect, binned_repr, frequency_vector, bin_starts, bin_stops] = generate_stimulus(self)

    [binnum, Fs, nfft, frequency_vector] = self.get_freq_bins();
    spect = self.get_empty_spectrum();
    binned_repr = zeros(self.n_bins, 1);

    for ii = 1:self.n_bins
        this_amplitude_value = self.amplitude_values(randi(length(self.amplitude_values)));
        binned_repr(ii) = this_amplitude_value;

        %% Find the two parameters of the gaussian (mu and sigma)
        % mu: the center of the bin
        % sigma: half the width of the bin

        %% Create a normal distribution with the correct number of points
        % (same size as spect)
        % with parameters mu and sigma.
        % Normalize and add it to the spectrum.

        %% Rescale spectrum
    end

    % Synthesize Audio
    stim = self.synthesize_audio(spect, nfft);


end % function