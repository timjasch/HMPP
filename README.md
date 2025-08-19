**Heterogeneity in Monetary Policy Preferences – An LLM-based Approach**

To make the program functional, replace the `base_url` in `agent_retrieval.py` with the API endpoint of the LLM host of your choice (e.g., Ollama).  
If you use Ollama, make sure you either have `gemma3` installed or set `model` to another LLM you have installed via Ollama.

---

### Repository Structure

- **Data/**  
  Contains the results from large-scale LLM requests and a script that merges the files required for the main analysis.  

- **results_complete.csv**  
  Output of `Data_Merger.R`, serves as the main database for analysis.  

- **Graphs/**  
  Contains all generated graphs, including those used in the documentation and additional visualizations.  

- **computer_modern/**  
  A file required to generate graphs labeled with the CM font.  

- **agent_profiles.py**  
  Creates the different agent profiles used in `agent_retrieval.py`. See the documentation for details.  

- **agent_retrieval.py**  
  Main contact point to the LLM. Generates and saves the responses of the LLM.  

- **centralBanker_retrieval.py**  
  Similar to `agent_retrieval.py`, but for a different setting. Not required for the main analysis.  

- **theory_centralbank.R**  
  Creates Figure 2(b) of the documentation and includes additional analysis on the results for the "central banker."  

- **demographics.r**  
  Main file for generating results presented in the documentation.  

- **variance_decomp.r**  
  Script for analyzing the influence and relative importance of different characteristics in explaining response variance. Produces Figure 3 of the documentation.  

---

### Documentation

The economic analysis of the results and the choices made for the LLM integration are documented in:  

- [LLM_Based_Agents_in_Macroeconomics.pdf](https://github.com/user-attachments/files/21833498/LLM_Based_Agents_in_Macroeconomics.pdf)  

This documentation focuses on the main analysis based on the profile-based agents.  
