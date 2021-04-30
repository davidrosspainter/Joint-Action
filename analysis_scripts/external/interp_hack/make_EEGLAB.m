function EEG = make_EEGLAB( data2use, fs, chanlocs )

% data2use - time x channels; badchans - indices

data2use = data2use';

EEG.setname = '';
EEG.filename = '';
EEG.filepath = '';
EEG.subject = '';
EEG.group = '';
EEG.condition = '';
EEG.session = [];
EEG.comments = '';
EEG.nbchan = size( data2use, 1);
EEG.trials = 1;
EEG.pnts = size(data2use,2);
EEG.srate = fs;
EEG.xmin = 0;
EEG.xmax = size(data2use,2) / fs;
EEG.times = ( 0 : size(data2use,2) - 1 ) ./ fs * 1000;
EEG.data = data2use;
EEG.icaact = [];
EEG.icawinv = [];
EEG.icasphere = [];
EEG.icaweights = [];
EEG.icachansind = [];
EEG.chanlocs = chanlocs;
EEG.urchanlocs = [];
EEG.chaninfo = [];
EEG.ref = 'common';
EEG.event = [];
EEG.urevent = [];
EEG.eventdescription = {''  ''  ''  ''  ''  ''  ''};
EEG.epoch = [];
EEG.epochdescription = {};
EEG.reject = [];
EEG.stats = [];
EEG.specdata = [];
EEG.specicaact = [];
EEG.splinefile = '';
EEG.icasplinefile = '';
EEG.dipfit = [];
EEG.history = [];
EEG.saved = 'no';
EEG.etc = [];
EEG.datfile = '';