from openai import OpenAI
import pandas as pd
import itertools
import re

# ---------------------------------------------------------------------------
# 1.  Set up the OpenAI client so it talks to your local Ollama daemon
# ---------------------------------------------------------------------------
client = OpenAI(
    base_url="http://localhost:11434/v1",
    api_key="ollama"
)

# ---------------------------------------------------------------------------
# 2.  Specify the model
# ---------------------------------------------------------------------------
model = "gemma3"  # pick any model you have pulled with `ollama pull ...`

# ---------------------------------------------------------------------------
# 3.  Parameters
# ---------------------------------------------------------------------------
inflation_values = [2.0, 4.0, 6.0, 8.0, 10.0, 12.0]
unemployment_values = [2.0, 4.0, 6.0, 8.0, 10.0, 12.0]
num_iterations = 10

# ---------------------------------------------------------------------------
# 4.  Choose answer type: "number" or "open"
# ---------------------------------------------------------------------------
answer_type = "number"  # set to "open" for open answer, "number" for just the number

results = []

for iteration in range(num_iterations):
    print(f"Starting iteration {iteration + 1}/{num_iterations}")
    for inf, unemp in itertools.product(inflation_values, unemployment_values):
        if answer_type == "number":
            system_prompt = (
                "You are the chief economist of the European central bank."
                "You must answer ONLY with a single number representing the interest rate in the format: {X.XX}. "
                "Do not add any explanation, reasoning, or extra text. Do NOT show your thought process. Reply ONLY with the number."
            )
            question = f"Inflation is at {inf}% and unemployment is at {unemp}%. Given this current economic climate, what is your preferred interest rate?"
            max_tokens = 10
            temperature = 0
        else:  # open answer
            system_prompt = (
                "You are the chief economist of the European central bank."
                "Keep your answer concise and focused on the interest rate decision."
                "Your answer must include the interest rate in the format: {X.XX}."
                "Do not say that you 'maintain' or 'keep' the interest rate, or that you change it in a specific direction."
                "But rather provide the interest rate as a final value."
            )
            question = (
                f"Inflation is at {inf}% and unemployment is at {unemp}%. "
                "Given this current economic climate, what is your preferred interest rate?"
                "Reason using your economic expertise and the current economic indicators."
                "Come to a conclusion and provide the interest rate in the format: {X.XX}."
                "Do not provide the interest rate as a change or relative to the current rate."
                "Give an actual interest rate value."
            )
            max_tokens = 200
            temperature = 0.7

        messages = [
            {"role": "system", "content": system_prompt},
            {"role": "user",   "content": question}
        ]

        chat_completion = client.chat.completions.create(
            model=model,
            messages=messages,
            temperature=temperature,
            max_tokens=max_tokens
        )

        response_text = chat_completion.choices[0].message.content.strip()
        interest_rate = None
        if answer_type == "number":
            match = re.search(r"\{([0-9]*\.?[0-9]+)\}", response_text)
            interest_rate = float(match.group(1)) if match else None
        else:
            match = re.search(r"\{([0-9]*\.?[0-9]+)\}", response_text)
            interest_rate = float(match.group(1)) if match else None

        results.append({
            "Iteration": iteration + 1,
            "Role": "Central Banker",
            "Inflation": inf,
            "Unemployment": unemp,
            "Response": response_text,
            "Interest Rate": interest_rate
        })
        print(f"Inflation: {inf}, Unemployment: {unemp}, Interest Rate: {interest_rate}")

    # Save results after each full iteration
    try:
        print(f"Saving results after iteration {iteration + 1} ...")
        df = pd.DataFrame(results)
        filename = "resultsCentralBank.csv" if answer_type == "number" else "resultsCentralBankOPEN.csv"
        df.to_csv(filename, index=False)
    except Exception as e:
        print(f"Error saving results: {e}")

print("All scenarios processed and results saved.")
