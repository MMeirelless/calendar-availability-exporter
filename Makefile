.PHONY: install lint format test clean run help

PYTHON ?= python3
PIP    ?= pip

help:
	@echo "Targets:"
	@echo "  install   Editable install with dev dependencies"
	@echo "  lint      Run ruff check"
	@echo "  format    Run ruff format"
	@echo "  test      Run pytest"
	@echo "  run       Run with example arguments (current week)"
	@echo "  clean     Remove caches and build artifacts"

install:
	$(PIP) install -e ".[dev]"

lint:
	ruff check src tests

format:
	ruff format src tests
	ruff check --fix src tests

test:
	pytest

run:
	$(PYTHON) -m calendar_availability \
		--start $$(date -v-Mon +%Y-%m-%d) \
		--end   $$(date -v-Mon -v+4d +%Y-%m-%d) \
		--day-start 09:00 \
		--day-end   20:00 \
		--lunch     12:00-14:00 \
		--output    availability.png

clean:
	rm -rf build dist *.egg-info
	rm -rf .pytest_cache .ruff_cache
	find . -type d -name __pycache__ -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
