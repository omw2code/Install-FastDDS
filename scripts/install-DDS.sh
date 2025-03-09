#!/bin/bash
# =========================================================================================
# Author: Brennan Rivera
# Created: 12-16-2024
# GitHub: omw2code
# -----------------------------------------------------------------------------------------
# Purpose:
# This script installs FastDDS and its related dependencies, builds required libraries,
# and generates the fastddsgen example program.
# =========================================================================================

set -e

usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  -c : Clones Fast-DDS, Fast-CDR, Foonathan memory, Fast-DDS-Gen
  -t : Number of jobs to build cloned repositories. Default is 1.
  -v : Specifies a version of FastDDS to install
  -h : Shows usage
EOF
    exit 1
}

validate_version() {
    if [ -z "${VERSION}" ]; then
        echo "Error: Version not specified. Use -v to provide a version." >&2
        usage
    fi
    if [[ ! ${VERSION} =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Version must be formatted as v#.#.# (e.g., v2.3.4)." >&2
        usage
    fi
    if [ -d "${HOME}/${VERSION}" ]; then
        echo "Error: ${HOME}/${VERSION} directory exisits." >&2
    fi
}

build_and_install() {
    local name="$1"
    local path="$2"
    local threads="$3"

    if [ ! -d "${path}" ]; then
        clone "${path}" "../"
    fi
    cd "${path}"

    echo "Building and installing ${name}..."

    if [ -d "build" ]; then
        echo "Removing existing build directory in ${name}"
        rm -rf "build"
    fi

    mkdir "build" && cd "build"
    cmake .. -DCMAKE_INSTALL_PREFIX=~/"$VERSION"/install -DBUILD_SHARED_LIBS=ON
    cmake --build . -j${threads} --target install
    echo "$name built and installed successfully."
    cd - >/dev/null
}

clone() {
    local repo="$1"
    local dir="$2"

    echo "Cloning $repo..."
    ( cd ${dir} && git clone https://github.com/eProsima/"$repo".git || {
        echo "Error: Failed to clone ${repo} because it already exists in ${dir}." >&2
    } ) 
}

generate_example_idl() {
    echo "Creating example.idl for testing..."

    if [ -d "../${VERSION}_program" ]; then
        rm -rf "../${VERSION}_program"
    fi

    mkdir -p "../${VERSION}_program"
    cd "../${VERSION}_program"
    cat << EOF > example.idl
struct example {
    unsigned long index;
    string message;
};
EOF
    echo "example.idl created successfully."
    cd - >/dev/null
}

build_fastdds_gen() {
    echo "Building Fast-DDS-Gen..."
    if [ ! -d "../Fast-DDS-Gen" ]; then
        clone "Fast-DDS-Gen" "../"
    fi
    cd ../Fast-DDS-Gen
    ./gradlew assemble
    cd - >/dev/null
}

run_fastddsgen() {
    cd "../${VERSION}_program"
    if [ ! -d "../Fast-DDS-Gen/build" ]; then
        build_fastdds_gen
    fi
    
    echo "Running fastddsgen with example option for testing..."
    java -jar ../Fast-DDS-Gen/build/libs/fastddsgen.jar -example CMake example.idl
    echo "Example program generated ..."
    cd - >/dev/null
}

# Remove the instance of find_package and add Fast-DDS, Fast-CDR install dir
update_cmakelists() {
    local install_dir="${HOME}/${VERSION}"
    local temp_file=$(mktemp)
    
    echo "Updating CMakeLists.txt for dependencies..."
    cat << EOF > "${temp_file}"
# FastDDS dependencies
link_directories(${install_dir}/lib libfastrtps)
link_directories(${install_dir}/lib libfastcdr)

# FastDDS dependencies
include_directories(${install_dir}/include ${install_dir}/include/fastcdr)
link_directories(${install_dir}/include)
EOF
   
    sed -i "/find_package/ r ${temp_file}" ../${VERSION}_program/CMakeLists.txt
    sed -i '/find_package/d' ../${VERSION}_program/CMakeLists.txt

    rm -f "$temp_file"
    export LD_LIBRARY_PATH="${install_dir}/lib":${LD_LIBRARY_PATH}
    echo "CMakeLists.txt updated successfully."
}


if [ $# -eq 0 ]; then
    usage
fi

# Default vars
THREADS=1
REPO_LIST=("foonathan_memory_vendor" "Fast-CDR" "Fast-DDS")
while getopts 'hctv:' opt; do
    case $opt in
        c)
            CLONE=1
            ;;
        t)
            THREADS=${OPTARG}
            ;;
        v)
            VERSION=${OPTARG}
            ;;
        *|h)
            usage
            ;;
    esac
done

validate_version

if [ -z "${CLONE}" ]; then
    echo "Cloning repositories..."
    for REPO in "${REPO_LIST[@]}"; do 
        clone "${REPO}" "../"
    done
fi

if [ -n "$VERSION" ]; then
    echo "Installing FastDDS version ${VERSION}..."
    for REPO in "${REPO_LIST[@]}"; do 
        build_and_install "${REPO}" "../${REPO}" "${THREADS}"
    done
    
    generate_example_idl
    run_fastddsgen
    update_cmakelists
    
    echo
    echo "Installation and setup of FastDDS, FastCDR, and foonathan memory completed."
    echo "Installation location: ${HOME}/${VERSION}"
    echo "Example program generated ..."
fi
