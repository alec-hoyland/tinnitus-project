% ### cs  
% 
% ```matlab
% [x] = cs(responses, Phi, Gamma)
% [x] = cs(responses, Phi)
%```
% 
% **ARGUMENTS:**
% 
%   - responses: `n x 1` vector
% 
%   - Phi: `n x m` matrix,
%       where `n` is the number of trials/samples
%       and `m` is the dimensionality of the stimuli/spectrum/bins
% 
% **OUTPUTS:**
%   - x: compressed sensing reconstruction of the signal.

function x = cs(responses, Phi, Gamma, options)

    arguments
        responses (:,1) {mustBeNumeric}
        Phi {mustBeNumeric}
        Gamma (1,1) {mustBeInteger, mustBeNonnegative} = 32
        options.verbose = true
    end
    
    n_samples = length(responses);
    len_signal = size(Phi, 2);

    if options.verbose
        waittext(0, 'init');
    end

    Theta = zeros(n_samples, len_signal);
    for ii = 1:len_signal
        if options.verbose
            waittext(ii/len_signal, 'fraction');
        end
        ek = zeros(1, len_signal);
        ek(ii) = 1;
        Psi = idct(ek)';
        Theta(:, ii) = Phi * Psi;
    end
        
    s = zhangpassivegamma(Theta, responses, Gamma);

    if options.verbose
        waittext(0, 'init');
    end

    x = zeros(len_signal, 1);
    for ii = 1:len_signal
        if options.verbose
            waittext(ii/len_signal, 'fraction');
        end
        ek = zeros(1, len_signal);
        ek(ii) = 1;
        Psi = idct(ek)';
        x = x + Psi * s(ii);
    end

end