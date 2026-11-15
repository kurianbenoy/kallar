.PHONY: help venv kallar multiscript test proofs specimen serve clean distclean \
	pdf pdf-multiscript qa qa-multiscript

PY := .venv/bin/python
PIP := .venv/bin/pip

help:
	@echo "targets:"
	@echo "  venv      create .venv and install build/proof dependencies"
	@echo "  kallar    build the variable Kallar family + Spectrum"
	@echo "  multiscript build Devanagari, Tamil, Telugu and Kannada families"
	@echo "  test      run shaping, variation and colour tests"
	@echo "  proofs    render the specimen PNGs and the HTML specimen"
	@echo "  pdf       print the specimen to proofs/Kallar-Specimen.pdf"
	@echo "  pdf-multiscript print the multiscript specimen to PDF"
	@echo "  qa        run fontbakery on the Malayalam Regular and Bold"
	@echo "  qa-multiscript run fontbakery on the four script families"
	@echo "  specimen  alias for proofs"
	@echo "  serve     serve specimen/ on http://localhost:8000"
	@echo "  clean     remove generated masters"
	@echo "  distclean remove generated fonts and proofs too"

venv:
	test -d .venv || { python3 -m venv .venv; $(PIP) install -U pip; }
	$(PIP) install -q fonttools uharfbuzz freetype-py pillow numpy Brotli scipy

kallar: venv
	$(PY) tools/kallar.py all

multiscript: venv
	$(PY) tools/multiscript.py

test: venv kallar multiscript
	$(PY) tests/test_kallar.py
	$(PY) tests/test_multiscript.py

proofs: kallar multiscript
	$(PY) tools/specimen.py
	$(PY) tools/specimen_multiscript.py
	$(PY) tools/specimen_html.py
	$(PY) tools/specimen_multiscript_html.py

pdf: proofs
	$(PIP) install -q playwright
	$(PY) -m playwright install chromium
	$(PY) tools/pdf.py

pdf-multiscript: proofs
	$(PIP) install -q playwright
	$(PY) -m playwright install chromium
	$(PY) tools/pdf.py specimen/multiscript.html \
		proofs/Kallar-Multiscript-Specimen.pdf

qa: kallar
	$(PIP) install -q fontbakery
	$(PY) -m fontbakery check-universal fonts/Kallar-Regular.ttf \
		--no-progress -x opentype/fvar/regular_coords_correct -x alt_caron
	$(PY) -m fontbakery check-universal fonts/Kallar-Bold.ttf \
		--no-progress -x opentype/fvar/regular_coords_correct -x alt_caron \
		-x opentype/fsselection -x opentype/mac_style

qa-multiscript: multiscript
	$(PIP) install -q fontbakery
	@for f in \
		fonts/KallarDevanagari-Regular.ttf \
		fonts/KallarDevanagari-Bold.ttf \
		fonts/KallarTamil-Regular.ttf \
		fonts/KallarTamil-Bold.ttf \
		fonts/KallarTelugu-Regular.ttf \
		fonts/KallarTelugu-Bold.ttf \
		fonts/KallarKannada-Regular.ttf \
		fonts/KallarKannada-Bold.ttf; do \
		echo "== $$f"; \
		$(PY) -m fontbakery check-universal "$$f" --no-progress \
			-x opentype/fvar/regular_coords_correct -x alt_caron \
			-x opentype/fsselection -x opentype/mac_style \
			2>&1 | grep -E '^    (FAIL|WARN|PASS):|^Total:' | tail -5; \
	done

specimen: proofs
	@echo "open specimen/index.html in a browser (or run: make serve)"

serve: specimen
	$(PY) -m http.server 8000 --directory specimen

clean:
	rm -rf sources/masters

distclean: clean
	rm -rf fonts/*.ttf fonts/*.otf fonts/*.woff2 proofs/kallar_*.png \
		proofs/Kallar-Specimen.pdf \
		proofs/Kallar-Multiscript-Specimen.pdf
