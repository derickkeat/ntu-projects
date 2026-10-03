from main import *
import pandas as pd
import subprocess
import time

def do_preprocess(preprocess_method, df):
    if preprocess_method == 'z-score':
        return z_score_data(df)
    elif preprocess_method == 'minmax':
        return min_max_scale_data(df)
    elif preprocess_method == 'robust':
        return robust_scaler_data(df)   
    elif preprocess_method == 'quantile':
        return quantile_transform_data(df)
    elif preprocess_method == 'power':
        return power_transform_data(df)
    elif preprocess_method == 'none':
        return df

def do_clustering(clustering_method, df, num_clusters):
    if clustering_method == 'kmeans':
        return kmeans_clustering(df, num_clusters)
    elif clustering_method == 'gmm':
        return gaussian_mixture_clustering(df, num_clusters)
    elif clustering_method == 'bgmm':
        return bayesian_gaussian_mixture_clustering(df, num_clusters)

if __name__ == "__main__":
    start_time = time.time()
    preprocess_methods = ['z-score', 'minmax', 'robust', 'quantile', 'power', 'none']
    clustering_methods = ['kmeans', 'gmm', 'bgmm']

    result = pd.DataFrame(columns=['preprocess_method', 'clustering_method', 'accuracy'])
    for preprocess_method in preprocess_methods:
        for clustering_method in clustering_methods:
            # read the data
            df = pd.read_csv('public_data.csv')
            num_columns = len(df.dtypes) - 1
            num_clusters = 4 * num_columns - 1

            # do the preprocess and clustering
            df = do_preprocess(preprocess_method, df)
            df = do_clustering(clustering_method, df, num_clusters)
            
            # creating submission file
            new_df = df[['id', 'label']]
            new_df.to_csv('public_submission.csv', index=False)

            # run the submission file
            output = subprocess.run(['python', 'eval.py'], capture_output=True, text=True)
            output_score = output.stdout.split('Score: ')[1].split('\n')[0]
            result = pd.concat([result, pd.DataFrame([[preprocess_method, clustering_method, output_score]], columns=['preprocess_method', 'clustering_method', 'accuracy'])], ignore_index=True)

    result.sort_values(by='accuracy', ascending=False, inplace=True)
    print(result)
    result.to_csv(f'model_tests/model_result_{time.strftime("%Y%m%d_%H%M%S")}.csv', index=False)
    print('Time taken:', time.time() - start_time, 'seconds')