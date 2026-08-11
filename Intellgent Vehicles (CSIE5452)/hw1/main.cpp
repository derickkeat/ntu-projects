#include <iostream>
#include <math.h>

using namespace std;

float getRHS(float tau, float c[], int t[], int i, float b, float q){
  float sum = b;
  for(int j = 0; j < i; j++){
      sum += ceil((q + tau) / (float)t[j]) * c[j];
    }
  return sum;
}

int main(){
  int n;
  float b, tau, lhs, rhs;

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

  // for each message, calculate the worst case response time
  for(int i = 0; i < n; i++){
    b = 0;

    // get the largest transmission time (c) from messages that has lower or equal priority than the current message
    for(int j = i; j < n; j++){
      if(c[j] > b){
        b = c[j];
      }
    }
    lhs = b;

    rhs = getRHS(tau, c, t, i, b, lhs);

    while(lhs != rhs){
      if(rhs + c[i] > t[i]){
        cout << "Message " << i << " is not schedulable." << endl;
        break;
      }
      lhs = rhs;
      rhs = getRHS(tau, c, t, i, b, lhs);
    }

    if(lhs == rhs){
      cout << lhs + c[i] << endl;
    }
  }
}
