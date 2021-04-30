function L = deleteTriggers( L, idx, nt )

if length(idx) == 1
    L( idx : idx + nt-1 ) = [];
else
    for TT = 1:length(idx)
        L( idx(TT) : idx(TT) + nt-1 ) = [];
    end
end
    

