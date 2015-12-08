/* The main entry is the gateway function "mexFunction". The actual
   algorithm implementation is in the "evaluateResidual" function. */

/* Includes */
#include "residual.h"
#include "mex.h"

using namespace std;

/* General */
#define    VERBOSE 1

/* Inputs */
#define    X_IN	prhs[0]     // x data
#define    Y_IN	prhs[1]     // y data
#define    T_IN	prhs[2]     // time data
#define    D_IN	prhs[3]     // displacement data
//#define		AL_IN	prhs[4]		// array with accumulator limits and steps
#define    AXV_IN  prhs[4]   // accumulator x values
#define    AYV_IN  prhs[5]   // accumulator y values
#define    ASV_IN  prhs[6]   // accumulator sigma values
#define    AAV_IN  prhs[7]   // accumulator amplitude values


/* Outputs */
#define    A_OUT   plhs[0]   // accumulators array
#define    C_OUT   plhs[1]   // counts array

/*
%    Gateway function
%
%    The function in MATLAB looks like:
%        [acc,cnt]=residual(x,y,t,d,xac,yac,sig,amp)
%    where
%        acc is the accumulators array
%            [[<1sig];[1sig<acc<2sig];[2sig<acc<3sig];final result]
%        cnt is the counts array
%            [[<1sig];[1sig<cnt<2sig];[2sig<cnt<3sig]]
%        x is the x from data
%            [x1, x2, ... xN]
%        y is the y from data
%            [y1, y2, ... yN]
%        t is the time series from data (do not pass the t=0)
%            [t1, t2, ... tN]
%        d is the displacement series array (do not pass the displ for t=0)
%            [pt1t1, pt2t1, ... ptNt1;
%            ...
%            pt1tM, pt2tM, ... ptNtM]
%        xac is the I x-axis sampling locations for the evaluation grid
%            [xac1, xac2, ... xacI]
%        yac is the J y-axis sampling locations for the evaluation grid
%            [yac1, yac2, ... yacJ]
%        sig is the K values of sigma to be iterated by the model
%            [sig1, sig2, ... sigK]
%        amp is the L values of amplitude to be iterated by the model (positive values)
%            [amp1, amp2, ... ampL]
%    Notes:
%    Particular care should be place in selecting the parameters so that the
%    units match. If the displacement series are in mm, and the time series is
%    in month, then the amp accumulator parameters should be in mm/month.
%    The units of x, y, xac, yac, and sigma should be identical.
*/

void mexFunction(int nlhs, mxArray *plhs[],		// number and pointer to output arguments
                 int nrhs, const mxArray *prhs[]){	// number and pointer to input arguments

    // SHOULD DO MORE CHECKS

    /* Check coordinates, time and displacement arrays for consistency */
    unsigned int xSize=(unsigned int)mxGetNumberOfElements(X_IN);
    unsigned int ySize=(unsigned int)mxGetNumberOfElements(Y_IN);
    if(xSize!=ySize){
        mexErrMsgTxt("X and Y must have the same size!");
    }
    unsigned int dSizeN=(unsigned int)mxGetN(D_IN);
    unsigned short dSizeM=(unsigned short)mxGetM(D_IN);
    if(dSizeN!=xSize){
        mexErrMsgTxt("The displacement series must have the same number of columns as elements in X and Y!");
    }
    unsigned short tSize=(unsigned short)mxGetNumberOfElements(T_IN);
    if(tSize!=dSizeM){
        mexErrMsgTxt("The time series must have the same number of elements as number of rows in the displacement series!");
    }

    /* Get pointers to input args */
    double *x = mxGetPr(X_IN);
    double *y = mxGetPr(Y_IN);
    double *t = mxGetPr(T_IN);
    float *d = (float *)mxGetPr(D_IN);
    double *ax = mxGetPr(AXV_IN);
    double *ay = mxGetPr(AYV_IN);
    double *as = mxGetPr(ASV_IN);
    double *aa = mxGetPr(AAV_IN);

    /* Evaluate dimensions of accumulator */
    /* Make sure the steps are integers */
    mwSize alim[4];
    unsigned short axSize=(unsigned short)mxGetNumberOfElements(AXV_IN); // Number of x-stp from call
    unsigned short aySize=(unsigned short)mxGetNumberOfElements(AYV_IN); // Number of y-stp from call
    unsigned short asSize=(unsigned short)mxGetNumberOfElements(ASV_IN); // Number of s-stp from call
    unsigned short aaSize=(unsigned short)mxGetNumberOfElements(AAV_IN); // Number of a-stp from call
    alim[0]=(mwSize)axSize;
    alim[1]=(mwSize)aySize;
    alim[2]=(mwSize)asSize;
    alim[3]=(mwSize)aaSize;

    if(VERBOSE){
        mexPrintf("Accumulator dimensions: [x:%d,y:%d,s:%d,a:%d,r:4]\n",
                  axSize,
                  aySize,
                  asSize,
                  aaSize);
    }

    /* Create the return variables: note the inversion of x and y */
    mwSize dimsAcc[]={alim[1],alim[0],alim[2],alim[3],4};
    A_OUT = mxCreateNumericArray(5,dimsAcc,mxSINGLE_CLASS,mxREAL);
    mwSize dimsCnt[]={alim[1],alim[0],alim[2],3};
    C_OUT = mxCreateNumericArray(4,dimsCnt,mxUINT16_CLASS,mxREAL);

    /* Get the actual pointer to the residual */
    float *a = (float *)mxGetPr(A_OUT);
    unsigned short *c = (unsigned short *)mxGetPr(C_OUT);

    /* Call function doing the work */
    evaluateResidual(a,c,x,y,xSize,t,tSize,d,ax,axSize,ay,aySize,as,asSize,aa,aaSize);

    return;
}




