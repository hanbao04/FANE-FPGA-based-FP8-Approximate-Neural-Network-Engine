#!/usr/bin/env bash
# One Y=1 RTL simulation against the Python golden model.
#   run_xsim.sh --target mvm  --seed S --mvm-vectors N
#   run_xsim.sh --target conv --seed S --conv-width W --conv-height H
# Requires: PYTHON_BIN (python with torch) and Vivado settings64.sh sourced.
# Vectors, logs and build files stay in build/ (removed by `make clean`).
set -euo pipefail

SIM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SIM_ROOT}/../../.." && pwd)"
: "${PYTHON_BIN:?PYTHON_BIN is not set}"
: "${XILINX_VIVADO:?source Vivado settings64.sh first}"

TARGET= SEED= MVM_VECTORS= CONV_WIDTH= CONV_HEIGHT=
while (( $# )); do
    case "$1" in
        --target) TARGET="${2:?}" ;;
        --seed) SEED="${2:?}" ;;
        --mvm-vectors) MVM_VECTORS="${2:?}" ;;
        --conv-width) CONV_WIDTH="${2:?}" ;;
        --conv-height) CONV_HEIGHT="${2:?}" ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
    shift 2
done
: "${SEED:?--seed is required}"
case "${TARGET}" in
    mvm) : "${MVM_VECTORS:?--mvm-vectors is required}" ;;
    conv) : "${CONV_WIDTH:?--conv-width is required}" "${CONV_HEIGHT:?--conv-height is required}" ;;
    *) echo "--target must be mvm or conv" >&2; exit 2 ;;
esac

case "${TARGET}" in
    mvm) WORK="${SIM_ROOT}/build/xsim_mvm_s${SEED}_n${MVM_VECTORS}" ;;
    conv) WORK="${SIM_ROOT}/build/xsim_conv_s${SEED}_${CONV_WIDTH}x${CONV_HEIGHT}" ;;
esac
rm -rf "${WORK}"; mkdir -p "${WORK}"

quiet() {  # quiet NAME CMD...: run silently, show the log tail only on failure
    local log="${WORK}/$1.log"; shift
    "$@" >"${log}" 2>&1 || { tail -n 40 "${log}" >&2; return 1; }
}
simulate() {  # simulate TOP MARKER; runs in ${WORK}
    local top="$1" marker="$2"
    quiet elaborate xelab "work.${top}" work.glbl "${@:3}" -s snap \
        -L unisims_ver --debug off --mt off --standalone
    quiet simulate env "LD_LIBRARY_PATH=${XILINX_VIVADO}/lib/lnx64.o:${XILINX_VIVADO}/lib/lnx64.o/Default:${LD_LIBRARY_PATH:-}" \
        ./xsim.dir/snap/axsim --testplusarg "VECTOR_DIR=${WORK}/vectors"
    grep -q "${marker}" "${WORK}/simulate.log" || { tail -n 40 "${WORK}/simulate.log" >&2; return 1; }
}

GLBL="${XILINX_VIVADO}/data/verilog/src/glbl.v"
cd "${WORK}"
if [[ "${TARGET}" == mvm ]]; then
    "${PYTHON_BIN}" "${SIM_ROOT}/generate_vectors.py" --target mvm --seed "${SEED}" \
        --mvm-vectors "${MVM_VECTORS}" --output-dir vectors
    R="${REPO}/hw/fane_opt/mm/v_opt"
    quiet compile xvlog --sv "${SIM_ROOT}/tb_mm_chip.sv" "${R}/mm_chip.sv" "${R}/mm_top.v" \
        "${R}/mm.v" "${R}/fpmac_mm.v" "${R}/addmul.v" "${R}/fpadder.v" "${R}/bram_adder.v" "${GLBL}"
    simulate tb_mm_chip 'MM Y=1 validation PASS' --generic_top "MVM_VECTORS=${MVM_VECTORS}"
    echo "PASS xsim mvm seed=${SEED} vectors=${MVM_VECTORS}"
else
    "${PYTHON_BIN}" "${SIM_ROOT}/generate_vectors.py" --target conv --seed "${SEED}" \
        --conv-width "${CONV_WIDTH}" --conv-height "${CONV_HEIGHT}" --output-dir vectors
    R="${REPO}/hw/fane_opt/conv/v_opt"
    quiet compile xvlog --sv "${SIM_ROOT}/tb_conv_chip.sv" "${R}/conv_chip.sv" "${R}/conv_top.v" \
        "${R}/addr_gen.v" "${R}/conv.v" "${R}/fpmac_conv.v" "${R}/fp8_addmul.v" "${R}/fp8_adder.v" \
        "${R}/carry8_adder.v" "${R}/md_in.v" "${R}/md_out.v" "${R}/mux_add_exp.v" "${R}/mux_add_mant.v" "${GLBL}"
    simulate tb_conv_chip 'Conv Y=1 FP8 writeback validation PASS' \
        --generic_top "IMG_W=${CONV_WIDTH}" --generic_top "IMG_D=${CONV_HEIGHT}"
    echo "PASS xsim conv seed=${SEED} size=${CONV_WIDTH}x${CONV_HEIGHT}"
fi
