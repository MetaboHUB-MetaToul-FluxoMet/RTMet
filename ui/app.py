import streamlit as st
import tkinter as tk
from tkinter import filedialog
import os
from pathlib import Path


############
# FUNCTION #
############

def get_path_netw():
    """ 
    Open a file dialog to select a network file.
    """
    # Set up tkinter
    root = tk.Tk()
    root.withdraw()

    # Make folder picker dialog appear on top of other windows
    root.wm_attributes('-topmost', 1)

    netw_directory_path = filedialog.askopenfilename(master = root,
                                                       title = "Select a network file",
                                                       filetypes=[("netw files", "*.netw")])
    st.session_state["netw_directory_path"] = netw_directory_path


def replace_in_config_file(file_path, old_string, new_string):
    """
    Overwrites a value in the ‘rose-suite.conf’ configuration file.

    :param file_path: Path to the configuration file
    :param old_string: The string to be replaced
    :param new_string: The string to replace with
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    content = content.replace(old_string, new_string)
    
    with open(file_path, 'w') as file:
        file.write(content)


#Replace with a serialization method    
def retrieve_from_config_file(file_path, string_value):
    """
    Retrieves a value from the ‘rose-suite.conf’ configuration file.

    :param file_path: Path to the configuration file
    :param string_value: The string to search for in the file

    :return: The value associated with the string in the configuration file
    """
    with open(file_path, 'r') as file:
        content = file.read()
    
    for line in content.splitlines():
        if line.startswith(string_value):
            return line.split('=')[1].strip()

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

# st.session_state.all_folder = [Path(f"{root}/{dir_name}")
#                                for root, dirs, _ in os.walk("/home/")
#                                for dir_name in dirs if dir_name.startswith("cylc-run/bioreactor-workflow")]
for root, dirs, _ in os.walk("/home/"):
    if "cylc-run" in dirs:
        if "bioreactor-workflow" in os.listdir(f"{root}/cylc-run"):
            st.session_state.cylc_workflow_path = f"{root}/cylc-run/bioreactor-workflow"
            st.session_state.all_folder = os.listdir(f"{root}/cylc-run/bioreactor-workflow")
            st.session_state.all_folder.remove("_cylc-install")
            break
        
# with open("cylc-run/bioreactor-workflow/rose-suite.conf", 'r') as file:
#     content = file.read()
#     for line in content.splitlines():
#         if line.startswith("cfg__local_runs_dir"):
#             folders_path = line.split('=')[1].strip().replace("'", "")
#             all_folder = all_folder + os.listdir(folders_path)

if "folder_selectbox" not in st.session_state:
    st.session_state.folder_selectbox = None 

folder_choice_selectbox = st.selectbox("Select a folder:", 
                                        options=st.session_state.all_folder,
                                        key="folder_choice_selectbox",
                                        index=st.session_state.all_folder.index(st.session_state.folder_selectbox) if st.session_state.folder_selectbox is not None else None,
                                        on_change=lambda: st.session_state.update({"folder_selectbox": st.session_state.folder_choice_selectbox}))

if st.session_state.folder_selectbox:
    st.session_state.cylc_workflow_path = Path(f"{st.session_state.cylc_workflow_path}/{st.session_state.folder_selectbox}")

with st.container(border=True):
    st.subheader("Configuration Parameters")
    ppm_tol = st.text_input("Enter ppm tolerance:", 
                            key="ppm_tol",)
   
    dmz_tol = st.text_input("Enter dmz tolerance:", 
                            key="dmz_tol",
                            )
    mz_list = st.text_input("Enter m/z list (comma-separated):", 
                            key="mz_list",)

    st.subheader("Database")
    col1, col2 = st.columns(2)
    with col1:
        input_button = st.button(
                label="Load a database",
                key="input_button",
                )
        if input_button:
            # Set up tkinter
            root = tk.Tk()
            root.withdraw()

            # Make folder picker dialog appear on top of other windows
            root.wm_attributes('-topmost', 1)

            db_directory_path = filedialog.askopenfilename(master = root,
                                                            title = "Select your file",
                                                            )
            # st.session_state["db_directory_path"] = db_directory_path
    with col2:
        modify_button = st.button(
                label="Change the default database",
                key="modify_button",
                )
        
        
if modify_button:
    with st.expander("Change the default database", expanded=True):
        st.write("Show default database here !!!!!")
        validate = st.button("Validate database", 
                             key="validate_db",
                             )

validate_configurations = st.button("Validate configurations", 
                                    key="validate_configurations",
                                    disabled=True if not st.session_state.get("db_directory_path") else False,)

#####################################################################################                            
# with open("cylc-src/bioreactor-workflow/rose-suite.conf", 'r') as file:
#     content = file.read()
#     for line in content.splitlines():
#         if line.startswith("cfg__local_runs_dir"):
#             folders_path = line.split('=')[1].strip().replace("'", "")
#             all_folder = all_folder + os.listdir(folders_path)

# if not st.session_state.cylc_workflow_path:
#     for root, dirs, files in os.walk("/home/"):
#         for dir_name in dirs:
#             if dir_name.startswith("cylc-run"):
#                 st.session_state.all_folder = os.listdir(f"{root}/{dir_name}/bioreactor-workflow")
#                 st.session_state.cylc_workflow_path = f"{root}/{dir_name}/bioreactor-workflow"

# if "folder_selectbox" not in st.session_state:
#     st.session_state.folder_selectbox = None 

# folder_choice_selectbox = st.selectbox("Select a folder:", 
#                                         options=st.session_state.all_folder,
#                                         key="folder_choice_selectbox",
#                                         index=st.session_state.all_folder.index(st.session_state.folder_selectbox) if st.session_state.folder_selectbox is not None else 0,
#                                         on_change=lambda: st.session_state.update({"folder_selectbox": st.session_state.folder_choice_selectbox}))

# with st.container(border=True):
#     st.subheader("Configuration Parameters")
#     st.session_state.ppm_wf_value = retrieve_from_config_file(f"{st.session_state.cylc_workflow_path}/{folder_choice_selectbox}/rose-suite.conf", "cfg__ppm_tol")
#     if "ppm_actual_value" not in st.session_state:
#         st.session_state.ppm_actual_value = None
    
#     ppm_tol = st.text_input("Enter ppm tolerance:", 
#                             key="ppm_tol",
#                             value=st.session_state.ppm_wf_value if not st.session_state.ppm_actual_value else st.session_state.ppm_actual_value,
#                             on_change=lambda: st.session_state.update({"ppm_actual_value": st.session_state.ppm_tol}))
#     st.session_state.dmz_wf_value = retrieve_from_config_file(f"{st.session_state.cylc_workflow_path}/{folder_choice_selectbox}/rose-suite.conf", "cfg__dmz_tol")
#     if "dmz_actual_value" not in st.session_state:
#         st.session_state.dmz_actual_value = None
#     dmz_tol = st.text_input("Enter dmz tolerance:", 
#                             key="dmz_tol",
#                             value=st.session_state.dmz_wf_value if not st.session_state.dmz_actual_value else st.session_state.dmz_actual_value,
#                             on_change=lambda: st.session_state.update({"dmz_actual_value": st.session_state.dmz_tol}))
#     st.session_state.mz_list_wf_value = retrieve_from_config_file(f"{st.session_state.cylc_workflow_path}/{folder_choice_selectbox}/rose-suite.conf", "cfg__custom_mz")
#     if "mz_list_actual_value" not in st.session_state:
#         st.session_state.mz_list_actual_value = None
#     mz_list = st.text_input("Enter m/z list (comma-separated):", 
#                             key="mz_list",
#                             value=st.session_state.mz_list_wf_value if not st.session_state.mz_list_actual_value else st.session_state.mz_list_actual_value,
#                             on_change=lambda: st.session_state.update({"mz_list_actual_value": st.session_state.mz_list}))
# validate = st.button("Validate parameters", key="validate_param")

# if validate:
#     if ppm_tol:
#         # Replace the parameters in the rose-suite.conf file
#         replace_in_config_file(
#             f"{st.session_state.cylc_workflow_path}/{st.session_state["folder_choice_selectbox"]}/rose-suite.conf",
#             f"cfg__ppm_tol={st.session_state.ppm_wf_value}",
#             f"cfg__ppm_tol={st.session_state.ppm_tol}")
#     if dmz_tol:
#         replace_in_config_file(
#             f"{st.session_state.cylc_workflow_path}/{st.session_state["folder_choice_selectbox"]}/rose-suite.conf",
#             f"cfg__dmz_tol={st.session_state.dmz_wf_value}",
#             f"cfg__dmz_tol={st.session_state.dmz_tol}")
#     if mz_list:
#         replace_in_config_file(
#             f"{st.session_state.cylc_workflow_path}/{folder_choice_selectbox}/rose-suite.conf",
#             f"cfg__custom_mz={st.session_state.mz_list_wf_value}",
#             f"cfg__custom_mz=[{st.session_state.mz_list}]")
#     st.success("Parameters are valid!")

# # st.write(st.session_state)
# st.subheader("Cylc GUI")

# cylc_gui = st.link_button("Go to cylc_gui", 
#                           "x")




