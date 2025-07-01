import streamlit as st
import subprocess
import os

############
# FUNCTION #
############

def replace_in_file(file_path, old_string, new_string):
    with open(file_path, 'r') as file:
        content = file.read()
    
    content = content.replace(old_string, new_string)
    
    with open(file_path, 'w') as file:
        file.write(content)
    
def retrieve_from_file(file_path, key):
    with open(file_path, 'r') as file:
        content = file.read()
    # Assuming the content is in a key-value format
    for line in content.splitlines():
        if line.startswith(key):
            return line.split('=')[1].strip()
    return None


########
# MAIN #
########

st.set_page_config(page_title=f"RT-MET")
st.title(f"Welcome to RT-MET")

CYLC_WORKFLOW = "bioreactor-workflow"

all_folder = []
with open("cylc-src/bioreactor-workflow/rose-suite.conf", 'r') as file:
    content = file.read()
    for line in content.splitlines():
        if line.startswith("cfg__local_runs_dir"):
            folders_path = line.split('=')[1].strip().replace("'", "")
            all_folder = all_folder + os.listdir(folders_path)
folder_choice = st.selectbox("Select a folder to work with:", 
                            key="folder_choice_selectbox",
                            options=all_folder)

with st.container(border=True):
    old_ppm_tol = retrieve_from_file("cylc-src/bioreactor-workflow/rose-suite.conf", "cfg__ppm_tol")
    ppm_tol = st.text_input("Enter ppm tolerance:", 
                            key="ppm_tol",
                            value=8)
    old_dmz_tol = retrieve_from_file("cylc-src/bioreactor-workflow/rose-suite.conf", "cfg__dmz_tol")
    dmz_tol = st.text_input("Enter dmz tolerance:", 
                            key="dmz_tol",
                            value=0.001)
    old_mz_list = retrieve_from_file("cylc-src/bioreactor-workflow/rose-suite.conf", "cfg__custom_mz")
    mz_list = st.text_input("Enter m/z list (comma-separated):", 
                            key="mz_list",
                            value="179.05611")

validate = st.button("Validate parameters", key="validate_param")

if validate:
    if ppm_tol:
        st.success("Parameters are valid!")
        # Replace the parameters in the rose-suite.conf file
        replace_in_file(
            "cylc-src/bioreactor-workflow/rose-suite.conf",
            f"cfg__ppm_tol={old_ppm_tol}",
            f"cfg__ppm_tol={ppm_tol}")
    if dmz_tol:
        replace_in_file(
            "cylc-src/bioreactor-workflow/rose-suite.conf",
            f"cfg__dmz_tol={old_dmz_tol}",
            f"cfg__dmz_tol={dmz_tol}")
    if mz_list:
        replace_in_file(
            "cylc-src/bioreactor-workflow/rose-suite.conf",
            f"cfg__custom_mz={old_mz_list}",
            f"cfg__custom_mz=[{mz_list}]")
    
    subprocess.Popen(["cylc", "play", f"{CYLC_WORKFLOW}/{folder_choice}"])

cylc_gui = st.link_button("Go to cylc_gui", 
                          "http://10.10.100.21:8000/")




