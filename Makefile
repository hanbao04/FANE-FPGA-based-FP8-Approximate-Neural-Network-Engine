SHELL := /bin/bash

SIM := hw/fane_opt/sim

# e.g.
#   make mvm  SEEDS="2026 2027" MVM_VECTORS=5
#   make conv SEEDS="2026" CONV_WIDTH=4 CONV_HEIGHT=6
#   make postsim-mvm  SEEDS="2026" MVM_VECTORS=5 PERIOD=10
#   make postsim-conv SEEDS="2026" CONV_WIDTH=4 CONV_HEIGHT=6 PERIOD=10

need = $(foreach v,$(1),$(if $($(v)),,$(error $(v) is required)))

.PHONY: help sim mvm conv postsim postsim-mvm postsim-conv clean

help:
	@echo "make mvm  SEEDS=... MVM_VECTORS=N                         RTL sim, MVM"
	@echo "make conv SEEDS=... CONV_WIDTH=W CONV_HEIGHT=H         RTL sim, Conv"
	@echo "make sim                                                  both (needs all of the above)"
	@echo "make postsim-mvm  SEEDS=... MVM_VECTORS=N PERIOD=NS       netlist sims, MVM"
	@echo "make postsim-conv SEEDS=... CONV_WIDTH=W CONV_HEIGHT=H PERIOD=NS   netlist sims, Conv"
	@echo "make clean                                                remove all generated files"

sim: mvm conv

mvm:
	@: $(call need,PYTHON_BIN SEEDS MVM_VECTORS)
	@for s in $(SEEDS); do bash $(SIM)/run_xsim.sh --target mvm --seed $$s --mvm-vectors $(MVM_VECTORS) || exit 1; done

conv:
	@: $(call need,PYTHON_BIN SEEDS CONV_WIDTH CONV_HEIGHT)
	@for s in $(SEEDS); do bash $(SIM)/run_xsim.sh --target conv --seed $$s --conv-width $(CONV_WIDTH) --conv-height $(CONV_HEIGHT) || exit 1; done

postsim: postsim-mvm postsim-conv

postsim-mvm:
	@: $(call need,PYTHON_BIN SEEDS MVM_VECTORS PERIOD)
	@bash $(SIM)/run_postsim.sh --target mvm --seeds "$(SEEDS)" --mvm-vectors $(MVM_VECTORS) --period $(PERIOD) $(POSTSIM_ARGS)

postsim-conv:
	@: $(call need,PYTHON_BIN SEEDS CONV_WIDTH CONV_HEIGHT PERIOD)
	@bash $(SIM)/run_postsim.sh --target conv --seeds "$(SEEDS)" --conv-width $(CONV_WIDTH) --conv-height $(CONV_HEIGHT) --period $(PERIOD) $(POSTSIM_ARGS)

# Generated files only (vectors, simulation/Vivado work dirs, scratch). Sources are never touched.
clean:
	@rm -rf $(SIM)/build xsim.dir .Xil .pytest_cache
	@rm -rf $(SIM)/vectors
	@find . -name __pycache__ -type d -prune -exec rm -rf {} +
	@rm -f *.jou *.log *.pb *.wdb *.str hs_err_pid*.log