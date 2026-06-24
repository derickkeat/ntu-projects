#include <iostream>
#include <mpi.h>
#include <stdlib.h>
#include <cmath>
#include <vector>
#include <algorithm>

// Function to check if a number is prime
bool isPrime(long long num) {
    if (num < 2) return false;
    if (num == 2) return true;
    if (num % 2 == 0) return false;
    
    long long sqrt_num = sqrt(num);
    for (long long i = 3; i <= sqrt_num; i += 2) {
        if (num % i == 0) return false;
    }
    return true;
}

// Function to calculate 2^n
long long powerOf2(int n) {
    return 1LL << n;  // 2^n using bit shift
}

// Function to calculate perfect number using Euclid's formula
// If 2^n - 1 is prime, then (2^n - 1) * 2^(n-1) is perfect
long long calculatePerfectNumber(int n) {
    long long mersenne = powerOf2(n) - 1;
    if (isPrime(mersenne)) {
        return mersenne * powerOf2(n - 1);
    }
    return -1;  // Not a perfect number
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
    const int TARGET_COUNT = 8;
    std::vector<long long> local_perfect_numbers;
    
    // Each process checks different values of n
    // Start from n=2 (n=1 gives 1 which is not considered perfect)
    // We'll check up to a reasonable limit (n=31 gives numbers in long long range)
    int start_n = 2 + rank;
    int step = size;
    
    // Each process checks n values: start_n, start_n + step, start_n + 2*step, ...
    for (int n = start_n; n <= 31; n += step) {
        long long perfect = calculatePerfectNumber(n);
        if (perfect > 0) {
            local_perfect_numbers.push_back(perfect);
        }
    }
    
    // Gather all perfect numbers to rank 0
    if (rank == 0) {
        std::vector<long long> all_perfect_numbers;
        
        // Add local perfect numbers from rank 0
        all_perfect_numbers.insert(all_perfect_numbers.end(), 
                                   local_perfect_numbers.begin(), 
                                   local_perfect_numbers.end());
        
        // Receive perfect numbers from other processes
        for (int src = 1; src < size; src++) {
            int count;
            MPI_Status status;
            
            // Probe for message size
            MPI_Probe(src, 0, MPI_COMM_WORLD, &status);
            MPI_Get_count(&status, MPI_LONG_LONG_INT, &count);
            
            if (count > 0) {
                std::vector<long long> received(count);
                MPI_Recv(received.data(), count, MPI_LONG_LONG_INT, src, 0, 
                        MPI_COMM_WORLD, &status);
                all_perfect_numbers.insert(all_perfect_numbers.end(), 
                                           received.begin(), received.end());
            }
        }
        
        // Sort and display first 8 perfect numbers
        std::sort(all_perfect_numbers.begin(), all_perfect_numbers.end());
        
        printf("\nFirst %d perfect numbers:\n", TARGET_COUNT);
        int count = 0;
        for (size_t i = 0; i < all_perfect_numbers.size() && count < TARGET_COUNT; i++) {
            printf("%d. %lld\n", ++count, all_perfect_numbers[i]);
        }
        
        if (count < TARGET_COUNT) {
            printf("Note: Only found %d perfect numbers. May need to check larger n values.\n", count);
        }
    } else {
        // Send local perfect numbers to rank 0
        if (!local_perfect_numbers.empty()) {
            MPI_Send(local_perfect_numbers.data(), local_perfect_numbers.size(), 
                    MPI_LONG_LONG_INT, 0, 0, MPI_COMM_WORLD);
        } else {
            // Send empty message (count = 0)
            std::vector<long long> empty;
            MPI_Send(empty.data(), 0, MPI_LONG_LONG_INT, 0, 0, MPI_COMM_WORLD);
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