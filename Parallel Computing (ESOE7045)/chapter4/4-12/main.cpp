#include <iostream>
#include <mpi.h>
#include <stdlib.h>
#include <vector>
#include <cmath>
#include <algorithm>

// Function to integrate: 4/(1+x^2)
double f(double x) {
    return 4.0 / (1.0 + x * x);
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    // Synchronize all processes before starting timer
    MPI_Barrier(MPI_COMM_WORLD);
    double start_time = MPI_Wtime();
    
    // ===== Your actual work here =====
    double a = 0.0;  // Start of interval
    double b = 1.0;  // End of interval
    long n = 50;     // Number of intervals (must be even)
    double h = (b - a) / n;  // Width of each interval
    
    // Divide work among processes
    // Each process handles a chunk of intervals
    long local_n = n / size;
    long start_idx = rank * local_n;
    long end_idx = (rank == size - 1) ? n : (rank + 1) * local_n;
    
    double local_sum = 0.0;
    
    // Compute local contribution using Simpson's rule
    for (long i = start_idx; i <= end_idx; i++) {
        double x = a + h * i;
        double coefficient;
        
        if (i == 0 || i == n) {
            coefficient = 1.0;
        } else if (i % 2 == 1) {
            coefficient = 4.0;
        } else {
            coefficient = 2.0;
        }
        
        local_sum += coefficient * f(x);
    }
    
    // Sum all local contributions
    double global_sum = 0.0;
    MPI_Reduce(&local_sum, &global_sum, 1, MPI_DOUBLE, MPI_SUM, 0, MPI_COMM_WORLD);
    
    // Only rank 0 computes final result
    double pi_approx;
    if (rank == 0) {
        pi_approx = (h / 3.0) * global_sum;
        printf("Approximation of pi: %13.11f\n", pi_approx);
        printf("Error: %e\n", fabs(pi_approx - M_PI)); 
    }
    // ==================================
    
    double elapsed_time = MPI_Wtime() - start_time;

    double max_elapsed_time;
    MPI_Reduce(&elapsed_time, &max_elapsed_time, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    
    // Only rank 0 reports the timing
    if (rank == 0) {
        printf("\n===== Benchmark Results =====\n");
        printf("Number of processes: %d\n", size);
        printf("Highest elapsed time: %f seconds\n", max_elapsed_time);
        printf("============================\n");
    }
    
    MPI_Finalize();
    return 0;
}