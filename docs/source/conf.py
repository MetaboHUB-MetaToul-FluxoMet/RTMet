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

# Versions used for intersphinx links
cylc_version = "8.3.0"
rose_version = "2.3.0"

# Branch of the project to use for :repofile: external links
rtmet_branch = "main"

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

# Add local sphinx extensions directory to extensions path.
sys.path.append(os.path.abspath("ext"))

extensions = [
    # core sphinx extensions
    "sphinx.ext.intersphinx",
    "sphinx.ext.extlinks",
    # community extensions
    "sphinx_design",
    "sphinx_new_tab_link",
    "sphinx_copybutton",
    # cylc.sphinx_ext extensions (from cylc.sphinx_ext-extensions library)
    "cylc.sphinx_ext.cylc_lang",
    # Custom extensions (in ext/ directory)
    "rose_lang",
    "rose_domain",
    "exec",
]

# pygments_style = "dracula"  # 🧛🏻‍♂️

templates_path = ["_templates"]
exclude_patterns = []

rst_epilog = open("substitutions.rst.include", "r").read()

intersphinx_mapping = {
    "sphinx": ("https://www.sphinx-doc.org/en/master/", None),
    "cylc": (f"https://cylc.github.io/cylc-doc/{cylc_version}/html/", None),
    "rose": (f"https://metomi.github.io/rose/{rose_version}/html/", None),
}
# See also:
# https://www.sphinx-doc.org/en/master/usage/extensions/intersphinx.html#confval-intersphinx_disabled_reftypes
intersphinx_disabled_reftypes = ["*"]

extlinks = {
    "issue": (
        "https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet/issues/%s",
        "issue %s",
    ),
    "repofile": (
        f"https://github.com/MetaboHUB-MetaToul-FluxoMet/RTMet/blob/{rtmet_branch}/%s",
        "repofile %s",
    ),
    "reporawfile": (
        f"https://raw.githubusercontent.com/MetaboHUB-MetaToul-FluxoMet/RTMet/{rtmet_branch}/%s",
        "reporawfile %s",
    ),
}

# Build CSV files snippet to use with `csv-table` directive
original_csvs = [
    "../../cylc-src/bioreactor-workflow/config/compounds_db.csv",
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

html_theme = "furo"
# html_static_path = ["_static"]
html_favicon = "_static/favicon.ico"
html_theme_options = {
    "sidebar_hide_name": True,
    "light_logo": "logo_blue.png",
    "dark_logo": "logo_white.png",
}

new_tab_link_show_external_link_icon = True
copybutton_exclude = ".linenos, .gp, .go"
copybutton_copy_empty_lines = False


def setup(app):
    app.config.html_static_path.append("_static")


# -- Options for epub output -------------------------------------------------
# disable epub mimetype warnings
suppress_warnings = ["epub.unknown_project_files"]
