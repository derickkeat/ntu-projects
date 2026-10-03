import multiprocessing
import numpy as np

class KMeansReducer(multiprocessing.Process):
    def __init__(self, result_queue, num_clusters, new_centroids):
        super().__init__()
        self.result_queue = result_queue
        self.num_clusters = num_clusters
        self.new_centroids = new_centroids

    def run(self):
        pass
        # TODO: Implement the run method. This method should calculate the new centroids based on the points in the result_queue and put the result in the new_centroids list.
        # The new centroids should be the average of the points assigned to each centroid.

        # transfer the elements from the queue to a list, then sort according to the centroid index
        items = []
        while not self.result_queue.empty():
            items.append(self.result_queue.get())
        items.sort(key=lambda x: x[0])

        # place the centroids with same index in a list then find a new coordinate for each centroid, can place then in the dictionary of the manager accordingly.
        for i in range(self.num_clusters):
            points = []
            for item in items:
                if item[0] == i:
                    points.append(item[1])

            if points: # handle empty cluster
                self.new_centroids[i] = self.calc_new_centroid(points)

    # calculate the average of the list of points
    def calc_new_centroid(self, points):
        total_x = 0
        total_y = 0
        for x, y in points:
            total_x += x
            total_y += y

        return np.array((total_x / len(points), total_y / len(points)))