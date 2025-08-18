from openai import OpenAI
import pandas as pd
import itertools

# Inflation rates, vector
gender = ["Men", "Woman"]
age = [18, 35, 50, 65]
kids = [0, 1, 2]
income = ["less than 1500", "1500-2500", "2500-4000", "more than 4000"]
education = ["no high school", "a high school", "a college"]
politics = ["left-wing", "left-leaning", "centre", "right-leaning", "right-wing"]

# Economic indicators
inflation = [2, 4, 6, 8, 12]
unemployment = [2, 4, 6, 8, 12]

# Indivudals
dim_individuals = len(gender) * len(age) * len(kids) * len(income) * len(education) * len(politics)
# length of the vectors
dim_economics = len(inflation) * len(unemployment)

# Create a table of all combinations
profiles = list(itertools.product(gender, age, kids, income, education, politics))
len(profiles)
profiles_df = pd.DataFrame(profiles, columns=["Gender", "Age", "Kids", "Income", "Education", "Politics"])
print(profiles_df.head())

# Save the profiles to a CSV file
profiles_df.to_csv("profiles.csv", index=False)