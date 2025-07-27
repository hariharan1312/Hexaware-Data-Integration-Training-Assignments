import pandas as pd

df = pd.read_csv("final_college_student_placement_dataset.csv")

# =====================
# 1. Categorize placed students into salary bands
# =====================
def salary_band(salary):
    if pd.isna(salary):
        return None
    elif salary < 300000:
        return 'Low'
    elif salary <= 600000:
        return 'Medium'
    else:
        return 'High'

df['Salary_Band'] = df.apply(lambda x: salary_band(x['Salary']) if x['Placement'] == 'Yes' else None, axis=1)

#print(df[['College_ID', 'Salary', 'Salary_Band']].head())

# =====================
# 2. For each gender and specialization, calculate:
#    Placement rate, Average salary (placed), Avg MBA score
# =====================

placement_stats = df.groupby(['Gender', 'Specialization']).agg(
    Placement_Rate=('Placement', lambda x: (x == 'Yes').mean()),
    Avg_Salary_Placed=('Salary', lambda x: x[df.loc[x.index, 'Placement'] == 'Yes'].mean()),
    Avg_MBA_Score=('MBA_Percentage', 'mean')
).reset_index()

#print(placement_stats)


# =====================
# 3. Find how many students have missing values in any column
# =====================
missing_value_count = df.isnull().any(axis=1).sum()

# print(f"Missing rows count: {missing_value_count}")

# =====================
# 4. Display all rows where salary is missing
# =====================
salary_missing = df[df['Salary'].isnull()]

# print(salary_missing)

# =====================
# 5. Filter only students with complete records (no missing values)
# =====================
complete_students = df.dropna()

# =====================
# 6. Identify if there are any duplicate student entries
# =====================
duplicate_rows = df[df.duplicated()]

# print(duplicate_rows)

# =====================
# 7. Drop the duplicate records and keep only the first occurrence
# =====================
df_no_duplicates = df.drop_duplicates()

# =====================
# 8. Check for duplicates based only on College_ID
# =====================
college_id_duplicates = df[df.duplicated(subset=['College_ID'], keep=False)]

# print(college_id_duplicates)

# =====================
# 9. Find all unique specializations offered to students
# =====================
unique_specializations = df['Specialization'].dropna().unique()

# print(unique_specializations)

# =====================
# 10. How many unique MBA scores are there?
# =====================
unique_mba_scores = df['MBA_Percentage'].nunique()

# print(f"Unique MBA scores: {unique_mba_scores}")

# =====================
# 11. Count of unique combinations of gender, specialization, and status
# =====================
unique_combos = df[['Gender', 'Specialization', 'Placement']].drop_duplicates().shape[0]

# print(f"Unique gender-specialization-placement combos: {unique_combos}")

# =====================
# 12. What is the average salary of all placed students?
# =====================
avg_salary_placed = df[df['Placement'] == 'Yes']['Salary'].mean()

# print(f"Average salary of placed students: ₹{avg_salary_placed:.2f}")

# =====================
# 13. What is the maximum and minimum degree percentage in the dataset?
# =====================
max_degree = df['CGPA'].max()
min_degree = df['CGPA'].min()

# print(f"Max CGPA: {max_degree}, Min CGPA: {min_degree}")


# =====================
# 14. Get total number of placed and unplaced students
# =====================
placement_counts = df['Placement'].value_counts()

# print(placement_counts)

# =====================
# 15. For each specialization, calculate:
#     Average SSC, Average MBA, Placement count
# =====================
spec_summary = df.groupby('Specialization').agg(
    Avg_SSC=('SSC_Percentage', 'mean'),
    Avg_MBA=('MBA_Percentage', 'mean'),
    Placement_Count=('Placement', lambda x: (x == 'Yes').sum())
).reset_index()

# print(spec_summary)

# =====================
# 16. Create a summary table with:
#     Column name, Count of nulls, Count of unique values, Duplicated value count
# =====================
summary_table = pd.DataFrame({
    'Column': df.columns,
    'Null_Count': df.isnull().sum().values,
    'Unique_Values': df.nunique().values,
    'Duplicate_Count': [df.duplicated(subset=[col]).sum() if df[col].duplicated().any() else 0 for col in df.columns]
})

# print(summary_table)
