#include <iostream>
#include <cmath>
#include <limits>
#include <algorithm>
#include <random>
#include <chrono>

using namespace std;

float getRHS(float tau, float c[], int t[], int i, float b, float q){
  float sum = b;
  for(int j = 0; j < i; j++){
      sum += ceil((q + tau) / (float)t[j]) * c[j];
    }
  return sum;
}

float calcResponseTime(int n, int i, float tau, float c[], int t[]){
  float b = 0;

  // get the largest transmission time (c) from messages that has lower or equal priority than the current message
  for(int j = i; j < n; j++){
    if(c[j] > b){
      b = c[j];
    }
  }
  float lhs = b;

  float rhs = getRHS(tau, c, t, i, b, lhs);

  while(lhs != rhs){
    if(rhs + c[i] > t[i]){
      // cout << "Message " << i << " is not schedulable." << endl;
      return numeric_limits<float>::infinity();
    }
    lhs = rhs;
    rhs = getRHS(tau, c, t, i, b, lhs);
  }

  return lhs + c[i];
}

float costFunction(int n, float tau, float c[], int t[]){
  float sum = 0;
  for(int i = 0; i < n; i++){
    sum += calcResponseTime(n, i, tau, c, t);
  }
  return sum;
}

int main(){
  auto start = chrono::high_resolution_clock::now();

  int n;
  float tau;

  cin >> n;
  cin >> tau;

  // p = priority
  // c = transmission time
  // t = period
  int p[n];
  float c[n];
  int t[n];

  // put the data into arrays
  for(int i = 0; i < n; i++){
    cin >> p[i] >> c[i] >> t[i];
  }

  // create an array of numbers from 0 to n-1
  int idx[n];
  for(int i = 0; i < n; i++){
    idx[i] = i;
  }

  // start the simulated annealing algorithm
  float temperature = 1000;
  int S[n], S_star[n];
  float c_star[n];
  int t_star[n];
  copy(p, p + n, S);
  // S_star is the best solution found so far
  copy(S, S + n, S_star);
  copy(c, c + n, c_star);
  copy(t, t + n, t_star);
  float best_cost = costFunction(n, tau, c_star, t_star);

  mt19937 rng(42);
  uniform_real_distribution<float> dist(0.0f, 1.0f);

  // iterate part
  while(temperature > 1){
    // pick a random neighbor S' of S (from current S, not S_star)
    int S_prime[n];
    float c_prime[n];
    int t_prime[n];
    int swap_index[2];
    sample(idx, idx + n, swap_index, 2, rng);
    copy(S, S + n, S_prime);
    copy(c, c + n, c_prime);
    copy(t, t + n, t_prime);
    swap(S_prime[swap_index[0]], S_prime[swap_index[1]]);
    swap(c_prime[swap_index[0]], c_prime[swap_index[1]]);
    swap(t_prime[swap_index[0]], t_prime[swap_index[1]]);

    float cost_S = costFunction(n, tau, c, t);
    float cost_prime = costFunction(n, tau, c_prime, t_prime);
    float delta_cost = cost_prime - cost_S;

    if(cost_prime < best_cost){
      copy(S_prime, S_prime + n, S_star);
      copy(c_prime, c_prime + n, c_star);
      copy(t_prime, t_prime + n, t_star);
      best_cost = cost_prime;
    }

    if(delta_cost <= 0){
      copy(S_prime, S_prime + n, S);
      copy(c_prime, c_prime + n, c);
      copy(t_prime, t_prime + n, t);
    } else {
      float probability = exp(-delta_cost / temperature);
      if(probability > dist(rng)){
        copy(S_prime, S_prime + n, S);
        copy(c_prime, c_prime + n, c);
        copy(t_prime, t_prime + n, t);
      }
    }
    temperature *= 0.999;
  }
  int result[n];
  for(int v = 0; v < n; v++){
    for(int i = 0; i < n; i++){
      if(S_star[i] == v){
        result[v] = i;
        break;
      }
    }
  }
  for(int i = 0; i < n; i++){
    cout << result[i] << "\n";
  }
  cout << "Best cost: " << best_cost << "\n";

  auto end = chrono::high_resolution_clock::now();
  double elapsed = chrono::duration<double, milli>(end - start).count();
  cout << "Time: " << elapsed << " ms\n";
}
