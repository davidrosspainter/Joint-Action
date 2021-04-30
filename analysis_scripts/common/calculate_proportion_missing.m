function result = calculate_proportion_missing(data)
    result = sum(isnan(data(:)))/numel(data);