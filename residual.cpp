/* The main entry is the gateway function "mexFunction". The actual
   algorithm implementation is in the "evaluateResidual" function. */

/* Includes */
#include <cmath>
#include <cstring>
//#include "omp.h"
#include "residual.h"

using namespace std;

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

    double xDat,yDat,sig,yAc,xAc,amp;
    double sigsq,sigsqinv,ex,dist,tim,dis,fit,dif,res;
    double tmpAcc;
    double tSizeInv=1.0/tSize;
    unsigned char rng;

//    double wtim=-omp_get_wtime();

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

//    wtim+=omp_get_wtime();

    return;
}
