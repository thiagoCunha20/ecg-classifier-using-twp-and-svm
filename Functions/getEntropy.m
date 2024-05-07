function entropy = getEntropy(signal)
    if ~isvector(signal)
      error('Input signal must be a vector.');
    end
    
    [counts, ~] = hist(signal);
    p = counts / numel(signal);
    p(p == 0) = min(p(p>0));
    entropy = -sum(p .* log2(p));
end
