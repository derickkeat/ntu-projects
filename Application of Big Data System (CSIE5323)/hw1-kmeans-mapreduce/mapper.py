import multiprocessing
import numpy as np
import math

class KMeansMapper(multiprocessing.Process):
    def __init__(self, data_chunk, centroids, result_queue):
        super().__init__()
        self.data_chunk = data_chunk
        self.centroids = centroids
        self.result_queue = result_queue

    def run(self):
        pass
        # TODO: Implement the run method. This method should assign each point in self.data_chunk to the nearest centroid and put the result in the result_queue.
        # The result should be a tuple containing the index of the nearest centroid and the point itself.

        # calculate the closest centroid for each point then put it in the queue with the format of (centroid_index, point_coordinate)
        for point in self.data_chunk:
            closest_centroid_index = 0
            shortest_distance = math.inf
            for i in range(len(self.centroids)):
                centroid = self.centroids[i]
                distance = self.euclidean_distance(point, centroid)

                if distance < shortest_distance:
                    closest_centroid_index = i
                    shortest_distance = distance

            self.result_queue.put((closest_centroid_index, point))
        
    # return the eucliedean distance between a point and a centroid
    def euclidean_distance(self, point, centroid):
        point_x, point_y = point
        centroid_x, centroid_y = centroid

        return math.sqrt((centroid_x - point_x)**2 + (centroid_y - point_y)**2)