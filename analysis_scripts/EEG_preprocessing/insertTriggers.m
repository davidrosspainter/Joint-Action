function L = insertTriggers( L, idx, nt )

L = [ L( 1:idx-1 ) ; NaN(nt,1) ; L( idx : end ) ];