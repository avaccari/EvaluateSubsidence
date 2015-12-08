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