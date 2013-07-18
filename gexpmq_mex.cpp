/** 
 * @file gexpm_mex.cpp
 * @author Kyle Kloster, David F. Gleich
 */

/**
 * This file implements an approximate gauss-southwell method using a Queue
 * instead of a heap to approximate the largest element for the truncated 
 * taylor series approximation for a column of the matrix exponential
 */

#include "mex.h"
#include <queue>
#include <vector>
#include <assert.h>
#include <math.h>

/** A replacement for std::queue<int> using a circular buffer array */
class array_queue {
    public:
    size_t max_size;
    std::vector<int> array;
    size_t head, tail;
    size_t cursize;
    array_queue(size_t _max_size)
    : max_size(_max_size), array(_max_size), head(0), tail(0), cursize(0)
    {}
    
    void empty() {
        head = 0;
        tail = 0;
        cursize = 0;
    }
    
    size_t size() {
        return cursize;
    }
    
    void push(int i) {
        assert(size() < max_size);
        array[tail] = i;
        tail ++;
        if (tail == max_size) {
            tail = 0;
        }
        cursize ++;
    }
    
    int front() {
        assert(size() > 0);
        return array[head];
    }
    
    void pop() {
        assert(size() > 0);
        head ++;
        if (head == max_size) {
            head = 0;
        }
        cursize --;
    }
};

/**
 * @param n - sparse matrix size
 * @param cp - sparse matrix column pointer (CSC)
 * @param ari - sparse matrix row index (CSC)
 * @param a - sparse matrix values (CSC)
 * @param c - the column index to approximate (0 <= c < n)
 * @param N - the number of steps (1 <= N < Inf)
 * @param tol - the stopping tolerance (0 < tol < Inf)
 * @param maxsteps - the maximum number of steps to take (1 <= maxsteps < Inf)
 * @param y - the output vector (length n)
 * @param nsteps - the number of output steps (length 1)
 */
void gexpmq(const mwSize n, const mwIndex* cp, const mwIndex* ari, const double* a, 
            const mwIndex c, const mwIndex N,  const double tol, const mwIndex maxsteps, 
            double* y, double *nsteps, double *npushes)
{
    //mexPrintf("Input n=%i N=%i c=%i tol=%i maxsteps=%i\n", n, N, c, tol, maxsteps);
    mwIndex M = n*N;
    double sumresid = 0.;
    double sumsol = -M_E;
    
    // allocate data 
    std::vector<double> rvec(M,0.);
    double *r = &rvec[0];
    
    std::queue<mwIndex> Q;
    
    // i is the node index, j is the "step"
    #define rentry(i,j) ((i)+(j)*n)
    
    // mexPrintf("Init...\n");
 
    // set the initial residual, add to the heap, and update
    r[rentry(c,0)] = 1;
    sumresid += 1.;
    Q.push(rentry(c,0));
    
    mwIndex npush = 0;
    *nsteps = (double)maxsteps; // set the default, which we change on early exit
    
    //mexPrintf("Loop...\n");
    
    for (mwIndex iter = 0; iter < maxsteps; ++iter) {
        
        /* STEP 1: pop top element off of heap
         *  * get indices i,j from T
         *  * add r(i,j) to y(i)
         *  * set r(i,j) to zero (update sumresid)
         * STEP 2: get i^th column from A
         *  * get neighbors of ith node
         *  * (if j == N-1), add the column to y instead of r.
         *  * add as a column to next time-step of r, and update heap
         *  *  (update sumresid)
         * Check for convegence!
        */
        
        // STEP 1: pop top element off of heap
        mwIndex ri = Q.front();
        Q.pop();
        
        // decode incides i,j
        mwIndex i = ri%n;
        mwIndex j = ri/n;
        
        double rij = r[ri];
        
        // update yi
        y[i] += rij;
        
        // update r, no need to update heap here 
        r[ri] = 0;
        sumresid -= rij;
        double rijs = rij/(double)(j+1);
        
        if (j == N-1) {
            // this is the terminal case, and so we add the column of A 
            // directly to the solution vector y
            for (mwIndex nzi=cp[i]; nzi < cp[i+1]; ++nzi) {
                mwIndex v = ari[nzi];
                double ajv = a[nzi];
                y[v] += ajv*rijs;
                sumsol += ajv*rijs;
            }
            npush+=cp[i+1]-cp[i];
        } else {
            // this is the interior case, and so we add the column of A 
            // to the residual at the next time step.
            for (mwIndex nzi=cp[i]; nzi < cp[i+1]; ++nzi) {
                mwIndex v = ari[nzi];
                double ajv = a[nzi];
                mwIndex re = rentry(v,j+1);
                double reold = r[re];
                r[re] += ajv*rijs;
                sumresid += ajv*rijs;
                sumsol += ajv*rijs;
                
                if (r[re] > tol/(n*N)) {
                    if (reold < tol/(n*N)) {
                        Q.push(re);
                    }
                }
            }
            npush+=cp[i+1]-cp[i];
        }
        
        
        if (sumresid < tol || Q.size() == 0 || sumsol > -tol ) {
            *nsteps = (double)iter;
            break;
        }
    }
    
    *npushes = (double)npush;
    
    return; // because we "break" out of for loop
}

void mexFunction(
  int nargout, mxArray *pargout[],       // these are your outputs
  int nargin, const mxArray *pargin[])   // these are your arguments
{
    // inputs
    // A - sparse n-by-n
    // c - integer scalar 1 <= c <= n
    // N - integer scalar 1 <= N <= Inf
    // tol - double value, 0 < tol < Inf
    // maxsteps - integer scalar max-steps 
    
    const mxArray* A = pargin[0];
    mwIndex c = (mwIndex)mxGetScalar(pargin[1])-1;
    mwIndex N = (mwIndex)mxGetScalar(pargin[2]);
    double tol = mxGetScalar(pargin[3]);
    mwIndex maxsteps = (mwIndex)mxGetScalar(pargin[4]);
    
    mwSize n = mxGetM(A);
    pargout[0] = mxCreateDoubleMatrix(n,1,mxREAL);
    pargout[1] = mxCreateDoubleMatrix(1,1,mxREAL);
    pargout[2] = mxCreateDoubleMatrix(1,1,mxREAL);
    
    // decode the sparse matrix
    mwIndex* cp = mxGetJc(A);
    mwIndex* ri = mxGetIr(A);
    double* a = mxGetPr(A);
    
    double* y = mxGetPr(pargout[0]);
    double* nsteps = mxGetPr(pargout[1]);
    double* npushes = mxGetPr(pargout[2]);
    
    // mexPrintf("Starting call \n");
    
    mxAssert(N > 0, "N must be bigger than 0");
    mxAssert(tol > 0 && tol <= 1, "tol must be 0 < tol <= 1");
    mxAssert(c >= 0 && c < n, "column c must be 1 <= c <= n");
    mxAssert(maxsteps > 0, "we must have maxsteps >= 0");
    
    gexpmq(n, cp, ri, a, // sparse matrix
           c, N, tol, maxsteps, // parameters
           y, nsteps, npushes);
    
}
    
    
  