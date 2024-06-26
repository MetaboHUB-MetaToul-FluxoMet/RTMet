# pylint: skip-file
# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import os
import sys
import csv

import metomi.rose

project = "RTMet"
copyright = "2024, MetaToul"
author = "Elliot Fontaine"
release = "0.1"
version = "0.1.0"

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

# Add local sphinx extensions directory to extensions path.
sys.path.append(os.path.abspath("ext"))

extensions = [
    # cylc.sphinx_ext extensions (from cylc.sphinx_ext-extensions library)
    "cylc.sphinx_ext.cylc_lang",
    # Custom extensions (in ext/ directory)
    "rose_lang",
    "rose_domain",
    "exec",
]

templates_path = ["_templates"]
exclude_patterns = []

rst_epilog = open("substitutions.rst.include", "r").read()

# Build CSV files snippet to use with `csv-table` directive
original_csvs = [
    "../../cylc-src/bioreactor-workflow/meta/exemples/compounds_db.csv",
]
static_tables_path = "_static/tables"
os.makedirs(static_tables_path, exist_ok=True)
for csv_path in original_csvs:
    with open(csv_path, "r") as csv_file:
        csv_reader = csv.reader(csv_file)
        csv_data = list(csv_reader)
    with open(
        os.path.join(static_tables_path, os.path.basename(csv_path)), "w"
    ) as csv_file:
        csv_writer = csv.writer(csv_file)
        csv_writer.writerows(csv_data[:5])

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "sphinx_rtd_theme"
# html_static_path = ["_static"]
html_logo = "_static/logo_white.png"
html_favicon = "_static/favicon.ico"
html_theme_options = {
    "logo_only": True,
    "display_version": False,
    "style_external_links": True,
}


def setup(app):
    app.config.html_static_path.append("_static")


# -- Options for epub output -------------------------------------------------
# disable epub mimetype warnings
suppress_warnings = ["epub.unknown_project_files"]
