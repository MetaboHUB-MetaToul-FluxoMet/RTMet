import streamlit as st
# import tkinter as tk
# from tkinter import filedialog
import os
from pathlib import Path
# import shutil
import pandas as pd
import configparser
import subprocess


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
    st.subheader("Parameters configuration")

    st.session_state.ppm_tol = config["template variables"]["cfg__ppm_tol"] if st.session_state.folder_selectbox else None

    ppm_tol = st.text_input("ppm tolerance",
                            value=st.session_state.ppm_tol,
                            help="ppm tolerance must not exceed 15",
                            disabled= True if not st.session_state.get("folder_selectbox") else False,
                            )

    if ppm_tol != st.session_state.ppm_tol:
        st.session_state.ppm_tol = ppm_tol                        

    st.session_state.dmz_tol = config["template variables"]["cfg__dmz_tol"] if st.session_state.folder_selectbox else None
    
    dmz_tol = st.text_input("dmz tolerance", 
                            value=st.session_state.dmz_tol,
                            disabled= True if not st.session_state.get("folder_selectbox") else False)

    if dmz_tol != st.session_state.dmz_tol:
        st.session_state.dmz_tol = dmz_tol

    st.session_state.custom_mz = config["template variables"]["cfg__custom_mz"] if st.session_state.folder_selectbox else None

    mz_list = st.text_input("m/z list (comma-separated)", 
                            value=st.session_state.custom_mz,
                            disabled= True if not st.session_state.get("folder_selectbox") else False,
                            )

    if mz_list != st.session_state.custom_mz:
        st.session_state.custom_mz = mz_list

# Load a database or modify the database
# with st.container(border=True):
    st.subheader("Database")
    # load_database, database_modification  = st.columns(2)
    if st.session_state.folder_selectbox:
        default_db = pd.read_csv(f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv", sep="\t")
        st.session_state.default_db = default_db

    st.session_state.edited_db = None
    
    if "database_choice_user" not in st.session_state:
        st.session_state.database_choice_user = None

    database_choice_list = ["Load a database", "Edit the default database"]

    database_choice = st.radio(
        label="Database options",
        options=database_choice_list,
        index=database_choice_list.index(st.session_state.database_choice_user) if st.session_state.get("database_choice_user") else None,
        disabled= True if not st.session_state.get("folder_selectbox") else False,
        # horizontal=True,
        key="database_choice",
        label_visibility="collapsed",
        on_change=lambda: st.session_state.update({"database_choice_user": st.session_state.database_choice}))
    
if st.session_state.database_choice == database_choice_list[0]:
    with st.expander("Load", expanded=True):
        input_db_button = st.file_uploader(
                    label="Load a database",
                    type=["tsv"],
                    disabled= True if not st.session_state.get("folder_selectbox") else False,
                    help="Database must be in .tsv format.\
                        \nMz must be in column number 5.",)
                    # key="input_db_button",)
        
        col_num_mz = st.text_input("Enter number of mz column in the database",
                                    width=300,
                                    key="col_num_mz",)
        
        col_num_precursor = st.text_input("Enter number of precursor name column in the database",
                                    width=300,
                                    key="col_num_precursor",)

if st.session_state.database_choice == database_choice_list[1]:
    with st.expander("Change the default database", expanded=True):
        db_editor = st.data_editor(st.session_state.default_db,
                                    hide_index=True,
                                    num_rows= "dynamic")
        st.session_state.edited_db = db_editor
        
        validate_db = st.button("Validate database", 
                                key="validate_db",)    
        if st.session_state.validate_db:
            if db_editor is not None:
                st.success("Database updated successfully!")
            else:
                st.error("Database cannot be empty!")
    # st.session_state.database_choice = database_choice
    # with load_database:
        # if "input_db_button" not in st.session_state:
        #     st.session_state.input_db_button = False
        
        # input_db_button = st.button(
        #         label="Load a database",
        #         # key="input_db_button",
        #         disabled= True if not st.session_state.get("folder_selectbox") else False,
        #         # disabled=True,
        #         # help="Database must be in .tsv format.\
        #             # \nMz must be in column number 5.",
        #         on_click=lambda: st.session_state.update({"input_db_button": True}))
        
        # input_db_button = st.file_uploader(
        #         label="Load a database",
        #         type=["tsv"],
        #         disabled= True if not st.session_state.get("folder_selectbox") else False,
        #         help="Database must be in .tsv format.\
        #             \nMz must be in column number 5.",)
                # key="input_db_button",)
    
#     with database_modification :
#         # if "modify_button" not in st.session_state:
#         #     st.session_state.modify_button = False

#         # modify_button = st.button(
#         #         label="Edit the default database",
#         #         disabled= True if not st.session_state.get("folder_selectbox") else False,
#         #         on_click=lambda: st.session_state.update({"modify_button": True}),)
#         modify_radio_button = st.radio(
#                 label="Edit the default database",
#                 options=["Load a database", "Edit the default database"],
#                 index=0,
#                 horizontal=True,
#                 disabled= True if not st.session_state.get("folder_selectbox") else False,
#                 on_change=lambda: st.session_state.update({"modify_button": True if st.session_state.modify_radio_button == "Yes" else False}),)

# if st.session_state.input_db_button:
#         with st.expander("Instructions to load a database", expanded=True):
#             st.file_uploader(
#                 label="Load a database",
#                 type=["tsv"],
#                 disabled= True if not st.session_state.get("folder_selectbox") else False,
#                 )
#             st.text_input("Enter number of mz column in the database",
#                           width=300)
#             # st.write("yes")

# if st.session_state.modify_button:
#     with st.expander("Change the default database", expanded=True):
#         db_editor = st.data_editor(st.session_state.default_db,
#                                     hide_index=True,
#                                     num_rows= "dynamic")
#         st.session_state.edited_db = db_editor
        
#         validate_db = st.button("Validate database", 
#                                 key="validate_db",)    
#         if st.session_state.validate_db:
#             if db_editor is not None:
#                 st.success("Database updated successfully!")
#             else:
#                 st.error("Database cannot be empty!")


# if st.session_state.get("db_directory_path"):
#     st.success(f"Database loaded: {st.session_state.db_directory_path}")
#     shutil.copy(st.session_state.db_directory_path, f"{st.session_state.cylc_workflow_path}/config/")


launch_workflow, visualize_workflow = st.columns(2)
with launch_workflow:
    start_workflow = st.button("Start workflow", 
                                key="start_workflow",
                                disabled= True if not st.session_state.get("folder_selectbox") else False)

with visualize_workflow:
    cylc_gui = st.link_button("Visualize workflow",
                              "x")
    
if st.session_state.start_workflow:
    if st.session_state.edited_db is not None:
        st.session_state.edited_db.to_csv(f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv", 
                                          sep="\t",
                                          index=False)
    if ppm_tol:
        replace_in_config_file(
            f"cfg__ppm_tol={config['template variables']['cfg__ppm_tol']}",
            f"cfg__ppm_tol={st.session_state.ppm_tol}")
        
    if dmz_tol:
        replace_in_config_file(
            f"cfg__dmz_tol={config['template variables']['cfg__dmz_tol']}",
            f"cfg__dmz_tol={st.session_state.dmz_tol}")
        
    if mz_list:
        replace_in_config_file(
            f"cfg__custom_mz={config['template variables']['cfg__custom_mz']}",
            f"cfg__custom_mz={st.session_state.custom_mz}")

    if st.session_state.database_choice == database_choice_list[0]:
        replace_in_config_file(
            f"cfg__num_col_mz={config['template variables']['cfg__num_col_mz']}",
            f"cfg__num_col_mz={st.session_state.col_num_mz}")
        
        replace_in_config_file(
            f"cfg__num_col_precursor_name={config['template variables']['cfg__num_col_precursor_name']}",
            f"cfg__num_col_precursor_name={st.session_state.col_num_precursor}")

    # subprocess.Popen(["cylc", "play", f"bioreactor-workflow/{st.session_state.folder_selectbox}"])


# st.write(st.session_state)
#####################################################################################   
#     os.remove(f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv")
#     os.rename(os.listdir(f"{st.session_state.cylc_workflow_path}/config/"), f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv")
# new_db.to_csv(f"{st.session_state.cylc_workflow_path}/config/compounds_db.tsv", 
#               sep="\t", 
#               index=False)

                         






