import streamlit as st
import tkinter as tk
from tkinter import filedialog
import os
from pathlib import Path
import shutil
import pandas as pd
import configparser
import subprocess


############
# FUNCTION #
############

def get_user_db_dir():
    """ 
    Open a file dialog to select a user database directory.
    """
    # Set up tkinter
    root = tk.Tk()
    root.withdraw()

    # Make folder picker dialog appear on top of other windows
    root.wm_attributes('-topmost', 1)

    user_db_dir = filedialog.askopenfilename(master = root,
                                                    title = "Select your file",
                                                    filetypes=[("TSV files", "*.tsv")])
    st.session_state["user_db_directory"] = Path(user_db_dir)

# def refresh_folder_list():
#     for root, dirs, _ in os.walk("/home/"):
#         if "cylc-run" in dirs:
#             if "bioreactor-workflow" in os.listdir(f"{root}/cylc-run"):
#                 st.session_state.cylc_workflow_path = f"{root}/cylc-run/bioreactor-workflow"
#                 st.session_state.all_folder = os.listdir(f"{root}/cylc-run/bioreactor-workflow")
#                 # Remove the "_cylc-install" folder if it exists (directory containing a source symlink to the source directory)
#                 st.session_state.all_folder.remove("_cylc-install")
#                 break
#     return st.session_state.all_folder

def replace_in_config_file(old_value, new_value):
    """
    Overwrites a value in the ‘rose-suite.conf’ configuration file.

    :param file_path: Path to the configuration file
    :param old_value: The string to be replaced
    :param new_value: The string to replace with
    """
    # Read the current content of the configuration file
    # Replace the old value with the new value
    with open( f"{st.session_state.cylc_workflow_path}/rose-suite.conf", 'r') as file:
        content = file.read()
    content = content.replace(old_value, new_value)

    # Write the modified content back to the configuration file
    with open( f"{st.session_state.cylc_workflow_path}/rose-suite.conf", 'w') as file:
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
for root, _, _ in os.walk("/home/"):
    workflow_path = os.path.join(root, "cylc-run", "bioreactor-workflow")
    if os.path.isdir(workflow_path):
        st.session_state.cylc_workflow_path = workflow_path
        st.session_state.all_folder = [folder for folder in os.listdir(workflow_path) if folder != "_cylc-install"]
        break   

# Storing the selected folder in the session state
if "folder_selectbox" not in st.session_state:
    st.session_state.folder_selectbox = None 


st.selectbox("Select a folder:", 
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
    st.subheader("Parameters configuration")

    st.session_state.ppm_tol = config["template variables"]["cfg__ppm_tol"] if st.session_state.folder_selectbox else None

    ppm_tol = st.text_input("ppm tolerance",
                            value=st.session_state.ppm_tol,
                            disabled= True if not st.session_state.get("folder_selectbox") else False,
                            )

    if ppm_tol != st.session_state.ppm_tol:
        st.session_state.ppm_tol = ppm_tol                        

    # st.session_state.custom_mz = config["template variables"]["cfg__custom_mz"] if st.session_state.folder_selectbox else None
    # mz_list = st.text_input("m/z list (comma-separated)", 
    #                         value=st.session_state.custom_mz,
    #                         disabled= True if not st.session_state.get("folder_selectbox") else False,
    #                         )

    # if mz_list != st.session_state.custom_mz:
    #     st.session_state.custom_mz = mz_list
    
    
    # DATABASE SECTION
    st.subheader("Database")

    if not "user_db_directory" in st.session_state:
        st.session_state["user_db_directory"] = None
    
    input_db_button = st.button(
            label="Load a database",
            # key="input_db_button",
            disabled= True if not st.session_state.get("folder_selectbox") else False,
            # disabled=True,
            # help="Database must be in .tsv format.\
                # \nMz must be in column number 5.",
            on_click=get_user_db_dir)
    
    if st.session_state["user_db_directory"]:
        database_df = pd.read_csv(st.session_state["user_db_directory"], sep="\t")
        st.dataframe(database_df, 
                     hide_index=True,
                     key="database_df")
        
        col_num_mz = st.text_input("Enter the column number for m/z",
                            width=300,
                            key="col_num_mz",
                            value=None)

        col_num_precursor = st.text_input("Enter the column number for the precursor name",
                                    width=300,
                                    key="col_num_precursor",
                                    value=None)

# QUANTIFICATION SECTION
with st.expander("Quantification"):
    st.subheader("Quantification")

    calib_curve = st.radio("'Calibration curve ?' ",
                options=["Yes","No"],
                index=None,
                horizontal=True,
                key="calib_curve")
    
    int_std_present = st.radio("Internal standard present ? ",
                options=["Yes", "No"],
                index=None,
                horizontal=True,
                key="int_std_present")

    conc_is = st.radio("Is the concentration of the internal standard known ?",
                options=["Yes", "No"],
                index=None,
                horizontal=True,
                key="conc_is")

    if int_std_present == "Yes":
        st.selectbox("Select IS: ",
                     options=st.session_state["database_df"].iloc[:, int(st.session_state["col_num_precursor"])],
                     key="is_selectbox")

launch_workflow, visualize_workflow = st.columns(2)
with launch_workflow:
    start_workflow = st.button("Start workflow", 
                                key="start_workflow",
                                disabled= True if not st.session_state.get("folder_selectbox") else False)

with visualize_workflow:
    cylc_gui = st.link_button("Visualize workflow",
                              "x")
st.session_state.new_path_db = config["template variables"]["cfg__database_path"] if st.session_state.folder_selectbox else None

if st.session_state.start_workflow:
    st.session_state.new_path_db = f"{st.session_state.cylc_workflow_path}/config/{st.session_state["user_db_directory"].name}"
    shutil.copy(st.session_state["user_db_directory"], 
                st.session_state.new_path_db )
    if ppm_tol:
        replace_in_config_file(
            f"cfg__ppm_tol={config['template variables']['cfg__ppm_tol']}",
            f"cfg__ppm_tol={st.session_state.ppm_tol}")
        
    replace_in_config_file(
        f"cfg__database_path={config['template variables']['cfg__database_path']}",
        f"cfg__database_path={st.session_state.new_path_db}")
    
    replace_in_config_file(
        f"cfg__num_col_mz={config['template variables']['cfg__num_col_mz']}",
        f"cfg__num_col_mz={st.session_state.col_num_mz}")
    
    replace_in_config_file(
        f"cfg__num_col_precursor_name={config['template variables']['cfg__num_col_precursor_name']}",
        f"cfg__num_col_precursor_name={st.session_state.col_num_precursor}")

    # subprocess.Popen(["cylc", "play", f"bioreactor-workflow/{st.session_state.folder_selectbox}"])


st.write(st.session_state)
#####################################################################################   
#     os.remove(f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv")
#     os.rename(os.listdir(f"{st.session_state.cylc_workflow_path}/config/"), f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv")
# new_db.to_csv(f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv", 
#               sep="\t", 
#               index=False)

                         






