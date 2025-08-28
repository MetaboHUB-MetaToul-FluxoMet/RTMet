import streamlit as st
import tkinter as tk
from tkinter import filedialog
import os
from pathlib import Path
# import shutil
import pandas as pd
import configparser


############
# FUNCTION #
############

# def get_user_db_dir():
#     """ 
#     Open a file dialog to select a user database directory.
#     """
#     # Set up tkinter
#     root = tk.Tk()
#     root.withdraw()

#     # Make folder picker dialog appear on top of other windows
#     root.wm_attributes('-topmost', 1)

#     user_db_dir = filedialog.askopenfilename(master = root,
#                                                     title = "Select your file",
#                                                     filetypes=[("TSV files", "*.tsv")])
#     st.session_state["user_db_directory"] = user_db_dir

def replace_in_config_file(file_path, old_value, new_value):
    """
    Overwrites a value in the ‘rose-suite.conf’ configuration file.

    :param file_path: Path to the configuration file
    :param old_value: The string to be replaced
    :param new_value: The string to replace with
    """
    # Read the current content of the configuration file
    # Replace the old value with the new value
    with open(file_path, 'r') as file:
        content = file.read()
    content = content.replace(old_value, new_value)

    # Write the modified content back to the configuration file
    with open(file_path, 'w') as file:
        content = content.replace(old_value, new_value)
        file.write(content)
   
########
# MAIN #
########

st.set_page_config(page_title=f"RT-MET", layout="centered")
st.title(f"Welcome to RT-MET")
st.write(" ")

# Storing the path to the ‘cylc-run’ workflow
if "cylc_workflow_path" not in st.session_state:
    st.session_state.cylc_workflow_path = ""

# Storing the list of folders in the ‘cylc-run’ workflow
if "all_folder" not in st.session_state:
    st.session_state.all_folder = []

# Searching for the ‘cylc-run’ workflow in the home directory
for root, dirs, _ in os.walk("/home/"):
    if "cylc-run" in dirs:
        if "bioreactor-workflow" in os.listdir(f"{root}/cylc-run"):
            st.session_state.cylc_workflow_path = f"{root}/cylc-run/bioreactor-workflow"
            st.session_state.all_folder = os.listdir(f"{root}/cylc-run/bioreactor-workflow")
            # Remove the "_cylc-install" folder if it exists (directory containing a source symlink to the source directory)
            st.session_state.all_folder.remove("_cylc-install")
            break

# Storing the selected folder in the session state
if "folder_selectbox" not in st.session_state:
    st.session_state.folder_selectbox = None 

folder_choice_selectbox = st.selectbox("Select a folder:", 
                                        options=st.session_state.all_folder,
                                        key="folder_choice_selectbox",
                                        index=st.session_state.all_folder.index(st.session_state.folder_selectbox) if st.session_state.folder_selectbox is not None else None,
                                        on_change=lambda: st.session_state.update({"folder_selectbox": st.session_state.folder_choice_selectbox}))

# Update the workflow path and read the configuration file
if st.session_state.folder_selectbox:
    st.session_state.cylc_workflow_path = Path(f"{st.session_state.cylc_workflow_path}/{st.session_state.folder_selectbox}")
    config = configparser.ConfigParser(allow_unnamed_section=True)
    config.read(f"{st.session_state.cylc_workflow_path}/rose-suite.conf")

# Settings configuration and database
with st.container(border=True):
    st.subheader("Configuration Parameters")

    st.session_state.ppm_tol_file = config["template variables"]["cfg__ppm_tol"] if st.session_state.folder_selectbox else None
    if "ppm_new_tol" not in st.session_state:
        st.session_state.ppm_new_tol = None

    ppm_tol = st.text_input("ppm tolerance",
                            value=st.session_state.ppm_tol_file if not st.session_state.ppm_new_tol else st.session_state.ppm_new_tol,
                            help="ppm tolerance must not exceed 15",
                            disabled= True if not st.session_state.get("folder_selectbox") else False)
                            
    st.session_state.ppm_new_tol = ppm_tol 

    st.session_state.dmz_tol_file = config["template variables"]["cfg__dmz_tol"] if st.session_state.folder_selectbox else None
    if "dmz_new_tol" not in st.session_state:
        st.session_state.dmz_new_tol = None
   
    dmz_tol = st.text_input("dmz tolerance", 
                            value=st.session_state.dmz_tol_file if not st.session_state.dmz_new_tol else st.session_state.dmz_new_tol,
                            disabled= True if not st.session_state.get("folder_selectbox") else False)
                            
    st.session_state.dmz_new_tol = dmz_tol

    st.session_state.custom_mz_file = config["template variables"]["cfg__custom_mz"] if st.session_state.folder_selectbox else None
    if "custom_mz_new" not in st.session_state:
        st.session_state.custom_mz_new = None

    mz_list = st.text_input("m/z list (comma-separated)", 
                            value=st.session_state.custom_mz_file if not st.session_state.custom_mz_new else st.session_state.custom_mz_new,
                            disabled= True if not st.session_state.get("folder_selectbox") else False,
                            )
    st.session_state.custom_mz_new = mz_list

# Load a database or modify the database
    st.subheader("Database")
    load_database, database_modification  = st.columns(2)
    if st.session_state.folder_selectbox:
        default_db = pd.read_csv(f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv", sep="\t")
        st.session_state.default_db = default_db

    st.session_state.edited_db = None

    with load_database:
        input_button = st.button(
                label="Load a database",
                key="input_button",
                # disabled= True if not st.session_state.get("folder_selectbox") else False,
                disabled=True,
                help="Database must be in .tsv format.\
                    \nMz must be in column number 5.")
                # on_click=get_user_db_dir)
            
    with database_modification :
        if "modify_button" not in st.session_state:
            st.session_state.modify_button = False

        modify_button = st.button(
                label="Edit the default database",
                disabled= True if not st.session_state.get("folder_selectbox") else False,
                on_click=lambda: st.session_state.update({"modify_button": True}),)

if st.session_state.modify_button:
    with st.expander("Change the default database", expanded=True):
        db_editor = st.data_editor(st.session_state.default_db,
                hide_index=True,
                num_rows= "dynamic",)
        st.session_state.edited_db = db_editor
        
        validate_db = st.button("Validate database", 
                                key="validate_db",)    
        if st.session_state.validate_db:
            if db_editor is not None:
                st.success("Database updated successfully!")
            else:
                st.error("Database cannot be empty!")

# if st.session_state.get("db_directory_path"):
#     st.success(f"Database loaded: {st.session_state.db_directory_path}")
#     shutil.copy(st.session_state.db_directory_path, f"{st.session_state.cylc_workflow_path}/config/")
    
validate_configurations = st.button("Validate configurations", 
                                    key="validate_configurations",
                                    disabled= True if not st.session_state.get("folder_selectbox") else False,)
if st.session_state.validate_configurations:
    if st.session_state.edited_db is not None:
        st.session_state.edited_db.to_csv(f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv", 
                                                        sep="\t", 
                                                        index=False)
    if ppm_tol:
        replace_in_config_file(
            f"{st.session_state.cylc_workflow_path}/rose-suite.conf",
            f"cfg__ppm_tol={config['template variables']['cfg__ppm_tol']}",
            f"cfg__ppm_tol={st.session_state.ppm_new_tol}")
    
    if dmz_tol:
        replace_in_config_file(
            f"{st.session_state.cylc_workflow_path}/rose-suite.conf",
            f"cfg__dmz_tol={config['template variables']['cfg__dmz_tol']}",
            f"cfg__dmz_tol={st.session_state.dmz_new_tol}")
        
    if mz_list:
        replace_in_config_file(
            f"{st.session_state.cylc_workflow_path}/rose-suite.conf",
            f"cfg__custom_mz={config['template variables']['cfg__custom_mz']}",
            f"cfg__custom_mz={st.session_state.custom_mz_new}")

cylc_gui = st.link_button("Go to cylc_gui", 
                          "x")

# st.write(st.session_state)
#####################################################################################   
#     os.remove(f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv")
#     os.rename(os.listdir(f"{st.session_state.cylc_workflow_path}/config/"), f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv")
# new_db.to_csv(f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv", 
#               sep="\t", 
#               index=False)

                         






