#include <iostream>
#include <mpi.h>
#include <stdlib.h>
#include <vector>
#include <cmath>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    // Validate that exactly 2 processes are running
    if (size != 2) {
        if (rank == 0) {
            fprintf(stderr, "Error: This program requires exactly 2 processes, but %d were provided.\n", size);
        }
        MPI_Finalize();
        return 1;
    }
    
    // Define message sizes to test (in bytes)
    int message_sizes[] = {
        10,          // 10 bytes
        100,         // 100 bytes
        1024,        // 1 KB
        10240,       // 10 KB
        102400,      // 100 KB
        1048576,     // 1 MB
        10485760,    // 10 MB
        20971520     // 20 MB
    };

    std::vector<int> message_sizes_vector (message_sizes, message_sizes + sizeof(message_sizes) / sizeof(message_sizes[0]));
    
    // Number of iterations for each message size
    const int num_iterations = 1000;
    
    MPI_Status status;
    
    // Store results for linear regression
    std::vector<double> times;
    std::vector<int> sizes;
    
    if (rank == 0) {
        printf("\n===== Message Passing Benchmark =====\n");
        printf("Number of processes: %d\n", size);
        printf("Iterations per message size: %d\n", num_iterations);
        printf("\n%-15s %-20s %-20s %-20s\n", 
               "Message Size", "Avg Round-trip (us)", "Avg One-way (us)", "Bandwidth (MB/s)");
        printf("%-15s %-20s %-20s %-20s\n", 
               "-------------", "-------------------", "----------------", "----------------");
    }
    
    // Test each message size
    for (size_t i = 0; i < message_sizes_vector.size(); i++) {
        int msg_size = message_sizes_vector[i];
        
        // Allocate buffer for message
        std::vector<char> buffer(msg_size, 'A');
        
        // Synchronize before timing
        MPI_Barrier(MPI_COMM_WORLD);
        
        if (rank == 0) {
            double total_time = 0.0;
            
            // Perform multiple ping-pong iterations
            for (int iter = 0; iter < num_iterations; iter++) {
                double start_time = MPI_Wtime();
                
                // Send message to process 1
                MPI_Send(buffer.data(), msg_size, MPI_CHAR, 1, 0, MPI_COMM_WORLD);
                
                // Receive message back from process 1
                MPI_Recv(buffer.data(), msg_size, MPI_CHAR, 1, 0, MPI_COMM_WORLD, &status);
                
                double end_time = MPI_Wtime();
                total_time += (end_time - start_time);
            }
            
            // Calculate statistics
            double avg_round_trip = total_time / num_iterations;
            double avg_one_way = avg_round_trip / 2.0;
            
            // Convert to microseconds
            double avg_round_trip_us = avg_round_trip * 1e6;
            double avg_one_way_us = avg_one_way * 1e6;
            
            // Calculate bandwidth (MB/s)
            // Bandwidth = message_size / one_way_time (in bytes/second)
            double bandwidth_bytes_per_sec = msg_size / avg_one_way;
            double bandwidth_mb_per_sec = bandwidth_bytes_per_sec / (1024.0 * 1024.0);
            
            printf("%-15d %-20.6f %-20.6f %-20.2f\n", 
                   msg_size, avg_round_trip_us, avg_one_way_us, bandwidth_mb_per_sec);
            
            // Store data for linear regression
            sizes.push_back(msg_size);
            times.push_back(avg_one_way);  // Store in seconds
            
        } else if (rank == 1) {
            // Process 1: Receive and send back for each iteration
            for (int iter = 0; iter < num_iterations; iter++) {
                MPI_Recv(buffer.data(), msg_size, MPI_CHAR, 0, 0, MPI_COMM_WORLD, &status);
                MPI_Send(buffer.data(), msg_size, MPI_CHAR, 0, 0, MPI_COMM_WORLD);
            }
        }
    }
    
    if (rank == 0) {
        // Perform linear regression to extract latency and bandwidth
        // Model: time = latency + (message_size / bandwidth)
        // This is y = b + mx where m = 1/bandwidth, b = latency
        
        int n = sizes.size();
        double sum_x = 0.0, sum_y = 0.0;
        double sum_xx = 0.0, sum_xy = 0.0;
        
        for (int i = 0; i < n; i++) {
            double x = (double)sizes[i];
            double y = times[i];
            sum_x += x;
            sum_y += y;
            sum_xx += x * x;
            sum_xy += x * y;
        }
        
        // Calculate slope (m) and intercept (b)
        double slope = (n * sum_xy - sum_x * sum_y) / (n * sum_xx - sum_x * sum_x);
        double intercept = (sum_y - slope * sum_x) / n;
        
        // Extract latency and bandwidth from regression
        double latency = intercept;  // seconds
        double bandwidth = 1.0 / slope;  // bytes/second
        
        // Calculate R-squared for goodness of fit
        double mean_y = sum_y / n;
        double ss_tot = 0.0, ss_res = 0.0;
        for (int i = 0; i < n; i++) {
            double predicted = intercept + slope * sizes[i];
            ss_res += (times[i] - predicted) * (times[i] - predicted);
            ss_tot += (times[i] - mean_y) * (times[i] - mean_y);
        }
        double r_squared = 1.0 - (ss_res / ss_tot);
        
        printf("\n===== Linear Regression Analysis =====\n");
        printf("Model: time = latency + (message_size / bandwidth)\n\n");
        printf("Estimated Latency:    %.6f microseconds\n", latency * 1e6);
        printf("Estimated Bandwidth:  %.2f MB/s\n", bandwidth / (1024.0 * 1024.0));
        printf("R-squared:            %.6f (closer to 1.0 = better fit)\n", r_squared);
        printf("=======================================\n\n");
    }
    
    MPI_Finalize();
    return 0;
}