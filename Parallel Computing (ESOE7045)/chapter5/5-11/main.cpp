#include <iostream>
#include <mpi.h>
#include <stdlib.h>
#include <gmp.h>
#include <cstring>

int main(int argc, char** argv) {
    MPI_Init(&argc, &argv);
    
    int rank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);
    
    // Synchronize all processes before starting timer
    MPI_Barrier(MPI_COMM_WORLD);
    double start_time = MPI_Wtime();
    
    // ===== Your actual work here =====
    int n = 0, d = 0;
    
    // Process 0 gets n and d from command-line arguments or user input
    if (rank == 0) {
        if (argc >= 3) {
            // Get from command-line arguments
            n = atoi(argv[1]);
            d = atoi(argv[2]);
        } else {
            // Fall back to interactive input
            std::cout << "Enter n (number of terms): ";
            std::cin >> n;
            std::cout << "Enter d (digits of precision after decimal point): ";
            std::cin >> d;
        }
    }
    
    // Broadcast n and d to all processes
    MPI_Bcast(&n, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(&d, 1, MPI_INT, 0, MPI_COMM_WORLD);
    
    // Calculate precision in bits: d decimal digits requires at least d*log2(10) bits
    // Using d*4 bits to be safe, plus extra for intermediate calculations
    mp_bitcnt_t precision_bits = (mp_bitcnt_t)(d * 4 + 64);
    
    // Initialize GMP floating point variables
    mpf_t local_sum, term, one;
    mpf_init2(local_sum, precision_bits);
    mpf_init2(term, precision_bits);
    mpf_init2(one, precision_bits);
    mpf_set_ui(local_sum, 0);
    mpf_set_ui(one, 1);
    
    // Distribute work among processes
    // Each process computes sum(1/i) for its assigned range
    int local_n = n / size;
    int remainder = n % size;
    int start_i = rank * local_n + (rank < remainder ? rank : remainder) + 1;
    int end_i = start_i + local_n + (rank < remainder ? 1 : 0);
    
    // Compute local partial sum
    for (int i = start_i; i < end_i; i++) {
        mpf_set_ui(term, i);
        mpf_div(term, one, term);  // term = 1/i
        mpf_add(local_sum, local_sum, term);  // local_sum += 1/i
    }
    
    // Process 0 receives all partial sums and combines them
    // Each process sends its local_sum as a properly formatted decimal string
    mpf_t global_sum;
    
    if (rank == 0) {
        mpf_init2(global_sum, precision_bits);
        mpf_set(global_sum, local_sum);  // Start with rank 0's partial sum
        
        // Receive and add partial sums from other processes
        mpf_t received_sum;
        mpf_init2(received_sum, precision_bits);
        
        for (int src = 1; src < size; src++) {
            int recv_len;
            mp_exp_t recv_exp;
            size_t str_size = d + 100;
            char* recv_str = new char[str_size];
            
            // Receive string length, exponent, and string
            MPI_Recv(&recv_len, 1, MPI_INT, src, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            MPI_Recv(&recv_exp, 1, MPI_LONG, src, 1, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            MPI_Recv(recv_str, recv_len, MPI_CHAR, src, 2, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
            recv_str[recv_len - 1] = '\0';  // Ensure null termination
            
            // Construct proper decimal string from digits and exponent
            char* decimal_str = new char[recv_len + 100];
            int digits_len = strlen(recv_str);
            
            if (recv_exp <= 0) {
                // Number < 1, format as "0.000...digits"
                strcpy(decimal_str, "0.");
                for (int i = 0; i < -recv_exp; i++) {
                    strcat(decimal_str, "0");
                }
                strcat(decimal_str, recv_str);
            } else {
                // Number >= 1, insert decimal point at position recv_exp
                int j = 0;
                for (int i = 0; i < digits_len; i++) {
                    if (i == recv_exp) {
                        decimal_str[j++] = '.';
                    }
                    decimal_str[j++] = recv_str[i];
                }
                // If decimal point wasn't inserted, add it at the end
                if (recv_exp >= digits_len) {
                    for (int i = digits_len; i < recv_exp; i++) {
                        decimal_str[j++] = '0';
                    }
                    decimal_str[j++] = '.';
                }
                decimal_str[j] = '\0';
            }
            
            mpf_set_str(received_sum, decimal_str, 10);
            mpf_add(global_sum, global_sum, received_sum);
            
            delete[] decimal_str;
            delete[] recv_str;
        }
        
        mpf_clear(received_sum);
    } else {
        // Other processes send their partial sums to process 0
        size_t str_size = d + 100;
        char* send_str = new char[str_size];
        mp_exp_t exp;
        mpf_get_str(send_str, &exp, 10, d + 20, local_sum);
        int str_len = strlen(send_str) + 1;
        
        // Send string length, exponent, and string
        MPI_Send(&str_len, 1, MPI_INT, 0, 0, MPI_COMM_WORLD);
        MPI_Send(&exp, 1, MPI_LONG, 0, 1, MPI_COMM_WORLD);
        MPI_Send(send_str, str_len, MPI_CHAR, 0, 2, MPI_COMM_WORLD);
        
        delete[] send_str;
        mpf_init2(global_sum, 1);  // Dummy init, won't be used
    }
    
    // Print the result (only on process 0)
    if (rank == 0) {
        // Print the result with d digits after decimal point
        // Request d+1 digits to ensure we have enough precision
        char* result_str = new char[d + 50];
        mp_exp_t exp;
        mpf_get_str(result_str, &exp, 10, d + 1, global_sum);
        
        std::cout << "\nS_" << n << " = ";
        
        int str_len = strlen(result_str);
        
        if (exp <= 0) {
            // Number is less than 1
            std::cout << "0.";
            // Add leading zeros
            for (int i = 0; i < -exp; i++) {
                std::cout << "0";
            }
            // Print the digits
            for (int i = 0; i < str_len && i < d; i++) {
                std::cout << result_str[i];
            }
            // Pad with zeros if needed
            int printed = str_len < d ? str_len : d;
            for (int i = printed; i < d; i++) {
                std::cout << "0";
            }
        } else {
            // Number is >= 1
            // Print integer part (first exp digits)
            int int_digits = exp;
            int digits_to_print = int_digits < str_len ? int_digits : str_len;
            for (int i = 0; i < digits_to_print; i++) {
                std::cout << result_str[i];
            }
            // If we need more integer digits, pad with zeros
            for (int i = digits_to_print; i < int_digits; i++) {
                std::cout << "0";
            }
            std::cout << ".";
            // Print fractional part (remaining digits)
            int frac_start = int_digits;
            int frac_digits = str_len - frac_start;
            int frac_to_print = frac_digits < d ? frac_digits : d;
            for (int i = frac_start; i < frac_start + frac_to_print; i++) {
                std::cout << result_str[i];
            }
            // Pad fractional part with zeros if needed
            for (int i = frac_to_print; i < d; i++) {
                std::cout << "0";
            }
        }
        std::cout << std::endl;
        
        // Cleanup
        delete[] result_str;
        mpf_clear(global_sum);
    } else {
        mpf_clear(global_sum);
    }
    
    // Cleanup
    mpf_clear(local_sum);
    mpf_clear(term);
    mpf_clear(one);
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