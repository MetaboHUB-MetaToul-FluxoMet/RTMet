import streamlit as st
import time
# import pickle
import plotly.express as px
import pandas as pd
from pathlib import Path

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

# def get_metabolites(path):
#     """
#     """
#     return pd.read_csv(path, sep="\t")
    # for metabolite in dataframe["Precursor Name"].sort_values().unique():
    #     st.session_state.met_dict[metabolite] = {"datetime": dataframe["Datetime"].loc[dataframe["Precursor Name"] == metabolite].tolist(),
    #                             "intensity": dataframe["Intensity"].loc[dataframe["Precursor Name"] == metabolite].tolist(),
    #                             "mz": dataframe["MzQuery"].loc[dataframe["Precursor Name"] == metabolite].tolist()}
   

def session_state_checkbox(metabolites):
    """
    Function to check if a key exists in the session state and set its value.
    """
    if metabolites not in st.session_state.metabolite_checkbox:
        st.session_state.metabolite_checkbox[metabolites] = True
    else:
        st.session_state.metabolite_checkbox[metabolites] = not st.session_state.metabolite_checkbox[metabolites]


########
# MAIN #
########


st.set_page_config(page_title=f"RT-MET", layout="wide")
st.title(f"Results")

if "met_dict" not in st.session_state:
    st.session_state.met_dict = {}

if "metabolite_checkbox" not in st.session_state:
    st.session_state.metabolite_checkbox = {}

actualize = st.button("Actualize",
          key="actualize_metabolites")

if actualize:
    st.rerun()

dataframe=pd.read_csv(f"{st.session_state.cylc_workflow_path}/results/all_features.tsv", sep="\t")
for metabolite in dataframe["Precursor Name"].sort_values().unique():
    st.session_state.met_dict[metabolite] = {"datetime": dataframe["Datetime"].loc[dataframe["Precursor Name"] == metabolite].tolist(),
                            "intensity": dataframe["Intensity"].loc[dataframe["Precursor Name"] == metabolite].tolist(),
                            "mz": dataframe["MzQuery"].loc[dataframe["Precursor Name"] == metabolite].tolist()}


with st.container(border=True, height=400,key="metabolite_selection_container"):
    st.subheader("Metabolites")
    for metabolite, values in st.session_state['met_dict'].items():
        metabolite_selection = st.checkbox(metabolite, 
                                            # key=metabolite, 
                                            value=False if metabolite not in st.session_state.metabolite_checkbox else st.session_state.metabolite_checkbox[metabolite],
                                            on_change=session_state_checkbox,
                                            args=(metabolite,)
                                            )

if st.session_state.metabolite_checkbox:
    st.subheader("Results")
    for i in st.session_state.metabolite_checkbox:
        if st.session_state.metabolite_checkbox[i]:
            graph, caracteristics = st.columns(2)
            df = pd.DataFrame({
                    "Datetime": st.session_state.met_dict[i]["datetime"],
                    "Intensity": st.session_state.met_dict[i]["intensity"]
                })
            with graph:
                fig = px.line(df, x="Datetime", y="Intensity", title=f"{i} Intensity Over Time")
                st.plotly_chart(fig, use_container_width=True)
                
            with caracteristics:
                show_df, operations = st.columns(2)
                with show_df:
                    st.subheader("Dataframe")
                    st.dataframe(df, use_container_width=True, hide_index=True)
                with operations:
                    st.subheader("Operations")
                    operation = ["area"]
                    st.selectbox("Select an operation:", 
                                key=f"operation_{i}",
                                options=operation)
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



# dataframe = pd.read_csv("/home/kouakou/cylc-run/bioreactor-workflow/data_test_2/results/all_features.tsv", sep="\t")
# for metabolite in dataframe["Precursor Name"].unique():
#     st.session_state.met_dict[metabolite] = {"datetime": dataframe["Datetime"].loc[dataframe["Precursor Name"] == metabolite].tolist(),
#                             "intensity": dataframe["Intensity"].loc[dataframe["Precursor Name"] == metabolite].tolist(),
#                             "mz": dataframe["MzQuery"].loc[dataframe["Precursor Name"] == metabolite].tolist()}

# actualize = st.button("Actualize",
#           key="actualize_metabolites",
#           on_click=store_metabolites)

# if actualize:
#     st.rerun()

# st.write(st.session_state.met_dict)

    # if "metabolite_checkbox" not in st.session_state:
    #     st.session_state.metabolite_checkbox = {}


                        

    # st.write(st.session_state)
