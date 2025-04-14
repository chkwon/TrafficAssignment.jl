# latest commit to bstabler/TransportationNetworks: August 2nd, 2023
const LAST_COMMIT_SHA = "375e0da93858c547230c5cf9ea8a96de4ccff29e"  # to update

function __init__()
    name1 = "TransportationNetworks"
    message1 = """
    This is a repository of real-life road networks, used to study the Traffic Assignment Problem.
    - Data: <https://github.com/bstabler/TransportationNetworks>
    """
    remote_path1 = "https://github.com/bstabler/TransportationNetworks/archive/$(LAST_COMMIT_SHA).zip"
    hash1 = "3ef8f870c14fc189a31d34266140d21883ce020cb8847788b1e2caea1e00a734"

    datadep1 = DataDep(
        name1,
        message1,
        remote_path1,
        hash1;
        fetch_method=DataDeps.fetch_default,
        post_fetch_method=_unpack_all1,
    )
    DataDeps.register(datadep1)

    name2 = "UnifiedTrafficDataset"
    message2 = """
    This is a unified and validated traffic dataset for 20 U.S. cities.
    - Paper: <https://www.nature.com/articles/s41597-024-03149-8>
    - Data: <https://figshare.com/articles/dataset/A_unified_and_validated_traffic_dataset_for_20_U_S_cities/24235696>
    - Repo: <https://github.com/xuxiaotong/A_unified_and_validated_traffic_dataset_for_20_U.S._cities>
    """
    remote_path2 = "https://figshare.com/ndownloader/files/48908890"
    hash2 = "afe5cfddbba8996290c29847e9d14f5c62fed67cd829dc5cadca7fee352a84e1"

    datadep2 = DataDep(
        name2,
        message2,
        remote_path2,
        hash2;
        fetch_method=DataDeps.fetch_default,
        post_fetch_method=DataDeps.unpack,
    )
    DataDeps.register(datadep2)
    return nothing
end

function _unpack_all1(zip_file)
    DataDeps.unpack(zip_file; keep_originals=false)
    # decompress potential zip files inside each instance
    for instance_dir in readdir("TransportationNetworks-$LAST_COMMIT_SHA"; join=true)
        isdir(instance_dir) || continue
        for potential_zip_file in readdir(instance_dir; join=true)
            if endswith(potential_zip_file, ".zip")
                run(unpack_cmd(potential_zip_file, instance_dir, ".zip", ""))
            end
        end
    end
end

"""
    datapath(dataset_name)
    datapath(dataset_name, instance_name)

Return the absolute path to the raw data.

The `dataset_name` must be one of $DATASET_NAMES.
"""
function datapath(dataset_name::AbstractString)
    if dataset_name == "TransportationNetworks"
        return joinpath(
            datadep"TransportationNetworks", "TransportationNetworks-$LAST_COMMIT_SHA"
        )
    else
        @assert dataset_name == "UnifiedTrafficDataset"
        return datadep"UnifiedTrafficDataset"
    end
end

function datapath(dataset_name::AbstractString, instance_name::AbstractString)
    return joinpath(datapath(dataset_name), instance_name)
end
