#include <iostream>
#include <mpi.h>
#include <stdlib.h>
#include <vector>
#include <fstream>
#include <cmath>
#include <algorithm>

/*
 * Matrix-Vector Multiplication with Checkerboard Block Decomposition
 * 
 * Input file formats:
 * - Matrix file: First line contains m n (rows columns), followed by m*n values in row-major order
 * - Vector file: First line contains n (size), followed by n values
 * 
 * Example matrix file (2x3):
 *   2 3
 *   1.0 2.0 3.0
 *   4.0 5.0 6.0
 * 
 * Example vector file (size 3):
 *   3
 *   1.0 2.0 3.0
 */

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    // Check command-line arguments
    if (argc != 3) {
        if (rank == 0) {
            std::cerr << "Usage: " << argv[0] << " <matrix_file> <vector_file>" << std::endl;
        }
        MPI_Finalize();
        return 1;
    }
    
    // Synchronize all processes before starting timer
    MPI_Barrier(MPI_COMM_WORLD);
    double start_time = MPI_Wtime();
    
    // ===== Your actual work here =====
    std::string matrix_file = argv[1];
    std::string vector_file = argv[2];
    
    int m = 0, n = 0;  // Matrix dimensions: m rows, n cols
    std::vector<double> matrix;
    std::vector<double> vector_x;
    
    // Rank 0 reads the matrix and vector from files
    if (rank == 0) {
        // Read matrix
        std::ifstream mat_file(matrix_file.c_str());
        if (!mat_file) {
            std::cerr << "Error: Cannot open matrix file " << matrix_file << std::endl;
            MPI_Abort(MPI_COMM_WORLD, 1);
        }
        mat_file >> m >> n;
        matrix.resize(m * n);
        for (int i = 0; i < m * n; i++) {
            mat_file >> matrix[i];
        }
        mat_file.close();
        
        // Read vector
        std::ifstream vec_file(vector_file.c_str());
        if (!vec_file) {
            std::cerr << "Error: Cannot open vector file " << vector_file << std::endl;
            MPI_Abort(MPI_COMM_WORLD, 1);
        }
        int vec_size;
        vec_file >> vec_size;
        if (vec_size != n) {
            std::cerr << "Error: Vector size (" << vec_size << ") must match matrix columns (" << n << ")" << std::endl;
            MPI_Abort(MPI_COMM_WORLD, 1);
        }
        vector_x.resize(n);
        for (int i = 0; i < n; i++) {
            vec_file >> vector_x[i];
        }
        vec_file.close();
    }
    
    // Broadcast dimensions
    MPI_Bcast(&m, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&n, 1, MPI_INT, 0, MPI_COMM_WORLD);
    
    // Create 2D Cartesian communicator for checkerboard decomposition
    // Find factors of size for grid dimensions
    int p_rows = (int)sqrt(size);
    while (size % p_rows != 0) {
        p_rows--;
    }
    int p_cols = size / p_rows;
    
    // Create Cartesian topology
    int dims[2] = {p_rows, p_cols};
    int periods[2] = {0, 0};
    int reorder = 1;
    MPI_Comm cart_comm;
    MPI_Cart_create(MPI_COMM_WORLD, 2, dims, periods, reorder, &cart_comm);
    
    int cart_rank;
    int coords[2];
    MPI_Comm_rank(cart_comm, &cart_rank);
    MPI_Cart_coords(cart_comm, cart_rank, 2, coords);
    int row_rank = coords[0];
    int col_rank = coords[1];
    
    // Create row and column communicators
    MPI_Comm row_comm, col_comm;
    int remain_dims[2];
    
    // Row communicator: same row, different columns
    remain_dims[0] = 0;  // Don't keep row dimension
    remain_dims[1] = 1;  // Keep column dimension
    MPI_Cart_sub(cart_comm, remain_dims, &row_comm);
    
    // Column communicator: same column, different rows
    remain_dims[0] = 1;  // Keep row dimension
    remain_dims[1] = 0;  // Don't keep column dimension
    MPI_Cart_sub(cart_comm, remain_dims, &col_comm);
    
    // Calculate block dimensions
    int block_rows = (m + p_rows - 1) / p_rows;  // Ceiling division
    int block_cols = (n + p_cols - 1) / p_cols;  // Ceiling division
    
    // Calculate local block boundaries
    int local_row_start = row_rank * block_rows;
    int local_row_end = std::min(local_row_start + block_rows, m);
    int local_row_size = local_row_end - local_row_start;
    
    int local_col_start = col_rank * block_cols;
    int local_col_end = std::min(local_col_start + block_cols, n);
    int local_col_size = local_col_end - local_col_start;
    
    // Allocate local matrix block
    std::vector<double> local_matrix(local_row_size * local_col_size);
    
    // Distribute matrix blocks to processes
    // Since blocks are not contiguous, we manually send each block
    if (rank == 0) {
        // Send blocks to all processes (including self)
        for (int proc = 0; proc < size; proc++) {
            int proc_coords[2];
            MPI_Cart_coords(cart_comm, proc, 2, proc_coords);
            int proc_row = proc_coords[0];
            int proc_col = proc_coords[1];
            
            int proc_row_start = proc_row * block_rows;
            int proc_row_end = std::min(proc_row_start + block_rows, m);
            int proc_row_size = proc_row_end - proc_row_start;
            
            int proc_col_start = proc_col * block_cols;
            int proc_col_end = std::min(proc_col_start + block_cols, n);
            int proc_col_size = proc_col_end - proc_col_start;
            
            // Pack block into contiguous buffer
            std::vector<double> block_data(proc_row_size * proc_col_size);
            for (int i = 0; i < proc_row_size; i++) {
                for (int j = 0; j < proc_col_size; j++) {
                    int global_row = proc_row_start + i;
                    int global_col = proc_col_start + j;
                    block_data[i * proc_col_size + j] = matrix[global_row * n + global_col];
                }
            }
            
            if (proc == 0) {
                // Copy to local_matrix for rank 0
                local_matrix = block_data;
            } else {
                // Send to other processes
                MPI_Send(block_data.data(), proc_row_size * proc_col_size, MPI_DOUBLE, 
                        proc, 0, cart_comm);
            }
        }
    } else {
        // Receive block from rank 0
        MPI_Recv(local_matrix.data(), local_row_size * local_col_size, MPI_DOUBLE,
                0, 0, cart_comm, MPI_STATUS_IGNORE);
    }
    
    // Broadcast vector x to all processes (each process needs its column portion)
    if (rank == 0) {
        // Broadcast full vector to all processes
        MPI_Bcast(vector_x.data(), n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
    } else {
        vector_x.resize(n);
        MPI_Bcast(vector_x.data(), n, MPI_DOUBLE, 0, MPI_COMM_WORLD);
    }
    
    // Compute local block-vector product: local_y = local_A * x[local_col_start:local_col_end]
    std::vector<double> local_y(local_row_size, 0.0);
    
    for (int i = 0; i < local_row_size; i++) {
        for (int j = 0; j < local_col_size; j++) {
            int global_col = local_col_start + j;
            local_y[i] += local_matrix[i * local_col_size + j] * vector_x[global_col];
        }
    }
    
    // Reduce within row communicator (sum contributions from processes in same row)
    // Processes with same row_rank but different col_rank contribute to same result rows
    std::vector<double> row_result;
    if (col_rank == 0) {
        row_result.resize(local_row_size);
    }
    
    // Sum contributions from all processes in the same row
    MPI_Reduce(local_y.data(), row_result.data(), local_row_size, MPI_DOUBLE, 
               MPI_SUM, 0, row_comm);
    
    // Gather results from all row leaders (col_rank == 0) to rank 0
    // Only processes with col_rank == 0 participate (they are the row leaders)
    std::vector<double> result;
    if (rank == 0) {
        result.resize(m);
    }
    
    if (col_rank == 0) {
        // Prepare gather parameters
        std::vector<int> recvcounts(p_rows);
        std::vector<int> displs_gather(p_rows);
        
        for (int r = 0; r < p_rows; r++) {
            int r_start = r * block_rows;
            int r_end = std::min(r_start + block_rows, m);
            recvcounts[r] = r_end - r_start;
            displs_gather[r] = r_start;
        }
        
        // Get rank in col_comm (processes with same col_rank=0)
        // The process with row_rank=0 should be rank 0 in col_comm
        int col_comm_rank;
        MPI_Comm_rank(col_comm, &col_comm_rank);
        
        // Root is the process with row_rank=0 in col_comm, which is rank 0 in col_comm
        int root_in_col_comm = 0;
        
        MPI_Gatherv(row_result.data(), local_row_size, MPI_DOUBLE,
                    result.data(), recvcounts.data(), displs_gather.data(), MPI_DOUBLE,
                    root_in_col_comm, col_comm);
    }
    
    // Print result
    if (rank == 0) {
        for (int i = 0; i < m; i++) {
            printf("%.10f\n", result[i]);
        }
    }
    
    // Clean up communicators
    MPI_Comm_free(&row_comm);
    MPI_Comm_free(&col_comm);
    MPI_Comm_free(&cart_comm);
    // ==================================
    
    double elapsed_time = MPI_Wtime() - start_time;

    double max_elapsed_time;
    MPI_Reduce(&elapsed_time, &max_elapsed_time, 1, MPI_DOUBLE, MPI_MAX, 0, MPI_COMM_WORLD);
    
    // Only rank 0 reports the timing
    if (rank == 0) {
        printf("\n===== Benchmark Results =====\n");
        printf("Number of processes: %d\n", size);
        printf("Grid dimensions: %d x %d\n", p_rows, p_cols);
        printf("Highest elapsed time: %f seconds\n", max_elapsed_time);
        printf("============================\n");
    }
    
    MPI_Finalize();
    return 0;
}
