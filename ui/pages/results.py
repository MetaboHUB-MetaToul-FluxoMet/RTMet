import streamlit as st
# import time
# import pickle
import plotly.express as px
import pandas as pd
import os
import subprocess
# from pathlib import Path

############
# FUNCTION #
############

# def save_process_to_file(dictionary, output_folder_dir):
#     """
#     Save the Process object to a pickle file in the model directory.
#     """
        
#     output_file_tmp = Path(output_folder_dir) / "metabolites_tmp.pkl"
#     output_file = Path(output_folder_dir) / "metabolites.pkl"

#     try:
#         with open(output_file_tmp, 'wb') as file:
#             pickle.dump(dictionary, file)
#         output_file.unlink(missing_ok=True)
#         output_file_tmp.rename(output_file)
#     except Exception as e:
#         raise ValueError(f"An unknown error has occured when saving the process file: {e}")

def session_state_checkbox(metabolite):
    """
    Function to check if a key exists in the session state and set its value.

    :param metabolite: The name of the metabolite to check
    """
    if metabolite not in st.session_state.metabolite_checkbox:
        st.session_state.metabolite_checkbox[metabolite] = True
    else:
        st.session_state.metabolite_checkbox[metabolite] = not st.session_state.metabolite_checkbox[metabolite]

def highlight_identified_metabolites(row):
    """
    Highlight rows in a DataFrame based on whether the 'Precursor Name' 
    exists in the session state's met_dict keys.

    :param row: The DataFrame row to check
    """
    return ['background-color: lightgreen' if row['Precursor Name'] in st.session_state.met_dict.keys() 
            else 'background-color: lightcoral' for _ in row]

########
# MAIN #
########


st.set_page_config(page_title=f"RT-MET", layout="wide")
st.title(f"Results")

if "met_dict" not in st.session_state:
    st.session_state.met_dict = {}

if "metabolite_checkbox" not in st.session_state:
    st.session_state.metabolite_checkbox = {}

with st.sidebar:
    visualize_workflow = st.button("Visualize workflow")
    


st.write(" ")
info, workflow_control = st.columns(2)
with info:
    st.info(f"Number of files processed : {len(os.listdir(f"{st.session_state.cylc_workflow_path}/share/cycle"))}",
            width=300)
    refresh = st.button("Refresh",
        key="refresh_metabolites")

    if refresh:
        st.rerun()


with workflow_control:
    with st.expander("Workflow control", expanded=True):
        with st.container(border=False, height=200):
            command_line = subprocess.run(["cylc", "workflow-state", f"bioreactor-workflow/{st.session_state.folder_selectbox}"], 
                                          capture_output=True,
                                          text=True)
            outputs_list = command_line.stdout.split("\n")
            for output in outputs_list:
                # if "succeeded" in output:
                #     st.success(output)
                if "failed" in output:
                    st.error(output)
                # else:
                #     st.info(output)


# Store metabolites and their different values
dataframe=pd.read_csv(f"{st.session_state.cylc_workflow_path}/share/data/all_features.tsv", sep="\t")
for metabolite in dataframe["Precursor Name"].unique():
    st.session_state.met_dict[metabolite] = {"datetime": dataframe["Datetime"].loc[dataframe["Precursor Name"] == metabolite].tolist(),
                            "intensity": dataframe["Intensity"].loc[dataframe["Precursor Name"] == metabolite].tolist(),
                            "mz": dataframe["MzQuery"].loc[dataframe["Precursor Name"] == metabolite].tolist()}

metabolite_selection, db_display = st.columns(2)

with metabolite_selection:
    # Metabolite selection container 
    with st.container(border=True, height=450,key="metabolite_selection_container"):
        st.subheader("Metabolites")
        for metabolite, values in sorted(st.session_state['met_dict'].items()):
            metabolite_selection = st.checkbox(metabolite, 
                                                # key=metabolite, 
                                                value=False if metabolite not in st.session_state.metabolite_checkbox else st.session_state.metabolite_checkbox[metabolite],
                                                on_change=session_state_checkbox,
                                                args=(metabolite,)
                                                )
with db_display:
    with st.expander("Show database", expanded=True):
        db_style = st.session_state.edited_db.style.apply(highlight_identified_metabolites, axis=1) \
            if st.session_state.edited_db is not None \
            else st.session_state.default_db.style.apply(highlight_identified_metabolites, axis=1)
        st.dataframe(db_style, use_container_width=True, hide_index=True)

# Display results based on metabolite selection
if st.session_state.metabolite_checkbox:
    # st.subheader("Results")
    for selected_metabolite in st.session_state.metabolite_checkbox:
        if st.session_state.metabolite_checkbox[selected_metabolite]:
            st.divider()
            st.subheader(f"{selected_metabolite}")

            caracteristics, graph  = st.columns(2)
            df = pd.DataFrame({
                    "Datetime": st.session_state.met_dict[selected_metabolite]["datetime"],
                    "Intensity": st.session_state.met_dict[selected_metabolite]["intensity"]
                })
            
            with caracteristics:
                operations,show_df = st.columns(2)
                with operations:
                    # st.subheader(" ")
                    st.write(" ")
                    operation = ["Relative quantification"]
                    st.selectbox("Select an operation:", 
                                # index=None,
                                key=f"operation_{selected_metabolite}",
                                options=operation)
                with show_df:
                    st.dataframe(df, use_container_width=True, hide_index=True)
                
            with graph:
                fig = px.line(df, 
                              x="Datetime",
                              y="Intensity",
                              title=f"{selected_metabolite} Intensity Over Time")
                st.plotly_chart(fig, use_container_width=False)
                
            
# while True:
#     if not Path("/home/kouakou/cylc-run/bioreactor-workflow/data_test_2/results/all_features.tsv").exists():
#         st.error("Results file not found. Please run the workflow to generate results.")
#         break
#     else:
#         if "met_dict" not in st.session_state:
#             st.session_state.met_dict = {}
#         if "metabolite_checkbox" not in st.session_state:
#             st.session_state.metabolite_checkbox = {}

#         dataframe=pd.read_csv("/home/kouakou/cylc-run/bioreactor-workflow/data_test_2/results/all_features.tsv", sep="\t")
        
#         for metabolite in dataframe["Precursor Name"].unique():
#             st.session_state.met_dict[metabolite] = {"datetime": dataframe["Datetime"].loc[dataframe["Precursor Name"] == metabolite].tolist(),
#                                     "intensity": dataframe["Intensity"].loc[dataframe["Precursor Name"] == metabolite].tolist(),
#                                     "mz": dataframe["MzQuery"].loc[dataframe["Precursor Name"] == metabolite].tolist()}

#         with st.container(border=True, height=400,key="metabolite_selection_container"):
#             st.subheader("Metabolites")
#             for metabolite, values in st.session_state['met_dict'].items():
#                 metabolite_selection = st.checkbox(metabolite, 
#                                                     # key=metabolite, 
#                                                     value=False if metabolite not in st.session_state.metabolite_checkbox else st.session_state.metabolite_checkbox[metabolite],
#                                                     on_change=session_state_checkbox,
#                                                     args=(metabolite,)
#                                                     )

#             if st.session_state.metabolite_checkbox:
#                 st.subheader("Results")
#                 for i in st.session_state.metabolite_checkbox:
#                     if st.session_state.metabolite_checkbox[i]:
#                         graph, caracteristics = st.columns(2)
#                         df = pd.DataFrame({
#                                 "Datetime": st.session_state.met_dict[i]["datetime"],
#                                 "Intensity": st.session_state.met_dict[i]["intensity"]
#                             })
#                         with graph:
#                             fig = px.line(df, x="Datetime", y="Intensity", title=f"{i} Intensity Over Time")
#                             st.plotly_chart(fig, use_container_width=True)
                            
#                         with caracteristics:
#                             show_df, operations = st.columns(2)
#                             with show_df:
#                                 st.subheader("Dataframe")
#                                 st.dataframe(df, use_container_width=True, hide_index=True)
#                             with operations:
#                                 st.subheader("Operations")
#                                 operation = ["area"]
#                                 st.selectbox("Select an operation:", 
#                                             key=f"operation_{i}",
#                                             options=operation)
#                     # st.write(df)
#                     time.sleep(20)
#                     break
# st.write(st.session_state.met_dict)           
    
    
# with open("/home/kouakou/Documents/metabolites.pkl", "rb") as f:
#     get_results = pickle.load(f)
# st.write(st.session_state.cylc_workflow_path)

# met_dict = {}
