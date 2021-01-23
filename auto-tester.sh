#!/bin/bash

INPUT="/submission"
OUTPUT_DIR="/results"
mkdir -p "${OUTPUT_DIR}"


_submission_dir="${HOME}/spec/submission" # extracted files
_tmp_extracted="/tmp/extracted_submission"
mkdir -p "$_tmp_extracted"

echo "[INFO] Extracting submission file"
file_output=$(file "$INPUT")
case "${file_output}" in 
    *"Zip archive data"*) 
        echo "Extracting zip file"
        unzip -j "${INPUT}" -d "${_tmp_extracted}"
        ;;

    *"POSIX tar archive"*) 
        echo "Extracting tar archive"
        tar -xvf "${INPUT}" -C "${_tmp_extracted}"
        ;;

    *"gzip compressed data"*) 
        echo "Extracting a gziped archive"
        tar -zxvf "${INPUT}" -C "${_tmp_extracted}"
        ;;

    *"(No such file or directory)"*) 
        printf "[ERROR] No file found. Using docker, mount the submission file with '-v'. eg:\n  docker run --rm -v \"\$(pwd)/submission.zip:/submission:ro\" <image> <args> %s\n" "$@"
        exit 1
        ;;
    
    *": directory")
        echo "[INFO] Directory was found. No extraction is needed"
        cp -r "${INPUT}" "${_tmp_extracted}"
        ;;

    *) 
        echo "ERROR: unrecognised file type: ${file_output}"
        exit 1
        ;;
esac

echo "[INFO] Finding submission files"
cd "$_tmp_extracted" || exit 111
# iterate over some directories if single directory is found (when zipping nested dir)
for _ in {1..3}; do
    if [ "$(ls | wc -l)" -eq 1 ]; then
        singledir="$(ls)"
        [ -d "${singledir}" ] && cd "${singledir}" && continue
    fi
    break
done 

mv ./* "${_submission_dir}/."
cd "${HOME}" || exit 111

echo "[INFO] Starting auto-grader"
make "$@"

echo "[INFO] Getting the Results"
cp -r /grader/spec/results/* "${OUTPUT_DIR}/."  

