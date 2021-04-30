function [IDX, real_Hz] = find_Hz_IDX(f,Hz)

n.Hz = length(Hz);
IDX = NaN(n.Hz,1);
real_Hz = NaN(n.Hz,1);

for H = 1:n.Hz
    
    [notused, IDX(H)] = min( abs( f - Hz(H) ) );
    real_Hz(H) = f(IDX(H));
    
end