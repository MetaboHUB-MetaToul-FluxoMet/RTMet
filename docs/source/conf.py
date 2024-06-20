# pylint: skip-file
# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

import os
import sys

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
    # Custom extensions (in ext/ directory) made for Rose (MET Office)
    "rose_lang",
    "rose_domain",
]
# extensions = ["cylc.sphinx_ext.cylc_lang"]

templates_path = ["_templates"]
exclude_patterns = []


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = "sphinx_rtd_theme"
# html_static_path = ["_static"]
html_logo = "_static/logo_white.png"
html_theme_options = {
    "logo_only": True,
    "display_version": False,
    "style_external_links": True,
}


def setup(app):
    app.config.html_static_path.append("_static")
