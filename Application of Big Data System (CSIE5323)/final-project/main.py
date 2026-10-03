import os
import pandas as pd
import joblib

from sklearn.preprocessing import StandardScaler, MinMaxScaler, QuantileTransformer, RobustScaler, PowerTransformer
from sklearn.cluster import KMeans
from sklearn.mixture import GaussianMixture, BayesianGaussianMixture

def z_score_data(df):
    id_column = df['id'].copy() # save the id column
    
    features_to_scale = df.drop('id', axis=1) # scale all columns except id
    scaler = StandardScaler()
    scaled_features = pd.DataFrame(
        scaler.fit_transform(features_to_scale), 
        columns=features_to_scale.columns
    )
    print('Z-score transformed features')
    
    # reconstruct the dataframe with id and scaled features
    df = pd.concat([id_column, scaled_features], axis=1)
    return df

def min_max_scale_data(df):
    id_column = df['id'].copy() # save the id column
    features_to_scale = df.drop('id', axis=1) # scale all columns except id
    scaler = MinMaxScaler()
    scaled_features = pd.DataFrame(
        scaler.fit_transform(features_to_scale), 
        columns=features_to_scale.columns
    )
    print('Min-max scaled features')

    df = pd.concat([id_column, scaled_features], axis=1)
    return df

def quantile_transform_data(df):
    id_column = df['id'].copy() # save the id column
    features_to_transform = df.drop('id', axis=1) # transform all columns except id
    transformer = QuantileTransformer(output_distribution='normal')
    transformed_features = pd.DataFrame(
        transformer.fit_transform(features_to_transform), 
        columns=features_to_transform.columns
    )
    print('Quantile transformed features')

    df = pd.concat([id_column, transformed_features], axis=1)
    return df

def robust_scaler_data(df):
    id_column = df['id'].copy() # save the id column
    features_to_scale = df.drop('id', axis=1) # scale all columns except id
    scaler = RobustScaler()
    scaled_features = pd.DataFrame(
        scaler.fit_transform(features_to_scale), 
        columns=features_to_scale.columns
    )
    print('Robust scaled features')

    df = pd.concat([id_column, scaled_features], axis=1)
    return df

def power_transform_data(df):
    id_column = df['id'].copy() # save the id column
    features_to_transform = df.drop('id', axis=1) # transform all columns except id
    transformer = PowerTransformer(method='yeo-johnson')
    transformed_features = pd.DataFrame(
        transformer.fit_transform(features_to_transform), 
        columns=features_to_transform.columns
    )
    print('Power transformed features')

    df = pd.concat([id_column, transformed_features], axis=1)
    return df

def kmeans_clustering(df, num_clusters):
    print('Clustering with KMeans...')
    kmeans = KMeans(n_clusters=num_clusters, verbose=0, n_init=10)
    kmeans.fit(df.drop('id', axis=1))  # don't include id in clustering
    df['label'] = kmeans.predict(df.drop('id', axis=1))
    print('KMeans clustering done')
    # save the model
    os.makedirs('models', exist_ok=True)
    joblib.dump(kmeans, 'models/kmeans_model.pkl')
    print('KMeans model saved')
    return df

def gaussian_mixture_clustering(df, num_clusters):
    print('Clustering with Gaussian Mixture Model...')
    gmm = GaussianMixture(n_components=num_clusters, verbose=1, n_init=5, max_iter=200)
    gmm.fit(df.drop('id', axis=1))
    df['label'] = gmm.predict(df.drop('id', axis=1))
    print('Gaussian Mixture Model clustering done')
    # save the model
    os.makedirs('models', exist_ok=True)
    joblib.dump(gmm, 'models/gmm_model.pkl')
    print('Gaussian Mixture Model model saved')
    return df

def bayesian_gaussian_mixture_clustering(df, num_clusters):
    print('Clustering with Bayesian Gaussian Mixture Model...')
    bgmm = BayesianGaussianMixture(n_components=num_clusters, verbose=1, n_init=5, max_iter=200)
    bgmm.fit(df.drop('id', axis=1))
    df['label'] = bgmm.predict(df.drop('id', axis=1))
    print('Bayesian Gaussian Mixture Model clustering done')
    # save the model
    os.makedirs('models', exist_ok=True)
    joblib.dump(bgmm, 'models/bgmm_model.pkl')
    print('Bayesian Gaussian Mixture Model model saved')
    return df

if __name__ == "__main__":
    # load the data
    df = pd.read_csv('public_data.csv')
    num_columns = len(df.dtypes) - 1
    num_clusters = 4 * num_columns - 1
    print('Number of columns:', num_columns)
    print('Number of clusters:', num_clusters)

    # preprocess the data
    df = z_score_data(df)
    # df = min_max_scale_data(df)
    # df = quantile_transform_data(df)
    # df = robust_scaler_data(df)
    # df = power_transform_data(df)

    # doing clustering
    df = kmeans_clustering(df, num_clusters)
    # df = gaussian_mixture_clustering(df, num_clusters)
    # df = bayesian_gaussian_mixture_clustering(df, num_clusters)

    # creating submission file
    new_df = df[['id', 'label']]
    new_df.to_csv('public_submission.csv', index=False)
    print('Submission file created')