import multiprocessing
import numpy as np
from mapper import KMeansMapper
from reducer import KMeansReducer

NUM_CLUSTERS = 4
NUM_MAPPERS = 8
MAX_ITER = 10
INPUT_FILE = "data.txt"

def read_data(file_path):
    with open(file_path, "r") as f:
        data = [np.array(list(map(float, line.strip().split()))) for line in f]
    return data

def split_data(data, num_chunks):
    chunk_size = len(data) // num_chunks + 1
    return [data[i:i+chunk_size] for i in range(0, len(data), chunk_size)]

if __name__ == "__main__":
    # read data
    data = read_data(INPUT_FILE)
    print("input length:", len(data))

    # initialize centroids
    centroids = [data[i] for i in np.random.choice(len(data), NUM_CLUSTERS, replace=False)]
    
    # run k-means
    for iteration in range(MAX_ITER):
        print(f"Iteration {iteration + 1}:")
        
        # split data
        data_chunks = split_data(data, NUM_MAPPERS)
        
        # initialize result queue
        result_queue = multiprocessing.Queue()
        
        # run mappers
        mappers = [KMeansMapper(chunk, centroids, result_queue) for chunk in data_chunks]
        for mapper in mappers:
            mapper.start()
        for mapper in mappers:
            mapper.join()
        
        # run reducer
        manager = multiprocessing.Manager()
        new_centroids = manager.dict()
        reducer = KMeansReducer(result_queue, NUM_CLUSTERS, new_centroids)
        reducer.start()
        reducer.join()
        
        # update centroids
        new_centroids = dict(new_centroids)
        if np.allclose(centroids, list(new_centroids.values()), atol=1e-4):
            print("Converged!")
            break
        centroids = list(new_centroids.values())
    
    print("Final centroids:", centroids)
