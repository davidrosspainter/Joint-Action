
function data2use = permF2(n, f, Nsub, epoch, code, t, fc, FWHM_tc, squared, PERM )


    wAMPG = NaN(n.x,length(f.wavelet),n.cond,Nsub);
    
    for SUB = 1:Nsub
        
        EPOCH = epoch{SUB};
        epochCode = code{SUB};
        
        if PERM ~= 1
            epochCode = epochCode( randperm(length(epochCode)) );
        end
        

        
        for CC = 1:n.cond
            
            erp = nanmean(EPOCH(:,epochCode==CC),2);
            
            P = morlet_transform(erp, t, f.wavelet, fc, FWHM_tc, squared);
            E = 1;
            wAMPG(:,:,CC,SUB) = abs( squeeze( P(E,:,:) ) ) * 2; % should be doubled i think (to include up/down sin cycle) - just like FFT
            
        end
        
    end
    
    data2use = nanmean( wAMPG(:,:,2,:), 4) - nanmean( wAMPG(:,:,1,:), 4);
    
end