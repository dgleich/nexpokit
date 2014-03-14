/** 
 * @file gexpm_mex.cpp
 * @author Kyle Kloster, David F. Gleich
 */

/**
 * This file implements a gauss-southwell type method for the truncated 
 * taylor series approximation for a column of the matrix exponential
 */



#include <vector>
#include <queue>
#include <utility> // for pair sorting
#include <assert.h>
#include <limits>
#include <algorithm>
#include <math.h>

#include "sparseheap.hpp" // include our heap functions

#include "mex.h"


#define DEBUGPRINT(x) do { if (debugflag) { \
mexPrintf x; mexEvalString("drawnow"); } \
} while (0)

int debugflag = 0;

struct sparsevec {
    typedef tr1ns::unordered_map<mwIndex,double> map_type;
    map_type map;
    /** Get an element and provide a default value when it doesn't exist
     * This command does not insert the element into the vector
     */
    double get(mwIndex index, double default_value=0.0) {
        map_type::iterator it = map.find(index);
        if (it == map.end()) {
            return default_value;
        } else {
            return it->second;
        }
    }
    
    /** Compute the sum of all the elements
     * Implements compensated summation
     */
    double sum() {
        double s=0.;
        for (map_type::iterator it=map.begin(),itend=map.end();it!=itend;++it) {
            s += it->second;
        }
        return s;
    }
    
    /** Compute the max of the element values
     * This operation returns the first element if the vector is empty.
     */
    mwIndex max_index() {
        mwIndex index=0;
        double maxval=std::numeric_limits<double>::min();
        for (map_type::iterator it=map.begin(),itend=map.end();it!=itend;++it) {
            if (it->second>maxval) { maxval = it->second; index = it->first; }
        }
        return index;
    }
};


/**
 * Computes the degree N for the Taylor polynomial
 * of exp(tP) to have error less than eps*exp(t)
 *
 * ( so exp(-t(I-P)) has error less than eps )
 */
unsigned int taylordegree(const double t, const double eps) {
    double eps_exp_t = eps*exp(t);
    double error = exp(t)-1;
    double last = 1.;
    double k = 0.;
    while(error > eps_exp_t){
        k = k + 1.;
        last = (last*t)/k;
        error = error - last;
    }
    return std::max((int)k, (int)1);
}


struct sparserow {
    mwSize n, m;
    mwIndex *ai;
    mwIndex *aj;
    double *a;
};


/**
 * Returns the degree of node u in sparse graph s
 */
mwIndex sr_degree(sparserow *s, mwIndex u) {
    return (s->ai[u+1] - s->ai[u]);
}


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

void gexpm(sparserow* G, std::vector<mwIndex>& set, sparsevec& y,
           const double t, const double eps,
           double* npushes, double* nsteps, const mwIndex maxsteps)
{
    mwIndex N = taylordegree(t,eps);
    mwIndex n = G->n;

    DEBUGPRINT( ("Input n=%i N=%i tol=%f maxsteps=%i\n", n, N, eps, maxsteps) );
    
    std::vector<double> psivec(N+1,0.);
    psivec[N] = 1;
    for (mwIndex k = 1; k <= N ; k++){
        psivec[N-k] = psivec[N-k+1]*t/(double)(N-k+1) + 1;
    } // now psivec[k] = psi_k(t)
    

/**
 *  prepare the RESIDUAL heap
 */
    // i is the node index, j is the "step"
#define rentry(i,j) ((i)+(j)*n)
    double sumresid = 0.;
    mwIndex ri;
    double rij = 0.;
    sparsemaxheap r;
    r.hsize=0;

     // set the initial residual
    for (size_t i=0; i<set.size(); ++i) {
        ri = set[i];
        rij = 1.;
        sumresid += rij;
        r.update(rentry(ri,0),rij); // "update" handles the heap as well
    }
    DEBUGPRINT(("gexpm_hash: hsize = %i \n", r.hsize));
    *npushes = 0;
        DEBUGPRINT(("gexpm_hash: enter for loop \n"));
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
        // "extractmax" sets the entry to 0, stores the value in rij,
        // the index in ri, removes the entry from the heap, then reheaps.
        ri = r.extractmax(rij);
        sumresid -= rij;
DEBUGPRINT(("gexpm_hash: hsize = %i , iter = %i,  sumresid = %.8f,  rij = %.8f \n", r.hsize, iter, sumresid, rij));
        // decode incides i,j
        mwIndex i = ri%n;
        mwIndex j = ri/n;

        // update yi
        y.map[i] += rij;

        double degofi = (double)sr_degree(G,i);
        double rijs = t*rij/(double)(j+1);
        double ajv = 1./degofi;
        double update = rijs*ajv;
        
        if (j == N-1) {
            // this is the terminal case, and so we add the column of A 
            // directly to the solution vector y
            for (mwIndex nzi=G->ai[i]; nzi < G->ai[i+1]; ++nzi){
                mwIndex v = G->aj[nzi];
                y.map[v] += update; // in general case, update = ajv*rijs
            }
            *npushes += degofi;
        } else {
            // this is the interior case, and so we add the column of A 
            // to the residual at the next time step.
            for (mwIndex nzi=G->ai[i]; nzi < G->ai[i+1]; ++nzi) {
                mwIndex v = G->aj[nzi];
                mwIndex re = rentry(v,j+1);
                r.update(re,update); // handles the heap internally
                //                r[re] += ajv*rijs;
                sumresid += update;
            }
            *npushes += degofi;
        }
        if (sumresid < eps/exp(t) || r.hsize == 0) {
            DEBUGPRINT(("gexpm_hash: BREAK: hsize = %i , iter = %i,  sumresid = %.8f,  rij = %.8f \n", r.hsize, iter, sumresid, rij));
            *nsteps = (double)iter;
            break;
        }
    }
    return; // because we "break" out of for loop
}


void copy_array_to_index_vector(const mxArray* v, std::vector<mwIndex>& vec)
{
    mxAssert(mxIsDouble(v), "array type is not double");
    size_t n = mxGetNumberOfElements(v);
    double *p = mxGetPr(v);
    
    vec.resize(n);
    
    for (size_t i=0; i<n; ++i) {
        double elem = p[i];
        mxAssert(elem >= 1, "Only positive integer elements allowed");
        vec[i] = (mwIndex)elem - 1;
    }
}


// USAGE
// [y npushes nsteps] = gexpm_hash_mex(A,set,eps,t,debugflag,maxsteps)
void mexFunction(int nlhs, mxArray* plhs[], int nrhs, const mxArray* prhs[])
{
    if (nrhs < 2 || nrhs > 5) {
        mexErrMsgIdAndTxt("gexpm_hash_mex:wrongNumberArguments",
                          "gexpm_hash_mex needs two to five arguments, not %i", nrhs);
    }
    mxAssert(nlhs <= 3, "Too many output arguments");
    if (nrhs == 5) {
        debugflag = (int)mxGetScalar(prhs[4]);
    }
    DEBUGPRINT(("\n gexpm_hash_mex: preprocessing start: \n"));
    
    const mxArray* mat = prhs[0];
    const mxArray* set = prhs[1];
    
    mxAssert(mxIsSparse(mat), "Input matrix is not sparse");
    mxAssert(mxGetM(mat) == mxGetN(mat), "Input matrix not square");
    
    double* npushes = 0;
    double* nsteps = 0;
    if (nlhs > 1){
        plhs[1] = mxCreateDoubleMatrix(1,1,mxREAL);
        npushes = mxGetPr(plhs[1]);
    }
    if (nlhs > 2){
        plhs[2] = mxCreateDoubleMatrix(1,1,mxREAL);
        nsteps = mxGetPr(plhs[2]);
    }
    
    double eps = pow(10,-5);
    double t = 1.;
    
    if (nrhs >= 4) { t = mxGetScalar(prhs[3]); }
    if (nrhs >= 3) { eps = mxGetScalar(prhs[2]); }
    
    sparserow G;
    G.m = mxGetM(mat);
    G.n = mxGetN(mat);
    G.ai = mxGetJc(mat);
    G.aj = mxGetIr(mat);
    G.a = mxGetPr(mat);

    mwIndex maxsteps = G.n;
    if (nrhs >= 6){
        maxsteps = (mwIndex)mxGetScalar(prhs[5]);
    }

    std::vector< mwIndex > seeds;
    copy_array_to_index_vector( set, seeds );
    sparsevec hk;
    
    DEBUGPRINT(("gexpm_hash_mex: preprocessing end: \n"));
    
    gexpm(&G, seeds, hk, t, eps, npushes, nsteps, maxsteps);
    
    DEBUGPRINT(("gexpm_hash_mex: call to gexpm_hash() done\n"));
    
    if (nlhs > 0) { // sets output "hk" to the heat kernel vector computed
        mxArray* hkvec = mxCreateDoubleMatrix(G.n,1,mxREAL);
        plhs[0] = hkvec;
        double *ci = mxGetPr(hkvec);
        for (sparsevec::map_type::iterator it=hk.map.begin(),itend=hk.map.end();
             it!=itend;++it) {
            ci[it->first] = it->second;
        }
    }
}