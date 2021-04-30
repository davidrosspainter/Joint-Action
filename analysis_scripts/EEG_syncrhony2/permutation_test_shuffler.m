function m = permutation_test_shuffler(PERMUTATION, type2, r4, nEpochs, number_of_channels, number_of_sessions)

tic

if PERMUTATION == 1 % obtained results
    type_to_use = type2;
else % permuted results
    type_to_use = type2(randperm(size(type2,1)), :, :);
end

m = NaN(nEpochs, 2, number_of_channels);

for e2use = 1:number_of_channels
    
    res = NaN(nEpochs,2,number_of_sessions);
    
    for SESSION = 1:number_of_sessions
        data2use = squeeze( r4(:,SESSION,:,e2use) );
        res(:,:,SESSION) = grpstats( data2use, type_to_use(:,1,SESSION), {'mean'} )';
    end
    
    m(:,:,e2use) = nanmean(res,3);
    
end

toc