#!/bin/bash

set -e

usage() {
    echo "Usage: $0 [-v v#.#.#] [-h]"
    echo " -v : Specifies a version of FastDDS to install"
    echo " -h : Shows usage"
    exit 1
}

validate_version() {
    if [[ ! $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "Error: Version must be formatted as v#.#.# (e.g., v2.3.4)." >&2
        usage
    fi
    if [ -d "$HOME/$VERSION" ]; then
        echo "Error: $HOME/$VERSION directory exisits." >&2
        exit 1;
    fi
}

build_and_install() {
    local name="$1"
    local path="$2"

    echo "Building and installing $name..."
    cd "$path"

    if [ -d "build" ]; then
        echo "Removing existing build directory in $name"
        rm -rf "build"
    fi

    mkdir "build" && cd "build"
    cmake .. -DCMAKE_INSTALL_PREFIX=~/"$VERSION"/install -DBUILD_SHARED_LIBS=ON
    cmake --build . --target install
    echo "$name built and installed successfully."
    cd - >/dev/null
}

clone_and_checkout() {
    cd ../
    echo "Cloning Fast-DDS, Fast-CDR, foonathan..."
    git clone https://github.com/eProsima/foonathan_memory_vendor.git
    git clone https://github.com/eProsima/Fast-CDR.git
    git clone https://github.com/eProsima/Fast-DDS.git
    git clone https://github.com/eProsima/Fast-DDS-Gen.git
    cd ./Fast-DDS && git checkout tags/$VERSION
    cd ../scripts
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
}

run_fastddsgen() {
    echo "Running fastddsgen with example option for testing..."
    java -jar ~/Fast-DDS-Gen/build/libs/fastddsgen.jar -example CMake example.idl
    echo "Example program generated ..."
}


update_cmakelists() {
    echo "Updating CMakeLists.txt for dependencies..."
    local install_dir="$HOME/$VERSION"
    local temp_file=$(mktemp)

    # Write dependencies to the temporary file
    cat << EOF > "$temp_file"
# FastDDS dependencies
link_directories($install_dir/lib libfastrtps)
link_directories($install_dir/lib libfastcdr)

# FastDDS dependencies
include_directories($install_dir/include $install_dir/include/fastcdr)
link_directories($install_dir/include)
EOF

    # Insert dependencies before the first `find_package` and remove `find_package`
    sed -i "/find_package/ r $temp_file" CMakeLists.txt
    sed -i '/find_package/d' CMakeLists.txt

    # Remove the temporary file
    rm -f "$temp_file"

    echo "CMakeLists.txt updated successfully."
}


if [ $# -eq 0 ]; then
    usage
fi

while getopts 'hcv:' opt; do
    case $opt in
        c)
            CLONE=1
            ;;
        v)
            VERSION=$OPTARG
            ;;
        h)
            usage
            ;;
        *)
            usage
            ;;
    esac
done


validate_version

if [ -v $CLONE ]; then
    clone
fi

echo "Installing FastDDS version $VERSION..."

build_and_install "foonathan_memory_vendor" "../foonathan_memory_vendor"
build_and_install "FastCDR" "../Fast-CDR"
build_and_install "FastDDS" "../Fast-DDS"

generate_example_idl
run_fastddsgen
update_cmakelists

echo
echo "Installation and setup of FastDDS, FastCDR, and foonathan memory completed."
echo "Example program generated ..."