#include <iostream>
#include <mpi.h>
#include <stdlib.h>
#include <cmath>

// Calculate distance from point (x, y, z) to the line x = y = z
// Using the formula from the hint:
// distance = sin(arccos((x+y+z)/(sqrt(3)*sqrt(x^2+y^2+z^2)))) * sqrt(x^2+y^2+z^2)
double distance_to_line(double x, double y, double z) {
    double norm_sq = x*x + y*y + z*z;
    if (norm_sq < 1e-10) {  // Point is at origin
        return 0.0;
    }
    double norm = sqrt(norm_sq);
    double sum = x + y + z;
    double cos_angle = sum / (sqrt(3.0) * norm);
    
    // Clamp cos_angle to [-1, 1] to avoid numerical issues
    if (cos_angle > 1.0) cos_angle = 1.0;
    if (cos_angle < -1.0) cos_angle = -1.0;
    
    double angle = acos(cos_angle);
    return sin(angle) * norm;
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    // Problem parameters
    const double s = 2.0;  // cube edge length
    const double d = 0.3;  // cylinder diameter
    const double r = d / 2.0;  // cylinder radius
    const long long total_samples = 100000000LL;  // total number of samples
    
    // Synchronize all processes before starting timer
    MPI_Barrier(MPI_COMM_WORLD);
    double start_time = MPI_Wtime();
    
    // ===== Your actual work here =====
    
    // Divide work among processes
    long long samples_per_process = total_samples / size;
    if (rank < total_samples % size) {
        samples_per_process++;  // Some processes get one extra sample
    }
    
    // Initialize random number generator with different seed for each process
    srand(rank + 12345);
    
    long long points_in_cube = 0;
    long long points_outside_cylinder = 0;
    
    // Monte Carlo integration
    for (long long i = 0; i < samples_per_process; i++) {
        double x = (double)rand() / RAND_MAX * s;
        double y = (double)rand() / RAND_MAX * s;
        double z = (double)rand() / RAND_MAX * s;
        
        // Point is in cube (always true since we sample from [0, s])
        points_in_cube++;
        
        // Check if point is outside the cylinder
        double dist_to_axis = distance_to_line(x, y, z);
        if (dist_to_axis > r) {
            points_outside_cylinder++;
        }
    }
    
    // Sum results from all processes
    long long total_points_in_cube;
    long long total_points_outside_cylinder;
    
    MPI_Reduce(&points_in_cube, &total_points_in_cube, 1, MPI_LONG_LONG, MPI_SUM, 0, MPI_COMM_WORLD);
    MPI_Reduce(&points_outside_cylinder, &total_points_outside_cylinder, 1, MPI_LONG_LONG, MPI_SUM, 0, MPI_COMM_WORLD);
    
    // Calculate volume
    double cube_volume = s * s * s;
    double remaining_volume = 0.0;
    
    if (rank == 0) {
        remaining_volume = (double)total_points_outside_cylinder / (double)total_points_in_cube * cube_volume;
        printf("\n===== Volume Calculation =====\n");
        printf("Cube edge length: %.1f\n", s);
        printf("Cylinder diameter: %.1f\n", d);
        printf("Total samples: %lld\n", total_points_in_cube);
        printf("Points outside cylinder: %lld\n", total_points_outside_cylinder);
        printf("Remaining volume: %.5f\n", remaining_volume);
        printf("==============================\n");
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