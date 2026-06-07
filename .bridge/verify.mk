# BRIDGE-managed. Defines verify / eval / test-slice. Safe to overwrite while
# unmodified; user edits here are preserved by bridge.sh update.
#
# Usage:
#   make verify              # run every tests/slices/*-verify.sh + *-smoke.sh
#   make eval                # run every tests/slices/*-eval.sh
#   make test-slice SLICE=Sxx  # run that slice's verify + smoke + eval
.PHONY: verify eval test-slice
verify:
	@bash tests/run-verify.sh
eval:
	@bash tests/run-eval.sh
test-slice:
	@bash tests/test-slice.sh "$(SLICE)"
