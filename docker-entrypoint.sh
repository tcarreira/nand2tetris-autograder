#!/bin/bash

[ "x${QUIET}" == "xyes" ] && exec 5>&1 1>/dev/null

INPUT="${SUBMISSION:-/submission}"
OUTPUT_DIR="${RESULTS_DIR:-/results}"
mkdir -p "${OUTPUT_DIR}"

# Some tools (like https://github.com/StepicOrg/epicbox) pass the argument 
#      as a commnand ['/bin/sh','-c','arg']. Strip it:
if [ "x${STRIP_SH_ARGS}" == "xyes" ]; then
    for foo in "/bin/sh" "/bin/bash" "/bin/ash" "-c"; do
        [ "x$1" == "x$foo" ] && shift
    done
fi 

HOME="/grader"
_submission_dir="${HOME}/spec/submission" # extracted files
_tmp_extracted="/tmp/extracted_submission"
mkdir -p "$_tmp_extracted"

echo "[INFO] Extracting submission file"
file_output=$(file "$INPUT")
case "${file_output}" in 
    *"Zip archive data"*) 
        echo "Extracting zip file"
        unzip "${INPUT}" -d "${_tmp_extracted}"
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
        printf "[ERROR] No file found. Using docker, mount the submission file with '-v'. eg:\n  docker run --rm -v \"\$(pwd)/submission.zip:/submission:ro\" <image> <args> %s\n" "$@" >&2
        exit 1
        ;;
    
    *": directory")
        echo "[INFO] Directory was found. No extraction is needed"
        cp -r "${INPUT}" "${_tmp_extracted}"
        ;;

    *) 
        echo "ERROR: unrecognised file type: ${file_output}" >&2
        exit 1
        ;;
esac

echo "[INFO] Finding submission files"
cd "$_tmp_extracted" || exit 111
# iterate over some directories if single directory is found (when zipping nested dir)
for _ in {1..3}; do
    rm -rf _* .??* ~* # remove hidden files like __MACOSX or .hidden or ~TMP
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
cp -r "${HOME}/spec/results/"* "${OUTPUT_DIR}/."  

[ "x${QUIET}" == "xyes" ] && cat "${HOME}/spec/results/results.json" >&5
