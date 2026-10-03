import pandas as pd
import joblib
from main import z_score_data

df = pd.read_csv('private_data.csv')
num_columns = len(df.dtypes) - 1
num_clusters = 4 * num_columns - 1
print('Number of columns:', num_columns)
print('Number of clusters:', num_clusters)

df = z_score_data(df)

model = joblib.load('models/kmeans_model.pkl')

df['label'] = model.predict(df.drop('id', axis=1))

new_df = df[['id', 'label']]

new_df.to_csv('private_submission.csv', index=False)