#include <iostream>
#include <mpi.h>
#include <stdlib.h>
#include <vector>
#include <fstream>
#include <string>
#include <algorithm>

// Count live neighbors for a cell at (i, j) in the grid
int countNeighbors(const std::vector<std::vector<int> >& grid, int i, int j, int m, int n) {
    int count = 0;
    for (int di = -1; di <= 1; di++) {
        for (int dj = -1; dj <= 1; dj++) {
            if (di == 0 && dj == 0) continue;
            int ni = i + di;
            int nj = j + dj;
            if (ni >= 0 && ni < m && nj >= 0 && nj < n) {
                count += grid[ni][nj];
            }
        }
    }
    return count;
}

// Print the grid
void printGrid(const std::vector<std::vector<int> >& grid, int m, int n, int iteration) {
    printf("Iteration %d:\n", iteration);
    for (int i = 0; i < m; i++) {
        for (int j = 0; j < n; j++) {
            printf("%c", grid[i][j] ? 'X' : '.');
        }
        printf("\n");
    }
    printf("\n");
}

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    // Check command-line arguments
    if (argc < 4) {
        if (rank == 0) {
            printf("Usage: %s <input_file> <j_iterations> <k_print_frequency>\n", argv[0]);
        }
        MPI_Finalize();
        return 1;
    }
    
    std::string input_file = argv[1];
    int j = atoi(argv[2]);  // Total iterations
    int k = atoi(argv[3]);  // Print every k iterations
    
    // Synchronize all processes before starting timer
    MPI_Barrier(MPI_COMM_WORLD);
    double start_time = MPI_Wtime();
    
    // ===== Your actual work here =====
    int m, n;  // Grid dimensions
    std::vector<std::vector<int> > full_grid;
    
    // Rank 0 reads the input file
    if (rank == 0) {
        std::ifstream file(input_file.c_str());
        if (!file.is_open()) {
            printf("Error: Cannot open file %s\n", input_file.c_str());
            MPI_Abort(MPI_COMM_WORLD, 1);
        }
        
        file >> m >> n;
        full_grid.resize(m, std::vector<int>(n));
        
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                file >> full_grid[i][j];
            }
        }
        file.close();
    }
    
    // Broadcast grid dimensions
    MPI_Bcast(&m, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&n, 1, MPI_INT, 0, MPI_COMM_WORLD);
    
    // Divide rows among processes
    int rows_per_process = m / size;
    int remainder = m % size;
    
    // Calculate local row range for this process
    int local_start_row = rank * rows_per_process + std::min(rank, remainder);
    int local_end_row = local_start_row + rows_per_process + (rank < remainder ? 1 : 0);
    int local_rows = local_end_row - local_start_row;
    
    // Allocate local grid with extra rows for ghost cells (top and bottom)
    std::vector<std::vector<int> > local_grid(local_rows + 2, std::vector<int>(n));
    std::vector<std::vector<int> > local_grid_next(local_rows + 2, std::vector<int>(n));
    
    // Scatter the grid to all processes
    std::vector<int> sendcounts(size);
    std::vector<int> displs(size);
    
    for (int i = 0; i < size; i++) {
        int start = i * rows_per_process + std::min(i, remainder);
        int end = start + rows_per_process + (i < remainder ? 1 : 0);
        sendcounts[i] = (end - start) * n;
        displs[i] = start * n;
    }
    
    // Scatter rows to each process
    std::vector<int> sendbuf;
    if (rank == 0) {
        sendbuf.resize(m * n);
        for (int i = 0; i < m; i++) {
            for (int j = 0; j < n; j++) {
                sendbuf[i * n + j] = full_grid[i][j];
            }
        }
    }
    
    std::vector<int> recvbuf(local_rows * n);
    MPI_Scatterv(rank == 0 ? &sendbuf[0] : NULL, &sendcounts[0], &displs[0], MPI_INT,
                 &recvbuf[0], local_rows * n, MPI_INT, 0, MPI_COMM_WORLD);
    
    // Copy received data to local grid (skip ghost rows)
    for (int i = 0; i < local_rows; i++) {
        for (int j = 0; j < n; j++) {
            local_grid[i + 1][j] = recvbuf[i * n + j];
        }
    }
    
    // Print initial state
    if (rank == 0) {
        printGrid(full_grid, m, n, 0);
    }
    
    // Main simulation loop
    for (int iter = 1; iter <= j; iter++) {
        // Exchange boundary rows with neighbors
        // We need to exchange with both neighbors simultaneously to avoid deadlock
        int top_neighbor = (rank > 0) ? rank - 1 : MPI_PROC_NULL;
        int bottom_neighbor = (rank < size - 1) ? rank + 1 : MPI_PROC_NULL;
        
        // Exchange boundary rows with neighbors
        // We use different tags for up and down to avoid conflicts
        // Tag 0: sending down (from rank i to rank i+1)
        // Tag 1: sending up (from rank i to rank i-1)
        
        // Exchange with bottom neighbor (rank i+1)
        // We send our last real row, they send their first real row
        if (bottom_neighbor != MPI_PROC_NULL) {
            MPI_Sendrecv(&local_grid[local_rows][0], n, MPI_INT, bottom_neighbor, 0,
                        &local_grid[local_rows + 1][0], n, MPI_INT, bottom_neighbor, 1,
                        MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        } else {
            // No bottom neighbor, ghost row stays 0 (fixed boundary)
            std::fill(local_grid[local_rows + 1].begin(), local_grid[local_rows + 1].end(), 0);
        }
        
        // Exchange with top neighbor (rank i-1)
        // We send our first real row, they send their last real row
        if (top_neighbor != MPI_PROC_NULL) {
            MPI_Sendrecv(&local_grid[1][0], n, MPI_INT, top_neighbor, 1,
                        &local_grid[0][0], n, MPI_INT, top_neighbor, 0,
                        MPI_COMM_WORLD, MPI_STATUS_IGNORE);
        } else {
            // No top neighbor, ghost row stays 0 (fixed boundary)
            std::fill(local_grid[0].begin(), local_grid[0].end(), 0);
        }
        
        // Compute next state for local rows (excluding ghost rows)
        for (int i = 1; i <= local_rows; i++) {
            for (int j = 0; j < n; j++) {
                int neighbors = countNeighbors(local_grid, i, j, local_rows + 2, n);
                int current = local_grid[i][j];
                
                if (current == 0) {
                    // Dead cell: becomes alive if exactly 3 neighbors
                    local_grid_next[i][j] = (neighbors == 3) ? 1 : 0;
                } else {
                    // Live cell: stays alive if 2 or 3 neighbors, dies otherwise
                    local_grid_next[i][j] = (neighbors == 2 || neighbors == 3) ? 1 : 0;
                }
            }
        }
        
        // Swap grids
        std::swap(local_grid, local_grid_next);
        
        // Print state every k iterations
        if (iter % k == 0 || iter == j) {
            // Gather full grid to rank 0
            std::vector<int> gatherbuf;
            if (rank == 0) {
                gatherbuf.resize(m * n);
            }
            
            // Prepare data to send (excluding ghost rows)
            std::vector<int> send_data(local_rows * n);
            for (int i = 0; i < local_rows; i++) {
                for (int j = 0; j < n; j++) {
                    send_data[i * n + j] = local_grid[i + 1][j];
                }
            }
            
            MPI_Gatherv(&send_data[0], local_rows * n, MPI_INT,
                       rank == 0 ? &gatherbuf[0] : NULL, &sendcounts[0], &displs[0], MPI_INT,
                       0, MPI_COMM_WORLD);
            
            // Rank 0 reconstructs and prints the grid
            if (rank == 0) {
                for (int i = 0; i < m; i++) {
                    for (int j = 0; j < n; j++) {
                        full_grid[i][j] = gatherbuf[i * n + j];
                    }
                }
                printGrid(full_grid, m, n, iter);
            }
        }
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