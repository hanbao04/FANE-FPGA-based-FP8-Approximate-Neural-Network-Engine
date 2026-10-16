#!/usr/bin/env bash
# Synthesize/route one Y=1 core, then simulate the netlists against the Python golden model:
# post-synthesis functional, post-route functional, post-route SDF (slow/max and fast/min).
#   run_postsim.sh --target mvm  --seeds "2026 2027" --mvm-vectors N --period NS [--carry-remap]
#   run_postsim.sh --target conv --seeds "2026 2027" --conv-width W --conv-height H --period NS [--carry-remap]
# Requires: PYTHON_BIN (python with torch) and Vivado settings64.sh sourced.
# Netlists, vectors, logs and build files stay in build/ (removed by `make clean`).
set -euo pipefail

SIM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SIM_ROOT}/../../.." && pwd)"
: "${PYTHON_BIN:?PYTHON_BIN is not set}"
: "${XILINX_VIVADO:?source Vivado settings64.sh first}"

TARGET= SEEDS= MVM_VECTORS= CONV_WIDTH= CONV_HEIGHT= PERIOD= CARRY_REMAP=0
while (( $# )); do
    case "$1" in
        --carry-remap) CARRY_REMAP=1; shift; continue ;;
        --target) TARGET="${2:?}" ;;
        --seeds) SEEDS="${2:?}" ;;
        --mvm-vectors) MVM_VECTORS="${2:?}" ;;
        --conv-width) CONV_WIDTH="${2:?}" ;;
        --conv-height) CONV_HEIGHT="${2:?}" ;;
        --period) PERIOD="${2:?}" ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
    shift 2
done
: "${SEEDS:?--seeds is required}" "${PERIOD:?--period is required}"
case "${TARGET}" in
    mvm) : "${MVM_VECTORS:?--mvm-vectors is required}" ;;
    conv) : "${CONV_WIDTH:?--conv-width is required}" "${CONV_HEIGHT:?--conv-height is required}" ;;
    *) echo "--target must be mvm or conv" >&2; exit 2 ;;
esac

WORK="${SIM_ROOT}/build/postsim_${TARGET}"
rm -rf "${WORK}"; mkdir -p "${WORK}"

GLBL="${XILINX_VIVADO}/data/verilog/src/glbl.v"
XSIM_LIB="${XILINX_VIVADO}/lib/lnx64.o:${XILINX_VIVADO}/lib/lnx64.o/Default:${LD_LIBRARY_PATH:-}"

quiet() {  # quiet NAME CMD...: run silently, show the log tail only on failure
    local log="${WORK}/$1.log"; shift
    "$@" >"${log}" 2>&1 || { tail -n 40 "${log}" >&2; return 1; }
}

simulate_stage() {  # simulate_stage STAGE CORNER NETLIST (uses cfg/unit/width/height)
    local stage="$1" corner="$2" netlist="$3"
    local dir="${cfg}/${stage}_${corner}"
    mkdir -p "${dir}"
    "${PYTHON_BIN}" "${SIM_ROOT}/make_postsim_adapter.py" --rtl "${REPO}/hw/fane_opt/${rtl}" \
        --netlist "${cfg}/${netlist}" --output "${dir}/adapter.sv" --width "${width}" --height "${height}" \
        --testbench "${SIM_ROOT}/${tb}.sv" --testbench-output "${dir}/testbench.sv" --period "${PERIOD}"
    cd "${dir}"
    local -a args=(work."${tb}" work.glbl -s snap --debug off --mt off --standalone)
    if [[ "${stage}" == route-time ]]; then
        local sdf="${cfg}/post_route.sdf"
        [[ "${corner}" == max ]] || sdf="${cfg}/post_route_fast.sdf"
        args+=(-L simprims_ver -L unisims_ver "--sdf${corner}" "/${tb}/dut/netlist=${sdf}"
            --transport_int_delays --pulse_r 0 --pulse_int_r 0 --pulse_e 0 --pulse_int_e 0 "--${corner}delay")
    else
        args+=(-L unisims_ver)
    fi
    quiet compile xvlog --sv -d POST_SIM testbench.sv adapter.sv "${cfg}/${netlist}" "${GLBL}"
    quiet elaborate xelab "${args[@]}"
    if [[ "${stage}" == route-time ]]; then
        # a timing sim with skipped SDF paths proves nothing
        if ! grep -q 'SDF backannotation was successful' "${WORK}/elaborate.log" ||
            grep -Eiq '(annotation will be skipped|Unable to find hierarchical path|Failed to annotate)' "${WORK}/elaborate.log"; then
            echo "SDF annotation incomplete (${unit} ${stage} ${corner})" >&2
            return 1
        fi
    fi
    local seed
    for seed in ${SEEDS}; do
        local vec="${cfg}/vectors_${seed}"
        if [[ ! -d "${vec}" ]]; then
            "${PYTHON_BIN}" "${SIM_ROOT}/generate_vectors.py" --seed "${seed}" --output-dir "${vec}" "${vector_args[@]}"
        fi
        quiet simulate env "LD_LIBRARY_PATH=${XSIM_LIB}" ./xsim.dir/snap/axsim --testplusarg "VECTOR_DIR=${vec}"
        if ! grep -q "${marker}" "${WORK}/simulate.log" ||
            grep -Eiq '(timing violation|\$setuphold|\$recrem|\$hold\(|\$setup\(|Fatal:|Error:)' "${WORK}/simulate.log"; then
            echo "POSTSIM FAIL ${unit} ${width}x${height} ${stage} ${corner} seed=${seed}" >&2
            tail -n 40 "${WORK}/simulate.log" >&2
            return 1
        fi
    done
    echo "POSTSIM PASS ${unit} ${width}x${height} stage=${stage} corner=${corner} seeds='${SEEDS}'"
}

run_config() {  # run_config UNIT WIDTH HEIGHT
    local unit="$1" width="$2" height="$3" tb rtl marker
    local -a vector_args
    local cfg="${WORK}/${unit}_${width}x${height}"
    if [[ "${unit}" == mvm ]]; then
        tb=tb_mm_chip; rtl=mm/v_opt/mm_chip.sv; marker='MM Y=1 validation PASS'
        vector_args=(--target mvm --mvm-vectors "${MVM_VECTORS}")
    else
        tb=tb_conv_chip; rtl=conv/v_opt/conv_chip.sv; marker='Conv Y=1 FP8 writeback validation PASS'
        vector_args=(--target conv --conv-width "${width}" --conv-height "${height}")
    fi
    mkdir -p "${cfg}"
    (cd "${cfg}" && quiet build vivado -mode batch -nolog -nojournal -source "${SIM_ROOT}/build_postsim.tcl" \
        -tclargs "${unit}" "${cfg}" "${width}" "${height}" "${PERIOD}" "${CARRY_REMAP}")
    echo "POSTSIM STA ${unit} ${width}x${height} $(grep -o 'period_ns=.*' "${WORK}/build.log" | tail -n 1)"
    (
        simulate_stage synth none post_synth_func.v
        simulate_stage route-func none post_route_func.v
        simulate_stage route-time max post_route_time.v
        simulate_stage route-time min post_route_time.v
    )
}

if [[ "${TARGET}" == mvm ]]; then
    run_config mvm "$((9*MVM_VECTORS))" 1
else
    run_config conv "${CONV_WIDTH}" "${CONV_HEIGHT}"
fi
