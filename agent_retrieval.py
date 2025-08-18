from openai import OpenAI
import pandas as pd
import itertools

# ---------------------------------------------------------------------------
# 1.  Set up the OpenAI client so it talks to your local Ollama daemon
# ---------------------------------------------------------------------------
client = OpenAI(
    base_url="http://localhost:11434/v1",  # or "http://localhost:11434/v1"
    api_key="ollama"                     # any non‑empty string is fine
)

# ---------------------------------------------------------------------------
# 2.  Specify the model
# ---------------------------------------------------------------------------
model = "gemma3"  # pick any model you have pulled with `ollama pull ...`

# Read in the csv file with the individual profiles
profiles_df = pd.read_csv("profiles.csv")

# Define the inflation and unemployment scenarios to loop over
inflation_values = [2.0, 4.0, 6.0, 8.0, 10.0, 12.0]
unemployment_values = [2.0, 4.0, 6.0, 8.0, 10.0, 12.0]

results = []

start_idx = 0  # Start processing from this profile number

for idx, profile in profiles_df.iloc[start_idx:].iterrows():
    actual_idx = idx + start_idx  # Adjust index for progress reporting
    gender = profile['Gender']
    age = profile['Age']
    kids = profile['Kids']
    politics = profile['Politics']
    education = profile['Education']
    income = profile['Income']

    profile_results = []

    for inf, unemp in itertools.product(inflation_values, unemployment_values):
        system_prompt = (
            f"You are a German {gender}, {age} years old and have {kids} kid(s)."
            f"You have {politics} political views. "
            f"You have {education} degree and earn {income} Euros a month. "
            "You must answer ONLY with a single number representing the interest rate in the format: {X.XX}. Do not add any explanation, reasoning, or extra text. Do NOT show your thought process. Reply ONLY with the number."
        )

        question = f"Inflation is at {inf}% and unemployment is at {unemp}%. Given this current economic climate, what is your preferred interest rate?" 

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": question}
        ]

        chat_completion = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=0,
            max_tokens=10
        )

        response_text = chat_completion.choices[0].message.content.strip()
        
        # Record the results for this profile and scenario
        profile_results.append({
            "Gender": gender,
            "Age": age,
            "Kids": kids,
            "Politics": politics,
            "Education": education,
            "Income": income,
            "Inflation": inf,
            "Unemployment": unemp,
            "Response": response_text
        })

    # Append profile_results to results and save to CSV after each profile
    results.extend(profile_results)
    df = pd.DataFrame(results)
    df.to_csv("results.csv", index=False)

    # Print the progress of the simulation
    percent_done = ((idx + 1) / len(profiles_df)) * 100
    print(f"Profile {idx + 1} of {len(profiles_df)} processed. Progress: {percent_done:.2f}%")