function session_string = generate_session_string(SESSION)
    
    if SESSION < 10
        session_string = [ 'S0' num2str(SESSION) ];
    else
        session_string =  [ 'S' num2str(SESSION) ];
    end