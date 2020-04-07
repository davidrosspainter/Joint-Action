cgmakesprite( spritenum.feedback, mon.res(1), mon.res(2), color.background )
cgsetsprite( spritenum.feedback )

% RT_fast: [NaN NaN NaN]
% RT_slow: [NaN NaN NaN]
% MT_slow: [NaN NaN NaN]
% leaving: [NaN NaN NaN]
% correct: [NaN NaN NaN]

for CURSOR = 1:n.cursors+1
    
    if isnan( use.react(CURSOR) )
        use.RT_slow(CURSOR) = true;
    end
    
    if isnan( use.inside(CURSOR) )
        
        use.MT_slow(CURSOR) = true;
        
    elseif ~isnan( use.inside(CURSOR) )
        
        if FRAME - 1 > use.inside(CURSOR) + f.HT
            use.MT(CURSOR) = ( use.inside(CURSOR) - use.react(CURSOR) ) ./ mon.ref * 1000;
        else
            use.MT_slow(CURSOR) = true;
        end
        
    end
    
    if ~use.RT_fast(CURSOR) && ~use.RT_slow(CURSOR) && ~use.MT_slow(CURSOR) && ~use.leaving(CURSOR)
        use.correct(CURSOR) = true;
    end
    
end

switch data(TRIAL,D.cond)
    
    case 1 % solo
        
        for MON = 1:n.mon
            
            CURSOR = MON;
            
            if use.RT_fast(CURSOR)
                cgdrawsprite( spritenum.solo_fast, mon.xcenter(MON), 0 )
            elseif use.RT_slow(CURSOR)
                cgdrawsprite( spritenum.solo_slow, mon.xcenter(MON), 0 )
            elseif use.MT_slow(CURSOR)
                cgdrawsprite( spritenum.solo_slow, mon.xcenter(MON), 0 )
            elseif use.leaving(CURSOR)
                cgdrawsprite( spritenum.solo_left, mon.xcenter(MON), 0 )
            elseif use.correct(CURSOR)
                cgdrawsprite( 7000 + round( sum( [ use.RT(CURSOR) use.MT(CURSOR) ] ) ), mon.xcenter(MON), 0 )
            end
        end
        
    case 2 % joint
        
        CURSOR = 3;
        
        for MON = 1:n.mon
            
            if any( use.RT_fast(1:2) ) % if individual RT fast in joint, group is fast
                
                cgdrawsprite( spritenum.solo_fast, mon.xcenter(MON), 0 )
                
            else
            
                if use.RT_fast(CURSOR)
                    cgdrawsprite( spritenum.team_fast, mon.xcenter(MON), 0 )
                elseif use.RT_slow(CURSOR)
                    cgdrawsprite( spritenum.team_slow, mon.xcenter(MON), 0 )
                elseif use.MT_slow(CURSOR)
                    cgdrawsprite( spritenum.team_slow, mon.xcenter(MON), 0 )
                elseif use.leaving(CURSOR)
                    cgdrawsprite( spritenum.team_left, mon.xcenter(MON), 0 )
                elseif use.correct(CURSOR)
                    cgdrawsprite( 7000 + round( sum( [ use.RT(CURSOR) use.MT(CURSOR) ] ) ), mon.xcenter(MON), 0 )
                end 
            end
            
        end
end

cgsetsprite( 0 )