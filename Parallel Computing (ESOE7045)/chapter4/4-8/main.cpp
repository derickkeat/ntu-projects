#include <iostream>
#include <mpi.h>
#include <stdlib.h>
#include <vector>
#include <cmath>
#include <algorithm>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    // Synchronize all processes before starting timer
    MPI_Barrier(MPI_COMM_WORLD);
    double start_time = MPI_Wtime();
    
    // ===== Your actual work here =====
    int n = 1000000;  // Find primes up to n
    int sqrt_n = (int)sqrt((double)n);
    
    // Step 1: Rank 0 finds all primes up to sqrt(n) using sequential sieve
    std::vector<int> seed_primes;
    if (rank == 0) {
        std::vector<int> arr(sqrt_n + 1, 0);
        arr[0] = 1;
        arr[1] = 1;
        
        for (int k = 2; k * k <= sqrt_n; k++) {
            if (arr[k] == 0) {
                for (int i = k * k; i <= sqrt_n; i += k) {
                    arr[i] = 1;
                }
            }
        }
        
        // Collect seed primes
        for (int i = 2; i <= sqrt_n; i++) {
            if (arr[i] == 0) {
                seed_primes.push_back(i);
            }
        }
    }
    
    // Step 2: Broadcast the number of seed primes and the primes themselves
    int num_seed_primes = seed_primes.size();
    MPI_Bcast(&num_seed_primes, 1, MPI_INT, 0, MPI_COMM_WORLD);
    
    if (rank != 0) {
        seed_primes.resize(num_seed_primes);
    }
    MPI_Bcast(seed_primes.data(), num_seed_primes, MPI_INT, 0, MPI_COMM_WORLD);
    
    // Step 3: Divide the range [sqrt_n+1, n) among processes
    int range_start = sqrt_n + 1;
    int range_size = n - range_start;
    int block_size = range_size / size;
    int remainder = range_size % size;
    
    // Calculate this process's range
    int local_start = range_start + rank * block_size + std::min(rank, remainder);
    int local_end = local_start + block_size + (rank < remainder ? 1 : 0);
    int local_size = local_end - local_start;
    
    // Step 4: Each process marks composites in its local range
    std::vector<int> local_arr(local_size, 0);
    
    for (int p = 0; p < num_seed_primes; p++) {
        int prime = seed_primes[p];
        // Find the first multiple of prime >= local_start
        int start = ((local_start + prime - 1) / prime) * prime;
        if (start == prime) start += prime;  // Don't mark the prime itself
        
        // Mark all multiples in local range
        for (int i = start; i < local_end; i += prime) {
            local_arr[i - local_start] = 1;
        }
    }
    
    // Step 5: Collect local primes
    std::vector<int> local_primes;
    for (int i = 0; i < local_size; i++) {
        if (local_arr[i] == 0) {
            local_primes.push_back(local_start + i);
        }
    }
    
    // Step 6: Gather all primes to rank 0
    // First, gather the counts
    int local_prime_count = local_primes.size();
    std::vector<int> all_prime_counts(size);
    MPI_Gather(&local_prime_count, 1, MPI_INT, all_prime_counts.data(), 1, MPI_INT, 0, MPI_COMM_WORLD);
    
    // Calculate displacements for Gatherv
    std::vector<int> displacements(size, 0);
    int total_primes = 0;
    if (rank == 0) {
        for (int i = 0; i < size; i++) {
            displacements[i] = total_primes;
            total_primes += all_prime_counts[i];
        }
    }
    
    // Gather all primes
    std::vector<int> all_primes;
    if (rank == 0) {
        all_primes.resize(total_primes);
    }
    MPI_Gatherv(local_primes.data(), local_prime_count, MPI_INT,
                all_primes.data(), all_prime_counts.data(), displacements.data(), MPI_INT,
                0, MPI_COMM_WORLD);
    
    // Step 7: Rank 0 counts twin primes (consecutive odd integers both prime)
    if (rank == 0) {
        // Combine seed primes and gathered primes
        std::vector<int> all_primes_combined = seed_primes;
        all_primes_combined.insert(all_primes_combined.end(), all_primes.begin(), all_primes.end());
        
        // Count twin primes: pairs (p, p+2) where both are prime
        int twin_prime_count = 0;
        
        // Special case: check (2, 3) - not consecutive odd, but consecutive primes
        // But user wants consecutive ODD integers, so skip this
        
        for (size_t i = 0; i < all_primes_combined.size() - 1; i++) {
            int p1 = all_primes_combined[i];
            int p2 = all_primes_combined[i + 1];
            
            // Check if they are consecutive odd integers (differ by 2)
            if (p2 - p1 == 2) {
                twin_prime_count++;
            }
        }
        
        std::cout << "Total primes found: " << all_primes_combined.size() << "\n";
        std::cout << "Twin prime pairs found: " << twin_prime_count << "\n";
        
        // Print first few twin prime pairs as examples
        std::cout << "\nFirst 10 twin prime pairs:\n";
        int count = 0;
        for (size_t i = 0; i < all_primes_combined.size() - 1 && count < 10; i++) {
            int p1 = all_primes_combined[i];
            int p2 = all_primes_combined[i + 1];
            if (p2 - p1 == 2) {
                std::cout << "  (" << p1 << ", " << p2 << ")\n";
                count++;
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