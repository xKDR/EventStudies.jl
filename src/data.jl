"""
    load_data(dataset::String)

Load a dataset from the EventStudies.jl package.  
The dataset can be either a CSV file or an RData file, which is shipped along with EventStudies.jl!
"""
function load_data(dataset::String)
    if dataset in readdir(artifact"eventstudies_r_data")
        return load_r_data(joinpath(artifact"eventstudies_r_data", dataset))
    elseif dataset in readdir(artifact"eventstudies_csv_data")
        return load_csv_data(joinpath(artifact"eventstudies_csv_data", dataset))
    else
        error("Dataset $dataset not found.")
    end
end

function load_r_data(path::String)
    # extract the relevant R object
    raw_data = RData.load(path; convert = false)[splitext(basename(path))[1]]
    # convert to TSFrame if it's a zoo object
    return if haskey(raw_data.attr, "class") && raw_data.attr["class"].data[1] == "zoo"
        zoo_to_tsframe(raw_data)
    else # otherwise, just convert to the nearest Julian type
        RData.sexp2julia(raw_data)
    end
end

function load_csv_data(path::String)
    # super simple CSV extraction
    return CSV.read(path, DataFrame; missingstring = "NA")
end