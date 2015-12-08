/* The main entry is the gateway function "mexFunction". The actual
   algorithm implementation is in the "evaluateResidual" function. */

/* Includes */
#include <cmath>
#include <cstring>
#include "omp.h"
#include "mex.h"

using namespace std;

/* General */
#define     VERBOSE 1

/* Inputs */
#define		X_IN	prhs[0]		// x data
#define		Y_IN	prhs[1]		// y data
#define		T_IN	prhs[2]		// time data
#define		D_IN	prhs[3]		// displacement data
//#define		AL_IN	prhs[4]		// array with accumulator limits and steps
#define     AXV_IN  prhs[4]     // accumulator x values
#define     AYV_IN  prhs[5]     // accumulator y values
#define     ASV_IN  prhs[6]     // accumulator sigma values
#define     AAV_IN  prhs[7]     // accumulator amplitude values


/* Outputs */
#define		A_OUT	plhs[0]		// accumulators array
#define     C_OUT   plhs[1]     // counts array

/* MAX */
#define		MAX(a,b)	((a)>(b)?(a):(b))

/* MIN */
#define		MIN(a,b)	((a)<(b)?(a):(b))

/* Index into output accumulators array: note the inversion of x and y */
#define		IDXACC(x,y,s,a,r)	(yAcStp-1-y+x*yAcStp+s*yAcStp*xAcStp+a*yAcStp*xAcStp*sigStp+r*yAcStp*xAcStp*sigStp*ampStp)

/* Index into output counts array: note the inversion of x and y */
#define		IDXCNT(x,y,s,r)     (yAcStp-1-y+x*yAcStp+s*yAcStp*xAcStp+r*yAcStp*xAcStp*sigStp)

/* Indes into displacement series */
#define		IDXDIS(t,p)         (t+p*tSize)

/* Fit functions */
#define 	FIT(amp,sig,dist,t)	((-amp)*t*exp((-(dist))/(2*sig*sig)))

/* Evaluate the residual for the given parameters */
//void evaluateResidual(float a[], float c[], double x[], double y[], int xSize, double t[], int tSize, double d[], double al[]){
void evaluateResidual(float a[], 
                      unsigned short c[], 
                      double x[], 
                      double y[], 
                      unsigned int xSize, 
                      double t[], 
                      unsigned short tSize, 
                      float d[],
                      double ax[], 
                      unsigned short xAcStp, 
                      double ay[], 
                      unsigned short yAcStp, 
                      double as[], 
                      unsigned short sigStp, 
                      double aa[],
                      unsigned short ampStp){

	/* Initialize ranges and increments */
    if(VERBOSE){
        mexPrintf("xAcMin: %4.3f xAcMax: %4.3f xAcStp: %d\n",ax[0],ax[xAcStp-1],xAcStp);
        mexPrintf("yAcMin: %4.3f yAcMax: %4.3f yAcStp: %d\n",ay[0],ay[xAcStp-1],yAcStp);
        mexPrintf("sigMin: %4.3f sigMax: %4.3f sigStp: %d\n",as[0],as[sigStp-1],sigStp);
        mexPrintf("ampMin: %4.3f ampMax: %4.3f ampStp: %d\n",aa[0],aa[ampStp-1],ampStp);
        mexEvalString("drawnow");    
    }


    double xDat,yDat,sig,yAc,xAc,amp;
 	double sigsq,sigsqinv,ex,dist,tim,dis,fit,dif,res;
    double tmpAcc;
    double tSizeInv=1.0/tSize;
    unsigned char rng;

    double wtim=-omp_get_wtime();
    
	/* Build accumulator */
    for(unsigned short sigIdx=0;sigIdx<sigStp;sigIdx++){	// Step through accumulator sigma
        sig=as[sigIdx];
        sigsq=sig*sig; // Evaluate sig*sig
        sigsqinv=0.5/sigsq; // Evaluate 1/(2*sig*sig)

        for(unsigned short xAcIdx=0;xAcIdx<xAcStp;xAcIdx++){ // Step through accumulator x
            xAc=ax[xAcIdx];

            for(unsigned short yAcIdx=0;yAcIdx<yAcStp;yAcIdx++){ // Step through accumulator y
                yAc=ay[yAcIdx];

                for(unsigned int datIdx=0;datIdx<xSize;datIdx++){ // For each datapoint
                    xDat=x[datIdx],yDat=y[datIdx]; // Get datapoint coordinates
                    dist=(xDat-xAc)*(xDat-xAc)+(yDat-yAc)*(yDat-yAc); // Calculate distance squared between data and accumulator coordinates
                    
                    if(dist<=(9.0*sigsq)){ // If datapoint distance is less than 3 sigma
                        
                        ex=exp((-dist)*sigsqinv); // Evaluate part of the exponential
                        
                        if(dist<=(sigsq)){ // If within 1 sigma
                            rng=0;							
                        } else if(dist<=(4.0*sigsq)){ // If between 1 and 2 sigma
                            rng=1;
                        } else { // If between 2 and 3 sigma
                            rng=2;
                        }
                        
                        c[IDXCNT(xAcIdx,yAcIdx,sigIdx,rng)]++; // Increase count in appropriate range

                        for(unsigned short ampIdx=0;ampIdx<ampStp;ampIdx++){ // Step through accumulator amplitudes
                            amp=-aa[ampIdx];
                            tmpAcc=0.0; // Zero the temporal accumulator
                            
                            for(unsigned short timIdx=0;timIdx<tSize;timIdx++){ // Step through times
                                tim=t[timIdx]; // Extract time
                                fit=amp*tim*ex; // Evaluate model at datapoint
                                dis=d[IDXDIS(timIdx,datIdx)]; // Extract displacement for datapoint at this time
                                dif=abs(fit-dis); // Evaluate abs difference between fit and displacement
                                res=MIN(1.0,dif/MAX(abs(fit),abs(dis))); // Evaluate scaled residual

                                /* Update the temporal accumulator */
                                tmpAcc+=res;
                            }
                            /* Normalize by the time series size */
                            tmpAcc*=tSizeInv;
                            
                            a[IDXACC(xAcIdx,yAcIdx,sigIdx,ampIdx,rng)]+=(float)tmpAcc; // Add to accumulator
                        }
                    }
                }

				/* Calculate the final residual */
				for(unsigned short ampIdx=0;ampIdx<ampStp;ampIdx++){ // Step through accumulator amplitudes
				
					float nrmAcc[3];
				
					/* Set the residual to 1 for the 0 counts elements in the accumulator */
					for(rng=0;rng<3;rng++){
						if(c[IDXCNT(xAcIdx,yAcIdx,sigIdx,rng)]==0){
							nrmAcc[rng]=1.0;
						} else {
							nrmAcc[rng]=a[IDXACC(xAcIdx,yAcIdx,sigIdx,ampIdx,rng)]/c[IDXCNT(xAcIdx,yAcIdx,sigIdx,rng)];
						}
					}

                    /* Evaluate average residual */
					a[IDXACC(xAcIdx,yAcIdx,sigIdx,ampIdx,3)]=(nrmAcc[0]+nrmAcc[1]+nrmAcc[2])/(float)3.0;
															  
				}
            }
        }
    }
    
    wtim+=omp_get_wtime();

    if(VERBOSE){
        mexPrintf("Time taken: %4.3f sec\n",wtim);
    }
    
    return;
}






/*	Gateway function
 
	The function in MATLAB looks like:
		[acc,cnt]=residual(x,y,t,d,xac,yac,sig,amp)
	where
		acc is the accumulators array
            [[<1sig];[1sig<acc<2sig];[2sig<acc<3sig];final result]
        cnt is the counts array
            [[<1sig];[1sig<cnt<2sig];[2sig<cnt<3sig]]
		x is the x from data
			[x1, x2, ... xN]
		y is the y from data
			[y1, y2, ... yN]
		t is the time series from data (do not pass the t=0)
			[t1, t2, ... tN]
		d is the displacement series array (do not pass the displ for t=0)
			[pt1t1, pt2t1, ... ptNt1;
			 ...
			 pt1tM, pt2tM, ... ptNtM]
        xac is the I x-axis sampling locations for the evaluation grid
            [xac1, xac2, ... xacI]
        yac is the J y-axis sampling locations for the evaluation grid
            [yac1, yac2, ... yacJ]
        sig is the K values of sigma to be iterated by the model
            [sig1, sig2, ... sigK]
        sig is the L values of amplitude to be iterated by the model (positive values)
            [amp1, amp2, ... ampL]
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
    	mexPrintf("Accumulator dimensions: [x:%d,y:%d,s:%d,a:%d,r:4]\n",axSize,aySize,asSize,aaSize);
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




