mata
mata clear
mata set matastrict on
mata set mataoptimize on
mata set matalnum off

// Copyright David Roodman 2007-15. May be distributed free.
// Mata code for cmp 6.9.2 27 September 2015

struct smatrix {
	real matrix M
}

struct ssmatrix {
	struct smatrix colvector M
}

struct mprobit_group {
	real scalar d, out // dimension - 1; eq of chosen alternative
	real rowvector in, res // eqs of remaining alternatives; indices in ECens to hold relative differences
}

struct scores {
	real matrix ThetaScores, CutScores  // in nonhierarchical models, views onto dataset
	struct smatrix vector TScores, SigScores, GammaScores // SigScores only used at top level, for views onto data. In hierarchical models, TScores[L] holds base Sig scores
}

struct scorescol {
	struct scores colvector M
}

struct subview { // info associated with subsets of data defined by given combinations of indicator values
	real matrix ECens, EUncens, F, Et, Ft
	struct smatrix rowvector theta
	struct smatrix matrix dOmega_dGamma
	struct scorescol rowvector Scores // one col for each level, one col for each draw
	struct smatrix colvector tau // in hierarchical models, views onto REs->theta, XB without added random effects/coefficients
	real matrix Yi
	real colvector subsample, SubsampleInds, one2N
	real scalar GHKStart, GHKStartTrunc // starting indexes in ghk2() point structure
	real scalar d_uncens, d_cens, d2_cens, d_two_cens, d_oprobit, d_trunc, N
	real scalar NumCuts // number of cuts in ordered probit eqs relevant for *these* observations
	real rowvector vNumCuts // number of cuts per eq for the eq for *these* observations
	real matrix dSig_dLTSig // derivative of Sig w.r.t. its lower triangle
	real scalar bounded // d_oprobit? d_one_cens+1..d_cens:J(1,0,0)
	real scalar N_perm, NumRoprobitGroups, NumMprobitGroups
	real colvector CensLTInds // indexes of lower triangle of a vectorized square matrix of dimension d_cens
	real colvector lnL, WeightProduct
	real rowvector TheseInds // user-provided indicator values
	real rowvector uncens, two_cens, oprobit, cens, trunc, one2d_trunc
	real rowvector cens_uncens // one_cens, oprobit, uncens
	real rowvector SigIndsUncens // Indexes, within the vectorized upper triangle of Sig, entries for the eqs uncens at these obs
	real rowvector SigIndsTrunc // Ditto for trunc obs
	real rowvector SigIndsCensUncens // Permutes vectorized upper triangle of Sig to order corresponding to cens eqs first
	real rowvector CutInds // Indexes, within full list of oprobit cuts, of those relevant for the equations in these observations
	real matrix QSig   // correction factor for trial cov matrix reflecting scores of passed "error" (XB,-XB,Y-XB, or XB-Y) w.r.t XB, and relative differencing
	real matrix Sig     // Sig, reflecting that correction
	real matrix Omega   // invGamma * Sig * invGamma' in Gamma models. Slips into place of "Sig".
	real matrix QE     // correction factors for dlnL/dE
	real matrix QEinvGamma, invGammaQSigD
	real scalar dCensNonrobase
	real matrix J_d_uncens_d_cens_0, J_d_cens_d_0, J_d2_cens_d2_0, J_N_1_0
	// used in computations. Store here to avoid repeatedly destroying and reallocating with J():
	real matrix dphi_dE, dPhi_dE, dPhi_dF, dPhi_dpF, dPhi_dEt, dphi_dSig, dPhi_dSig, dPhi_dSigt, dPhi_dpE_dSig, _dPhi_dpE_dSig, _dPhi_dpF_dSig, dPhi_dpF_dSig, dPhi_dcuts, EDE
	struct ssmatrix colvector XU
	struct smatrix colvector id // for each level, colvector of observation indexes that explodes group-level data to obs-level data, within this view
	pointer (real rowvector) colvector roprobit_Q_E // for each roprobit permutation, matrix that effects roprobit differencing of ECens columns
	pointer (real rowvector) colvector roprobit_Q_Sig // ditto for vech() of Sigma of censored E columns
	struct mprobit_group colvector mprobit
	
	pointer (struct subview scalar) scalar next
}

struct RE { // info associated with given level of model. Top level also holds various globals as an alternative to storing them as separate externals, references to which are slow
	struct smatrix colvector y, theta, Lt, Ut, yL
	real scalar N // number of groups at this level
	real colvector one2N
	real rowvector one2d, one2R
	real scalar R // number of draws. (*REs)[l].R =(*REs)[l+1].NumREDraws
	real scalar d, d2 // number of RCs and REs, corresponding triangular number
	real scalar dCns // number of *indepedent* RCs and REs
	real scalar NEq // number of equations
	real rowvector NEff // number of effects/coefficients by equation, one entry for each eq that has any effects
	real scalar ThisDraw, NumREDraws, L
	real matrix Sig, T, Omega
	real matrix D // derivative of vech(Sig) w.r.t lnsigs and atanhrhos
	real matrix dSig_dT // derivative of vech(Sig) w.r.t vech(cholesky(Sig))
	struct smatrix rowvector U // draws/observation-vector of N_g x d sets of draws
	struct smatrix matrix XU // draws/observation x d matrix of matrices of X, U products; coefficients on these, elements of T, set contribution to simulated error 
	struct smatrix matrix TotalEffect // matrices of, for each draw set and equation, total simulated effects at this level: RE + RC*(RC vars)
	real matrix id // group id var
	real colvector IDRangesGroup // N x 1, max id for each group's subgroups in the next level down
	real matrix IDRanges // N x 1, id ranges for each group in data set, as returned by panelsetup()
	real matrix lnL, lnLByDraw // lnL holds latest likelihoods at this level; lnLByDraw acculumulates sums of them at next level up, by draw
	real colvector Weights // weights at this level, one obs per group, renormalized if pweights or aweights
	real colvector WeightProduct // obs-level product of weights at all levels, for weighting scores
	real colvector J_N_1_0
	real matrix J_N_NEq_0
	real rowvector Eqs // indexes of equations in this level--for upper levels, ones with REs or RCs
	real rowvector GammaEqs // indexes of equations in this level that have REs or RCs or depend on them indirectly through Gamma
	real rowvector REEqs // indexes of equations, within Eqs, with REs (as distinct from RCs)
	real rowvector REInds // indexes, within vector of effects, of random effects
	real scalar HasRC
	struct smatrix colvector RCInds // for each equation, indexes of equation's set of random-coefficient effects within vector of effects
	struct smatrix colvector X // NEq-vector of data matrices for variables with random coefficients
	real matrix dSigdParams // derivative of sig, vech(rho) vector w.r.t. vector of actual sig, rho parameters, reflecting "exchangeable" and "independent" options
	real scalar lnLlimits, lnNumREDraws
	// stash here to avoid slow references to externals
	transmorphic ghk2DrawSet
	real scalar mprobit_ind_base, roprobit_ind_base, ghkAnti, NumCuts, HasGamma, SigXform
	real colvector G // number of Gamma params in each eq
	pointer(real matrix) colvector GammaInds // d x 1 vector of pointers to rowvectors indicating which columns of Gamma, for a given row, are real model parameters
	real matrix dOmega_dSig, invGamma
	struct smatrix matrix dOmega_dGamma
	real rowvector trunceqs, intregeqs
	real matrix RC_T // transform simulated effects into full, constrained ones
	real scalar Quadrature, IntMethod, AdaptivePhaseThisEst, AdaptivePhaseThisIter, QuadTol, QuadIter
	real colvector ToAdapt // by group, state of adaptation attempt for this iteration. 2 = ordinary adaptation needed; 1 = adaptation needed having been reset because of divergence; 0 = converged
	real colvector QuadXinner2, QuadW, QuadX // quadrature weights
	struct smatrix rowvector QuadXAdapt // one set of adapted nodes per group
	struct smatrix colvector QuadMean, QuadSD // by group, estimated RE/RC mean and variance, for adaptive quadrature
	real matrix RichardZhangPX, RichardZhangPXX, AdaptiveShift
	real rowvector lnnormaldenQuadX
	real scalar LastlnLLastIter, LastlnLThisIter
	string scalar LastIter
	real scalar todo // whether this is an lf1 search, even if this particular iteration isn't
}
	
// substitute for built-in Stata command _ms_findomitted, since missing from Stata 11
void _ms_findomitted(string scalar bname, string scalar Vname) {
	string matrix stripe; string rowvector s; real scalar i, j
	stripe = st_matrixcolstripe(bname)
	for (i=rows(stripe); i; i--)
		if (!(st_matrix(bname)[i] & st_matrix(Vname)[i,i])) {
			s = tokens(stripe[i,2], "#")
			for (j=cols(s); j; j--)
				if (s[j]!="#" & !(strpos(s[j], "b.") | strpos(s[j],"o.")))
					s[j] = "o." + s[j]
			stripe[i,2] = invtokens(s, "")
		}
	st_matrixcolstripe(bname, stripe)
}

// bypass built-in Kmatrix() to be compatible with Stata 10, in which it was "kmatrix()"
real matrix _Kmatrix(real scalar d) 
	return (designmatrix(vec(rowshape(1::d*d,d))))

// prepare matrix to transform scores w.r.t. elements of Sigma to ones w.r.t. lnsig's and rho's
real matrix dSigdsigrhos(pointer (struct RE scalar) scalar REs, pointer (struct RE scalar) scalar RE, real rowvector sig, real matrix Sig, real rowvector rho, real matrix Rho) {
	real matrix D, t, t2; real scalar i, j, k, d, d2
	d = cols(sig); d2 = d + cols(rho)
	D = I(d2)
	for (k=1; k<=d; k++) {  // derivatives of Sigma w.r.t. lnsig's
		t2 = REs->SigXform? Sig[k,] : Rho[k,]:*sig
		(t = J(d,d,0))[k,] = t2
		t[,k] = t[,k] + t2'
		D[,k] = vech(t)
	}
	if (d > 1) {  // derivatives of Sigma w.r.t. rho's
		for (j=1; j<=d; j++)
			for (i=j+1; i<=d; i++) {
				(t = J(d,d,0))[i,j] = sig[i] * sig[j]
				D[,k++] = vech(t)
			}
		if (REs->SigXform) {
			t = cosh(rho)
			D[|.,d+1 \ .,.|] = D[|.,d+1 \ .,.|] :/ (t:*t)  //Datanh=cosh^2
		}
	}
	return(D)
}

// insert row vector into a matrix at specified row
real matrix insert(real matrix X, real scalar i, real rowvector newrow)
	return (i==1? newrow\X : (i==rows(X)+1? X\newrow : X[|.,.\i-1,.|] \ newrow \ X[|i,.\.,.|]))

// Given a col, apply forward Guassian elimination using first row that is non-zero in that col, then delete the row.
/* real matrix eliminate(real matrix X, real scalar c) {
	real matrix RetVal, r
	r = min(OneInds(X[,c]:!=0)')
	if (r < .) {
		RetVal = r>1? X[|.,.\r-1,.|] : J(0, cols(X), 0)
		return (r==rows(X) & r>0? RetVal : RetVal \ X[|r+1,.\.,.|] - (X[r,]/X[r,c] # J(rows(X)-r,1,1)) :* X[|r+1,c \ .,c|])
	}
	return (X)
}*/

// Check whether all entries in vector are prime
void CheckPrime(real vector v) {
	real scalar i, j
	for (i=length(v); i; i--)
		for (j=floor(sqrt(v[i])); j>1; j--)
			if (mod(v[i], j) == 0) {
				printf("Note: %f is not prime. Prime draw counts are more reliable.\n\n", v[i])
				return
			}
}

// paste columns B into matrix A at starting index i, then advance index
void PasteAndAdvance(real matrix A, real scalar i, real matrix B) {
	if (cols(B)) {
		real scalar t
		t = i + cols(B)
		A[|.,i \ .,t-1|] = B
		i = t
	}
}

// given a vector of 0's and 1's, return indices of the 1's, like selectindex() function added in Stata 13
// if v = 0 (so can't tell if row or col vector), returns rowvector J(1, 0, 0) 
real vector OneInds(real vector v) {
	real colvector i, t; real matrix w
	pragma unset i; pragma unset w
	maxindex((cols(v)==1? v \ 0 : v, 0), 1, i, w)
	t = rows(i)>length(v)? J(0, 1, 0) : i
	return (cols(v)==1 & rows(v)!=1? t : t')
}

// Given ranking potentially with ties, return matrix of all un-tied rankings consistent with it, one per row
real matrix PermuteTies(real vector v) {
	real colvector Indexes; real matrix  TiedRanges
	pragma unset   Indexes; pragma unset TiedRanges
	minindex(v, ., Indexes, TiedRanges)
	TiedRanges[,2] = rowsum(TiedRanges) :- 1
	return (_PermuteTies(Indexes, TiedRanges', rows(TiedRanges))')
}
real matrix _PermuteTies(real colvector Indexes, real matrix TiedRanges, real scalar ThisRank) {
	real colvector info, p, t; real matrix RetVal
	RetVal = J(rows(Indexes), 0, .)
	info = cvpermutesetup(Indexes[| p = TiedRanges[,ThisRank] |], 0)
	while (rows(t = cvpermute(info))) {
		Indexes[|p|] = t
		RetVal = RetVal, ( ThisRank==1? Indexes : _PermuteTies(Indexes, TiedRanges, ThisRank-1) )
	}
	return (RetVal)
}

// given indexes for variables, and dimension of variance matrix, return corresponding indexes in vectorized variance matrix
// e.g., (1,3) ->((1,1), (3,1), (3,3)) -> (1, 3, 6)
real rowvector vSigInds(real rowvector inds, real scalar d)
	return (vech(invvech(1::d*(d+1)*0.5)[inds,inds])')

// Given transformation matrix for errors, return transformation matrix for vech(covar)
real matrix QE2QSig(real matrix QE)
	return (Lmatrix(cols(QE))*(QE#QE)'Dmatrix(rows(QE)))

// compute normal(F) - normal(E) while maximizing precision
// In Mata, 1 - normal(10) should = normal(-10) but the former = 0 because normal(10) is close to 1
// Ergo the best way to compute the former is to do the latter
// F = . means +infinity. E = . means -infinity
real colvector normal2(real colvector E, real colvector F) {
	real colvector sign, _E, _F
	_E = editmissing(E, -maxdouble()); _F = editmissing(F, maxdouble())
	sign = _F+_E:<0
	sign = sign + sign :- 1
	return (abs(normal(sign:*_F) - normal(sign:*_E)))
}

// integral of bivariate normal from -infinity to E1, F2 to E2, done to maximize precision as in normal2()
real colvector binormal2(real colvector E1, real matrix E2, real matrix F2, real scalar rho) {
	real colvector sign, _E1, _E2, _F2
	_E1  = editmissing(E1 , -maxdouble()); _E2  = editmissing(E2 , -maxdouble())
	_F2 = editmissing(F2,  maxdouble())
	sign = _E2+_F2:<0
	sign = sign + sign :- 1
	return (abs(binormalGenz(_E1, sign:*_E2, rho, sign) - binormalGenz(_E1, sign:*_F2, rho, sign)))
}

// Based on Genz 2004 Fortran code, http://www.math.wsu.edu/faculty/genz/software/fort77/tvpack.f
// Alan Genz, "Numerical computation of rectangular bivariate and trivariate normal and t probabilities," Statistics and Computing, August 2004, Volume 14, Issue 3, pp 251-60.
//
//    A function for computing bivariate normal probabilities.
//    This function is based on the method described by 
//        Drezner, Z and G.O. Wesolowsky, (1989), On the computation of the bivariate normal integral, Journal of Statist. Comput. Simul. 35, pp. 101-107,
//    with major modifications for double precision, and for |r| close to 1.
//
// Calculates the probability that X < x1 and Y < x2.
//
// Parameters
//   x1  integration limit
//   x2  integration limit
//   r   correlation coefficient
//   m   optional column vector of +/-1 multipliers for r
real colvector binormalGenz(real colvector x1, real colvector x2, real scalar r, | real colvector m) {
	real scalar a, as, absr, asinr; real colvector X, W, B, C, D, retval, BS, HS, HK, negx2, normalx1, normalx2, normalnegx1, normalnegx2; real rowvector xs, rs, sn, sn2; pointer (real colvector) px2

	if (r>=.) return (J(rows(x1),1,.))
	if (!r  ) return (normal(x1):*normal(x2))
	
	if ((absr=abs(r)) < 0.925) {
		// Gauss Legendre Points and Weights
		if (absr < 0.3) {
			X = -0.9324695142031522D+00, -0.6612093864662647D+00, -0.2386191860831970D+00
			W =  0.1713244923791705D+00,  0.3607615730481384D+00,  0.4679139345726904D+00	
		} else if (absr < 0.75) {
			X = -0.9815606342467191D+00, -0.9041172563704750D+00, -0.7699026741943050D+00, -0.5873179542866171D+00, -0.3678314989981802D+00, -0.1252334085114692D+00	
			W =  0.4717533638651177D-01,  0.1069393259953183D+00,  0.1600783285433464D+00,  0.2031674267230659D+00,  0.2334925365383547D+00,  0.2491470458134029D+00	
		} else {
			X = -0.9931285991850949D+00, -0.9639719272779138D+00, -0.9122344282513259D+00, -0.8391169718222188D+00, -0.7463319064601508D+00,
				-0.6360536807265150D+00, -0.5108670019508271D+00, -0.3737060887154196D+00, -0.2277858511416451D+00, -0.7652652113349733D-01

			W =  0.1761400713915212D-01,  0.4060142980038694D-01,  0.6267204833410906D-01,  0.8327674157670475D-01,  0.1019301198172404D+00,
				 0.1181945319615184D+00,  0.1316886384491766D+00,  0.1420961093183821D+00,  0.1491729864726037D+00,  0.1527533871307259D+00
		}
		X = 1:-X, 1:+X
		W = W, W

		HK = x1:*x2; if (rows(m)) HK = m :* HK
		HS = x1:*x1 + x2:*x2
		asinr = asin(r) 
		sn = sin((asinr * 0.5) * X); sn2 = sn + sn
		asinr = asinr * 0.079577471545947673 // 1/(2 * tau)
		return ( normal(x1):*normal(x2) + quadrowsum(W:*exp((HK*sn2:-HS):/(2:-sn2:*sn))) :* (rows(m)?m*asinr:asinr) )
	}

	negx2 = -x2
	if (r<0) px2 = &x2
		else px2 = &negx2
	if (rows(m)) {
		px2 = &(m :* *px2)
		normalx1    = normal( x1)
		normalx2    = normal( x2)
		normalnegx1 = normal(-x1)
		normalnegx2 = normal(negx2)
	}
	HK = x1 :* *px2 * 0.5
	if (absr < 1) {
		X = -0.9931285991850949D+00, -0.9639719272779138D+00, -0.9122344282513259D+00, -0.8391169718222188D+00, -0.7463319064601508D+00,
			-0.6360536807265150D+00, -0.5108670019508271D+00, -0.3737060887154196D+00, -0.2277858511416451D+00, -0.7652652113349733D-01

		W =  0.1761400713915212D-01,  0.4060142980038694D-01,  0.6267204833410906D-01,  0.8327674157670475D-01,  0.1019301198172404D+00,
			 0.1181945319615184D+00,  0.1316886384491766D+00,  0.1420961093183821D+00,  0.1491729864726037D+00,  0.1527533871307259D+00
		X = 1:-X, 1:+X
		W = W, W

		a = sqrt(as = (1-r)*(1+r))
		B = abs(x1 + *px2); BS = B :* B
		C = 2 :+ HK
		D = 6 :+ HK
		asinr = HK - BS/(as+as)
		retval = a * exp(asinr) :* (1:-C:*(BS:-as):*(0.083333333333333333:-D:*BS*0.0020833333333333333) + C:*D:*(as*as*0.00625)) -
		              exp(HK) :* normal(B/-a) :* B :* (/*sqrt(tau)*/2.5066282746310002 :- C:*BS:*(/*sqrt(tau)/12*/0.20888568955258335:-D:*BS*/*sqrt(tau)/480*/0.0052221422388145835)) 

		a = a * 0.5
		xs = a*X; xs = xs :* xs
		rs = sqrt(1 :- xs)
		asinr = HK :- BS * 1:/(xs+xs)
		retval = (retval + quadrowsum((a*W) :* (exp(asinr) :* ( exp(HK*((1:-rs):/(1:+rs))):/rs - (1 :+ C*(xs*.25):*(1:+D*(xs*.125))) ))))/-6.2831853071795862
		if (rows(m)) {
			if (r<0)				
				return ((m:<0):*(retval + rowmin((normalx1,normalx2))) - (m:>0):*(retval + (x1:>=negx2):*((x1:>x2):*(normalnegx1-normalx2)+(x1:<=x2):*(normalnegx2-normalx1)))) // slow but max precision
			return     ((m:>0):*(retval + rowmin((normalx1,normalx2))) - (m:<0):*((x1:>=negx2):*(retval + (x1:>x2):*(normalnegx1-normalx2)+(x1:<=x2):*(normalnegx2-normalx1))))
		}
		if (r<0)
			return ((x1:>=negx2):*((x1:>x2):*(normal(x2)-normal(-x1))+(x1:<=x2):*(normal(x1)-normal(negx2))) - retval) // slow but max precision
		return (retval + normal(rowmin((x1,x2))))
	}
	if (rows(m)) {
		if (r<0)				
			return ((m:<0):*(rowmin((normalx1,normalx2))) - (m:>0):*((x1:>=negx2):*((x1:>x2):*(normalnegx1-normalx2)+(x1:<=x2):*(normalnegx2-normalx1)))) // slow but max precision
		return     ((m:>0):*(rowmin((normalx1,normalx2))) - (m:<0):*((x1:>=negx2):*((x1:>x2):*(normalnegx1-normalx2)+(x1:<=x2):*(normalnegx2-normalx1))))
	}
	if (r<0)
		return ((x1:>=negx2):*((x1:>x2):*(normal(x2)-normal(-x1))+(x1:<=x2):*(normal(x1)-normal(negx2)))) // slow but max precision
	return (normal(rowmin((x1,x2))))
}

/*SpGr(dim, k): function for generating nodes & weights for nested sparse grids intergration with Gaussian weights
dim  : dimension of the integration problem
k    : Accuracy level. The rule will be exact for polynomial up to total order 2k-1
Returns 1x2 vector of pointers to matrices: nodes and weights
correspond to Heiss and Winschel GQN & KPN types
Adapted with permission from Florian Heiss & Viktor Winschel, http://sparse-grids.de/stata/build_nwspgr.do.
Sources: Florian Heiss and Viktor Winschel, "Likelihood approximation by numerical integration on sparse grids", Journal of Econometrics 144(1): 62-80.
         A. Genz and B. D. Keister (1996): "Fully symmetric interpolatory rules for multiple integrals over infinite regions with Gaussian weight." Journal of Computational and Applied Mathematics 71, 299-309.*/
pointer (real matrix) rowvector SpGr(real scalar dim, real scalar k) {
	pointer colvector n1d, w1d
	real matrix nodes, is, t
	pointer (real matrix) rowvector newnw
	real colvector weights, sortvec, keep, R1d, Rq
	real rowvector midx
	real scalar q, bq, j, r

	if (dim <= 2) { // "sparse" grids only sparser for dim > 2
		nodes = *GQNn1d()[k]; weights = *GQNw1d()[k] // use non-nested nodes
		nodes = nodes \ -nodes[|1+mod(k,2)\.|]; weights = weights \ weights[|1+mod(k,2)\.|]
		return (dim==1? (&              nodes          , & weights         ) :
		                (&(J(k,1,nodes),nodes#J(k,1,1)), &(weights#weights))) // Kronecker square of non-nested nodes
	}
	
	w1d = KPNw1d(); n1d = KPNn1d()
	nodes = J(0, dim,.); weights = J(0,1,.); R1d = J(25, 1, 0)
	for (r=25; r; r--) R1d[r] = rows(*n1d[r])

	for(q=max((0,k-dim)); q<k; q++) {
		r = rows(weights)
		bq = (2*mod(k-q, 2)-1) * comb(dim-1,dim+q-k)
		is = SpGrGetSeq(dim, dim+q) // matrix of all rowvectors in N^D_{D+q}
		Rq = R1d[is[,1]]
		for(j=dim; j>1; j--)
			Rq = Rq :* R1d[is[,j]]
		nodes   = nodes   \ J(colsum(Rq), dim, .)
		weights = weights \ J(colsum(Rq), 1  , .)

		// inner loop collecting product rules
		for (j=1; j<=rows(is); j++) {
			midx = is[j,]
			newnw = SpGrKronProd(n1d[midx], w1d[midx])
			nodes  [|r+1,. \ r+Rq[j],.|] = *newnw[1]
			weights[|r+1   \ r+Rq[j]  |] = *newnw[2] :* bq 
			r = r + Rq[j]
		}
		
		// combine identical nodes, summing weights
		if (rows(nodes) > 1) {
			sortvec = order(nodes, 1..dim)
			_collate(nodes,   sortvec)
			_collate(weights, sortvec)
			keep = rowmax(nodes[|.,.\rows(nodes)-1,.|] :!= nodes[|2,.\.,.|]) \ 1
			weights = select(quadrunningsum(weights), keep)
			weights = weights - (0 \ weights[|.\rows(weights)-1|])
			nodes = select(nodes, keep)
		}
	}

	// 2. expand rules to other orthants
	for(j=dim; j; j--)
		if (any(keep = nodes[,j])) {
			t = select(nodes, keep)
			t[,j] = -t[,j]
			nodes   = nodes   \ t
			weights = weights \ select(weights, keep)
		}
		
	return(&nodes, &weights)
}

// SpGrGetSeq(): generate all d-length sequences of positive integers summing to norm
//     Output: one sequence per row
real matrix SpGrGetSeq(real scalar d, real scalar norm) {
	real scalar i; real matrix retval
	if (d==1) return (norm)
	retval = norm-d+1, J(1,d-1,1)
	for (i=norm-d; i; i--)
		retval = retval \ J(comb(norm-i-1,d-2), 1, i), SpGrGetSeq(d-1, norm-i)
	return (retval)
}

// SpGrKronProd(): generate tensor product quadrature rule 
// Input: 
//     n1d : vector of pointers to 1D nodes 
//     n1d : vector of pointers to 1D weights 
// Output:
//     out  = pair of pointers to nodes and weights
pointer (real matrix) rowvector SpGrKronProd(pointer colvector n1d, pointer colvector w1d){
  real matrix nodes; real colvector weights; real scalar j
  nodes = *n1d[1]; weights = *w1d[1]
  for(j=2; j<=rows(n1d); j++){  
    nodes = J(rows(*n1d[j]),1,nodes), *n1d[j]#J(rows(nodes),1,1)
    weights = *w1d[j] # weights
  }
  return(&nodes, &weights)
}

// build database of KPN nodes
pointer colvector KPNn1d() {
	pointer colvector n1d
	n1d = J(25, 1, NULL)
	n1d[1]=&0
	n1d[2]=
	n1d[3]=&(0 \ 1.bb67ae8584caaX+000)
	n1d[4]=&(0 \ 1.7b70d986e371bX-001 \ 1.bb67ae8584caaX+000 \ 1.0bd651c3c6940X+002)
	n1d[5]=
	n1d[6]=
	n1d[7]=
	n1d[8] =&(0 \ 1.7b70d986e371bX-001 \ 1.bb67ae8584caaX+000 \ 1.6e3e68bdf05c1X+001 \ 1.0bd651c3c6940X+002)
	n1d[9] =&(0 \ 1.7b70d986e371bX-001 \ 1.3afd0b145f6cbX+000 \ 1.bb67ae8584caaX+000 \ 1.4c4c73966ac4cX+001 \ 1.6e3e68bdf05c1X+001 \ 1.0bd651c3c6940X+002 \ 1.4bf8121fd06beX+002 \ 1.9741dafb2e279X+002)
	n1d[10]=
	n1d[11]=
	n1d[12]=
	n1d[13]=
	n1d[14]=
	n1d[15]=&(0 \ 1.7b70d986e371bX-001 \ 1.3afd0b145f6cbX+000 \ 1.bb67ae8584caaX+000 \ 1.4c4c73966ac4cX+001 \ 1.6e3e68bdf05c1X+001 \ 1.9a4860b6119dbX+001 \ 1.0bd651c3c6940X+002 \ 1.4bf8121fd06beX+002 \ 1.9741dafb2e279X+002)
	n1d[16]=&(0 \ 1.fdefac787ea12X-003 \ 1.7b70d986e371bX-001 \ 1.3afd0b145f6cbX+000 \ 1.bb67ae8584caaX+000 \ 1.1de7757332a7cX+001 \ 1.4c4c73966ac4cX+001 \ 1.6e3e68bdf05c1X+001 \ 1.9a4860b6119dbX+001 \ 1.d1521e02e7753X+001 \ 1.0bd651c3c6940X+002 \ 1.4bf8121fd06beX+002 \ 1.9741dafb2e279X+002 \ 1.c7d0989fa502aX+002 \ 1.fec4f713f2469X+002 \ 1.208ac550728f1X+003)
	n1d[17]=&(0 \ 1.fdefac787ea12X-003 \ 1.7b70d986e371bX-001 \ 1.3afd0b145f6cbX+000 \ 1.bb67ae8584caaX+000 \ 1.1de7757332a7cX+001 \ 1.4c4c73966ac4cX+001 \ 1.6e3e68bdf05c1X+001 \ 1.9a4860b6119dbX+001 \ 1.d1521e02e7753X+001 \ 1.0bd651c3c6940X+002 \ 1.4bf8121fd06beX+002 \ 1.6caef1ce9cd82X+002 \ 1.9741dafb2e279X+002 \ 1.c7d0989fa502aX+002 \ 1.fec4f713f2469X+002 \ 1.208ac550728f1X+003)
	n1d[18]=
	n1d[19]=
	n1d[20]=
	n1d[21]=
	n1d[22]=
	n1d[23]=
	n1d[24]=
	n1d[25]=&(0 \ 1.fdefac787ea12X-003 \ 1.7b70d986e371bX-001 \ 1.3afd0b145f6cbX+000 \ 1.bb67ae8584caaX+000 \ 1.1de7757332a7cX+001 \ 1.4c4c73966ac4cX+001 \ 1.6e3e68bdf05c1X+001 \ 1.9a4860b6119dbX+001 \ 1.d1521e02e7753X+001 \ 1.0bd651c3c6940X+002 \ 1.2f21b83cf6e0dX+002 \ 1.4bf8121fd06beX+002 \ 1.6caef1ce9cd82X+002 \ 1.9741dafb2e279X+002 \ 1.c7d0989fa502aX+002 \ 1.fec4f713f2469X+002 \ 1.208ac550728f1X+003)
	return (n1d)
}
// build database of KPN weights
pointer colvector KPNw1d() {
	pointer colvector w1d
	w1d = J(25, 1, NULL)
	w1d[1]=&1
	w1d[2]=
	w1d[3]=&(1.5555555555556X-001 \ 1.5555555555555X-003)
	w1d[4]=&(1.d5c136f97eb9fX-002 \ 1.0d103a2317c43X-003 \ 1.1bc1d1bdbe6a5X-003 \ 1.6cbd25ab17686X-00b)
	w1d[5]=
	w1d[6]=
	w1d[7]=
	w1d[8]=&(1.0410410410414X-002 \ 1.148e5d741b005X-002 \ 1.84826d9d7c2efX-004 \ 1.06060a315d4a6X-007 \ 1.8b650f2e8fcd4X-00e)
	w1d[9]=&(1.11540fa7752daX-002 \ 1.04abb319cb636X-002 \ 1.d1109e29589b7X-007 \ 1.6b3cc5404fbb8X-004 \ 1.01a52daa57d1aX-009 \ 1.ccf2379939783X-008 \ 1.bb13c34bd0925X-00e \ -1.b87f927a33201X-015 \ 1.6b1f4ed2fa996X-01a)
	w1d[10]=
	w1d[11]=
	w1d[12]=
	w1d[13]=
	w1d[14]=
	w1d[15]=&(1.36c01b0b214aaX-002 \ 1.aaa64b1098a9dX-003 \ 1.f4f4791f6a8d9X-005 \ 1.068995aaeb61eX-004 \ 1.284ef86a8d09eX-006 \ -1.9f50fd3c25122X-008 \ 1.7a2086415d886X-009 \ 1.f859f3e93d0b5X-00f \ 1.473669d2633bfX-015 \ 1.da6c037cb5564X-01f)
	w1d[16]=&(1.091d18766b7ceX-002 \ 1.ccd9cf0da1f36X-006 \ 1.98f65ae9b1ec1X-003 \ 1.0bf31bad212fdX-004 \ 1.f99924ddae2a8X-005 \ 1.cd987ab3a0a7eX-00a \ 1.0fd9f560112f9X-006 \ -1.6c723438806c2X-008 \ 1.65ce5537c60f6X-009 \ 1.f8ccbd8413685X-011 \ 1.f2e981ae3e0ebX-00f \ 1.49d4c7adcacdfX-015 \ 1.b3f263f7f563eX-01f \ 1.67fe27d2db829X-026 \ -1.4e2f97e6388d2X-02b \ 1.6bb3d51d2f57fX-032)
	w1d[17]=&(1.1ce5d1fcb8556X-003 \ 1.a97acb4daae07X-004 \ 1.689a86fc7dc03X-003 \ 1.3d3580d146bf1X-004 \ 1.bfeb256ec39b1X-005 \ 1.e1e30ddc332b8X-008 \ 1.79ca558bf4430X-007 \ -1.6b3aad1909c14X-009 \ 1.15e6fa482e21cX-009 \ 1.5d1e05e9c73c4X-00e \ 1.d32bda6e983caX-00f \ 1.72e76f320db55X-015 \ -1.cf60435a516d9X-01b \ 1.ab387b3b8eb18X-01e \ -1.54417e7671e89X-024 \ 1.2bf25fc6b54f0X-02a \ -1.1e40bbd0c6bd1X-032)
	w1d[18]=
	w1d[19]=
	w1d[20]=
	w1d[21]=
	w1d[22]=
	w1d[23]=
	w1d[24]=
	w1d[25]= KPNw1d25()
	return (w1d)
}
pointer(real colvector) scalar KPNw1d25() // hack to get around Mata "no room to add more double literals" compiler error
	return(&(1.0df3f89599c82X-00b \ 1.88b98713549feX-003 \ 1.2f3fc28a6ceecX-003 \ 1.7a536f88daddaX-004 \ 1.72e1ccce26990X-005 \ 1.00cb504b73588X-006 \ 1.9d97350f96961X-009 \ 1.2ef3e06f24d86X-009 \ 1.ad5e22af36681X-00b \ 1.209cbfeab0317X-00c \ 1.2bb830e618c44X-00f \ 1.6efb1b7210daeX-013 \ 1.08f607cf1c672X-016 \ 1.6f8ca9924e87bX-01a \ 1.f9e7977b533b5X-020 \ 1.b3e53215c6f94X-027 \ 1.88b784334d04dX-030 \ 1.3720030162321X-03c))

// build database of classic Gaussian quadrature node points, which are optimal (fewer) in 1- and 2-dimensional case
pointer colvector GQNw1d() {
	pointer colvector w1d
	w1d = J(17, 1, NULL)
	w1d[1]=&1
	w1d[2]=&0.5
	w1d[3]=&(1.5555555555555X-001 \ 1.5555555555558X-003)
	w1d[4]=&(1.d105eb806161eX-002 \ 1.77d0a3fcf4f09X-005)
	w1d[5]=&(1.1111111111112X-001 \ 1.c6cfbdb1f1fa3X-003 \ 1.70e202bebe3a7X-007)
	w1d[6]=&(1.a2a3ee29aae1dX-002 \ 1.6af858329214cX-004 \ 1.4efde4d84c7a5X-009)
	w1d[7]=&(1.d41d41d41d425X-002 \ 1.ebc5b378f5f4bX-003 \ 1.f7ecba63d3cabX-006 \ 1.1f7366724faa9X-00b)
	w1d[8]=&(1.7df6ecdef47e1X-002 \ 1.e036f41317d11X-004 \ 1.3bba15a77e75dX-007 \ 1.d856f0999f3a6X-00e)
	w1d[9]=&(1.a01a01a01a023X-002 \ 1.f3e9643fc0922X-003 \ 1.98ea4ad2e4eb8X-005 \ 1.6d940d8468e15X-009 \ 1.76e6ab51a9110X-010)
	w1d[10]=&(1.60e9eb9566811X-002 \ 1.15787acb87a16X-003 \ 1.391fc74e7189cX-006 \ 1.8d728ef7a4755X-00b \ 1.214872c35b4dfX-012)
	w1d[11]=&(1.7a463005e918fX-002 \ 1.f01baeaddb005X-003 \ 1.0ee78075fa6f1X-004 \ 1.b86bad4e71d18X-008 \ 1.9a5a915200b18X-00d \ 1.b409da81c1130X-015)
	w1d[12]=&(1.496261e3f1ff8X-002 \ 1.2cfd0f478e08eX-003 \ 1.dd0c3d967e08aX-006 \ 1.20cd2ffcb8399X-009 \ 1.95c5c15728197X-00f \ 1.421b5e3a9a562X-017)
	w1d[13]=&(1.5d2d18a2fe8d9X-002 \ 1.e7292f5e3ed36X-003 \ 1.4446aac477328X-004 \ 1.81b29e36e45f4X-007 \ 1.6529fec49affeX-00b \ 1.82c4b5d22b3aeX-011 \ 1.d3be6e1811e79X-01a)
	w1d[14]=&(1.35e5da033242eX-002 \ 1.3b900bcbdb3d0X-003 \ 1.3c9f272c6261cX-005 \ 1.2240eeb891669X-008 \ 1.a4247a9ba0ea2X-00d \ 1.6526f764ca204X-013 \ 1.4e899939f3b85X-01c)
	w1d[15]=&(1.45e5d2ba42e9fX-002 \ 1.dc1530e4db087X-003 \ 1.6e415aaec396bX-004 \ 1.1c855660dc3c2X-006 \ 1.9adf94e023fc0X-00a \ 1.d94c2be3fe52aX-00f \ 1.40cd8aa6ea5efX-015 \ 1.d8389345109e0X-01f)
	w1d[16]=&(1.257237eb1f12bX-002 \ 1.4446e8a55664eX-003 \ 1.835b501eb7e7eX-005 \ 1.dc3efb56d343fX-008 \ 1.13c480766c610X-00b \ 1.00b123449bbfeX-010 \ 1.19350d272303bX-017 \ 1.495f790d999f3X-021)
	w1d[17]=&(1.32ba2fbe5d1aeX-002 \ 1.d04b65a55e84cX-003 \ 1.8ef9fba90df96X-004 \ 1.7a4075398fbccX-006 \ 1.76ba4fad552feX-009 \ 1.615a26057b77bX-00d \ 1.0d494ed8ab7b5X-012 \ 1.e269dadb1cac0X-01a \ 1.c6a33273c5c56X-024)
	return (w1d \ GQNw1d18())
}
pointer colvector GQNw1d18() {
	pointer colvector w1d
	w1d = J(8, 1, NULL)
	w1d[1]=&(1.17547cfef2f46X-002 \ 1.491560695d193X-003 \ 1.c1b695253803aX-005 \ 1.589af1e7fc724X-007 \ 1.174f796af7002X-00a \ 1.b2856c34a4c40X-00f \ 1.12388bd5565c6X-014 \ 1.95d273b675690X-01c \ 1.36ca30ad426f8X-026)
	w1d[2]=&(1.2295709965ab9X-002 \ 1.c47d16a1bd936X-003 \ 1.a85c4efbf3d6bX-004 \ 1.d5acd11d5e8b3X-006 \ 1.2762dcb9ca37eX-008 \ 1.8ce362e7050adX-00c \ 1.018cab7a125b2X-010 \ 1.0fe5225d2e717X-016 \ 1.4f73f6cb14e42X-01e \ 1.a53ef230db9faX-029)
	w1d[3]=&(1.0b0d563a28710X-002 \ 1.4b3dfdef813beX-003 \ 1.f7dc361055131X-005 \ 1.caae5f0667284X-007 \ 1.dfc024629beb9X-00a \ 1.0e2b151900242X-00d \ 1.276bdd4d66a02X-012 \ 1.072c77c840896X-018 \ 1.10e7d83542f2aX-020 \ 1.1b3b45ae1f15eX-02b)
	w1d[4]=&(1.14bf15e76d04cX-002 \ 1.b900e215176feX-003 \ 1.bbf98c9e7772bX-004 \ 1.16240901614afX-005 \ 1.a608303b60f73X-008 \ 1.7338910139939X-00b \ 1.61ef604c7b84aX-00f \ 1.48edbe3f7951cX-014 \ 1.f2718419f6999X-01b \ 1.b5a35749021e1X-023 \ 1.7a1ee275317e1X-02e)
	w1d[5]=&(1.003fdb7d7f495X-002 \ 1.4b9586d9d3975X-003 \ 1.133c707ffb8c5X-004 \ 1.1fda085c6c27eX-006 \ 1.702661aee92fbX-009 \ 1.1306235b39102X-00c \ 1.bfd11211e61bbX-011 \ 1.647771ec3c191X-016 \ 1.ceb0afd401710X-01d \ 1.5a4342ed6e5acX-025 \ 1.f57170af1a7b8X-031)
	w1d[6]=&(1.08b6c709e2b6cX-002 \ 1.adff55d2841ebX-003 \ 1.cb0d75907c529X-004 \ 1.3e66645c9c42dX-005 \ 1.19238f0cff5bbX-007 \ 1.32163b3f699f4X-00a \ 1.87c846af16c00X-00e \ 1.127946272007dX-012 \ 1.78e2d51532124X-018 \ 1.a5b629c720c4fX-01f \ 1.0ea10bc809809X-027 \ 1.4a730b4f958dcX-033)
	w1d[7]=&(1.ed4d4fa6da3d6X-003 \ 1.4aab48fb22861X-003 \ 1.27323497f4f17X-004 \ 1.5a224f9483d2bX-006 \ 1.049c6d4cc0b24X-008 \ 1.e74afb2f16fd5X-00c \ 1.0d3b7ff451495X-00f \ 1.46dcf0c7d6da6X-014 \ 1.858c04de91929X-01a \ 1.79f03beeecf96X-021 \ 1.a244d6f97e2fcX-02a \ 1.b10bd7013194eX-036)
	w1d[8]=&(1.fc403679615eeX-003 \ 1.a388ef3dc31c8X-003 \ 1.d68d614d1d96cX-004 \ 1.635e64257cda4X-005 \ 1.63c111f64510bX-007 \ 1.cccf5801e9c6eX-00a \ 1.74cde1a66238cX-00d \ 1.661974c8c9745X-011 \ 1.7b0c183df3fb2X-016 \ 1.8a50622866c6cX-01c \ 1.4d791bd04ec6dX-023 \ 1.3fd9ac565f9a5X-02c \ 1.1a3e0c7f3a049X-038)
	return (w1d)
}
pointer colvector GQNn1d() {
	pointer colvector n1d
	n1d = J(17, 1, NULL)
	n1d[1]=&(0.0000000000000X-3ff)
	n1d[2]=&(1.0000000000001X+000)
	n1d[3]=&(0.0000000000000X-3ff \ 1.bb67ae8584caaX+000)
	n1d[4]=&(1.7be2ad58cb0ffX-001 \ 1.2ace15c98aa9fX+001)
	n1d[5]=&(0.0000000000000X-3ff \ 1.5b0a513c97441X+000 \ 1.6db131839e414X+001)
	n1d[6]=&(1.3bc0f75835b11X-001 \ 1.e3a107c35822eX+000 \ 1.a98144804badfX+001)
	n1d[7]=&(0.0000000000000X-3ff \ 1.27871ca8bbf03X+000 \ 1.2ef1f8ed4d738X+001 \ 1.e00e689ea0325X+001)
	n1d[8]=&(1.140244df60425X-001 \ 1.a2f2e9768a3f2X+000 \ 1.66b7db50ddbecX+001 \ 1.094042d748ee4X+002)
	n1d[9]=&(0.0000000000000X-3ff \ 1.05f4154b6bccfX+000 \ 1.09d6279197adaX+001 \ 1.9a4b7f60758f2X+001 \ 1.20d0d4069d86cX+002)
	n1d[10]=&(1.f092fc71c448cX-002 \ 1.774b0fb0b3e2fX+000 \ 1.3dfe63a13936dX+001 \ 1.ca793120f33dbX+001 \ 1.37017060f4281X+002)
	n1d[11]=&(0.0000000000000X-3ff \ 1.db94b79c0a3abX-001 \ 1.e043d4c1b73c5X+000 \ 1.6ebc5b10fd018X+001 \ 1.f7d44eb09d822X+001 \ 1.4c0836499312fX+002)
	n1d[12]=&(1.c711949e60909X-002 \ 1.5722d43422c04X+000 \ 1.21362191c2f29X+001 \ 1.9ca2860f2e400X+001 \ 1.1165983dc4e75X+002 \ 1.600ec605ccc6dX+002)
	n1d[13]=&(0.0000000000000X-3ff \ 1.b69eb1cfa3c79X-001 \ 1.b9b504d83fb18X+000 \ 1.4f72c4e06c593X+001 \ 1.c81ef20936599X+001 \ 1.25d978e145995X+002 \ 1.7335f0b515220X+002)
	n1d[14]=&(1.a67e1cee3a09cX-002 \ 1.3e20dd06e9148X+000 \ 1.0b4ee170c819dX+001 \ 1.7b44c85ba11f6X+001 \ 1.f186be95f3409X+001 \ 1.396767eb4c3daX+002 \ 1.85981e3653268X+002)
	n1d[15]=&(0.0000000000000X-3ff \ 1.992771fb7948dX-001 \ 1.9b5159e0a1de5X+000 \ 1.375a1706cbe4dX+001 \ 1.a500a723520f6X+001 \ 1.0c8eaac9c7e65X+002 \ 1.4c2a7e4f7553aX+002 \ 1.974aec15fe3bcX+002)
	n1d[16]=&(1.8c0af8ced8268X-002 \ 1.29f0b43504447X+000 \ 1.f3b4fbe349534X+000 \ 1.614fb5b04289bX+001 \ 1.cce96d4a6c431X+001 \ 1.1f8c9465ada5bX+002 \ 1.5e38f22ad8822X+002 \ 1.a8604ef376e7bX+002)
	n1d[17]=&(0.0000000000000X-3ff \ 1.80f1836b86908X-001 \ 1.8287b663c367eX+000 \ 1.23f871ecb6a1dX+001 \ 1.89722f93492fdX+001 \ 1.f3355a79cee0fX+001 \ 1.31d3762917467X+002 \ 1.6fa53be2c1437X+002 \ 1.b8e761ce5f5f2X+002)
	return (n1d \ GQNn1d18())
}
pointer colvector GQNn1d18() {
	pointer colvector n1d
	n1d = J(8, 1, NULL)
	n1d[1]=&(1.7602fbbba22caX-002 \ 1.193072dc46a64X+000 \ 1.d6fbd122b7929X+000 \ 1.4c44473fdd49dX+001 \ 1.aff75de6e4410X+001 \ 1.0c088602756abX+002 \ 1.4375ed47e5578X+002 \ 1.807ee8b4fde66X+002 \ 1.c8ecfdf981a52X+002)
	n1d[2]=&(0.0000000000000X-3ff \ 1.6c96693043f6bX-001 \ 1.6dcadca1c617aX+000 \ 1.13e783b5259f8X+001 \ 1.72f3581f62135X+001 \ 1.d50b99f71c617X+001 \ 1.1dd0db6c15d13X+002 \ 1.5483ab02758aeX+002 \ 1.90d3356de8734X+002 \ 1.d87c2cbb1629dX+002)
	n1d[3]=&(1.634a926e31cc3X-002 \ 1.0afe77649f855X+000 \ 1.bec88746540b3X+000 \ 1.3ab57d3cecdfdX+001 \ 1.9831a333c7333X+001 \ 1.f8d3ec11c84feX+001 \ 1.2f03616d7eb60X+002 \ 1.650a0e7d0f317X+002 \ 1.a0ad8256821f3X+002 \ 1.e79e7dc649aafX+002)
	n1d[4]=&(0.0000000000000X-3ff \ 1.5b28ce1473d5dX-001 \ 1.5c199cece9271X+000 \ 1.0648fd5ba8a05X+001 \ 1.60136e491d115X+001 \ 1.bc23efb4dcdfbX+001 \ 1.0db7cfd1dc8e7X+002 \ 1.3fad7d40e26dcX+002 \ 1.7514984550ddcX+002 \ 1.b017ab96e92dbX+002 \ 1.f65c4a1312ec3X+002)
	n1d[5]=&(1.5320aba86f5ecX-002 \ 1.fd85edd3b9dcdX-001 \ 1.aa0415e079011X+000 \ 1.2bbecaa391824X+001 \ 1.8425d25d6503fX+001 \ 1.dee95a373fc04X+001 \ 1.1e7cb6f266eabX+002 \ 1.4fdab7954e4f1X+002 \ 1.84ad428f4eb28X+002 \ 1.bf1a4da2ea0cbX+002 \ 1.025e7421097e3X+003)
	n1d[6]=&(0.0000000000000X-3ff \ 1.4c046939a8fceX-001 \ 1.4cc4b44834a04X+000 \ 1.f5136b2368a4eX+000 \ 1.4fe9d63b33b83X+001 \ 1.a70b8d2ab336fX+001 \ 1.004e3d26ab08fX+002 \ 1.2ec42f6c9ccb9X+002 \ 1.5f9513ea54adcX+002 \ 1.93dcc5a2cb26bX+002 \ 1.cdbcfaed54d66X+002 \ 1.09636b181b8c7X+003)
	n1d[7]=&(1.44fcaaa701e6fX-002 \ 1.e826eb1490d0aX-001 \ 1.97ee555ce0a70X+000 \ 1.1ec7a68b60b2cX+001 \ 1.72e8c5ada9cd9X+001 \ 1.c8df0b468b344X+001 \ 1.10aa1ffefe67aX+002 \ 1.3e983ad98d6f2X+002 \ 1.6ee554687c2dbX+002 \ 1.a2aacda3fd64aX+002 \ 1.dc06669272595X+002 \ 1.103fed2a77985X+003)
	n1d[8]=&(0.0000000000000X-3ff \ 1.3eb3603832154X-001 \ 1.3f4fd66f2eea1X+000 \ 1.e086e5b79be9dX+000 \ 1.41da42df91e4bX+001 \ 1.94d5d55dc73a6X+001 \ 1.e9b71c20e3ca5X+001 \ 1.20924ecfc66b2X+002 \ 1.4e019b6f3f9fcX+002 \ 1.7dd32f47e7204X+002 \ 1.b11e255e18de2X+002 \ 1.e9fc869ed6452X+002 \ 1.16f68f680d2d2X+003)
	return (n1d)
}

// apply a binormal function to columns of values. Accepts general covariance matrix, not just rho parameter
// optionally computes scores
real colvector vecbinormal(real matrix X, real matrix Sig, real colvector one2N, real scalar todo, real matrix dPhi_dX, real matrix dPhi_dSig) {
	real colvector Phi, Xhat, X_2
	real matrix dPhi_dSigDiag, phi, X_
	real scalar rho
	real rowvector SigDiag, sqrtSigDiag

	Xhat = X :/ (sqrtSigDiag = sqrt(SigDiag = diagonal(Sig)'))
	rho = Sig[1,2]/(sqrtSigDiag[1]*sqrtSigDiag[2])
	Phi = binormalGenz(editmissing(Xhat[one2N,1], 1e6), editmissing(Xhat[one2N,2], 1e6), rho)

	if (todo) {
		phi = editmissing(normalden(Xhat), 0)
		X_ = Xhat * ((1,-rho \ -rho,1) / sqrt(1-rho*rho)) // each X_ with the other partialled out, then renormalized to s.d. 1
		dPhi_dSig = phi[one2N,1] :* editmissing(normalden(X_2=X_[one2N,2]),0) / sqrt(det(Sig))
		dPhi_dX = phi :* (editmissing(normal(X_2), 1), editmissing(normal(X_[one2N,1]), 1)) :/ sqrtSigDiag
		dPhi_dSigDiag = (editmissing(X, 0):*dPhi_dX :+ (Sig[1,2]*dPhi_dSig)) :/ (-2 * SigDiag) 
		dPhi_dSig = dPhi_dSigDiag[one2N,1], dPhi_dSig, dPhi_dSigDiag[one2N,2]
	}
	return (Phi)
}

// compute binormal(E1,E2,rho)-binormal(E1,F2,rho) so as to maximize precision. If midpoint between E2, F2 is >0, negate E2, F2, rho in order to take difference of smaller numbers
// infsign flag indicate whether to interpret . in E1 as + or - infinity. 1=+, 0=-
real colvector vecbinormal2(real colvector E1, real colvector E2, real colvector F2, real matrix Sig, real scalar infsign, real scalar flip, real colvector one2N,
							real scalar todo, real matrix dPhi_dE1, real matrix dPhi_dE2, real matrix dPhi_dF2, real matrix dPhi_dSig) {
	real colvector Phi, E1hat, E2hat, F2hat, phiE1, phiE2, phiF2
	real matrix dPhi_dSigDiagE, dPhi_dSigDiagF, dPhi_dXE, dPhi_dXF, dPhi_dSigE, dPhi_dSigF, E1E2hat, E1F2hat, t
	real scalar rho, i1, i2
	real rowvector SigDiag, sqrtSigDiag

	if (flip) {
		i1 = 2; i2 = 1
	} else {
		i1 = 1; i2 = 2
	}
	sqrtSigDiag = sqrt(SigDiag = diagonal(Sig)'[(i1,i2)])
	E1hat = E1 / sqrtSigDiag[1]
	E2hat = E2 / sqrtSigDiag[2]
	F2hat = F2 / sqrtSigDiag[2]
	rho = Sig[1,2]/(sqrtSigDiag[1]*sqrtSigDiag[2])

	if (infsign)
		Phi = binormal2(editmissing(E1hat, 1e6), 
						editmissing(E2hat, 1e6), editmissing(F2hat, -1e6), rho)
	else
		Phi = binormal2(editmissing(E1hat,-1e6), 
						editmissing(E2hat, 1e6), editmissing(F2hat, -1e6), rho)

	if (todo) {
		phiE1 = editmissing(normalden(E1hat), 0)
		phiE2 = editmissing(normalden(E2hat), 0)
		phiF2 = editmissing(normalden(F2hat), 0)
		E1E2hat = (E1hat,E2hat) * (t = (1,-rho \ -rho,1) / sqrt(1-rho*rho)) // each with the other partialled out, then renormalized to s.d. 1
		E1F2hat = (E1hat,F2hat) *  t
		dPhi_dSigE = phiE1 :* editmissing(normalden(E2hat=E1E2hat[one2N,2]),0) / (t=sqrt(det(Sig)))
		dPhi_dSigF = phiE1 :* editmissing(normalden(F2hat=E1F2hat[one2N,2]),0) /  t
		dPhi_dXE = (phiE1,phiE2) :* (editmissing(normal(E2hat), 1), editmissing(normal(E1E2hat[one2N,1]), infsign)) :/ sqrtSigDiag
		dPhi_dXF = (phiE1,phiF2) :* (editmissing(normal(F2hat), 0), editmissing(normal(E1F2hat[one2N,1]), infsign)) :/ sqrtSigDiag
		dPhi_dSigDiagE = (editmissing((E1,E2), 0):*dPhi_dXE :+ (Sig[1,2]*dPhi_dSigE)) :/ (t=-SigDiag-SigDiag) 
		dPhi_dSigDiagF = (editmissing((E1,F2), 0):*dPhi_dXF :+ (Sig[1,2]*dPhi_dSigF)) :/  t 
		dPhi_dSigE = dPhi_dSigDiagE[one2N,i1], dPhi_dSigE, dPhi_dSigDiagE[one2N,i2]
		dPhi_dSigF = dPhi_dSigDiagF[one2N,i1], dPhi_dSigF, dPhi_dSigDiagF[one2N,i2]
		dPhi_dSig = dPhi_dSigE - dPhi_dSigF
		dPhi_dE1 = dPhi_dXE[one2N,1] - dPhi_dXF[one2N,1]
		dPhi_dE2 = dPhi_dXE[one2N,2]
		dPhi_dF2 =                   - dPhi_dXF[one2N,2]
	}
	return (Phi)
}

// neg_half_E_Dinvsym_E() -- compute -0.5 * inner product of given errors weighting by derivative of inverse of a symmetric matrix 
// Passed +/- E times the inverse of X. Returns a matrix with one column for each of the N(N+1)/2 independent entries in X.
real matrix neg_half_E_Dinvsym_E(real matrix E_invX, real colvector one2N, real matrix EDE) {
	real colvector E_invX_j; real scalar N, j, l
	if (N = cols(E_invX)) {
		l = cols(EDE)
		E_invX_j = E_invX[one2N,N]
		EDE[,l--] = E_invX_j :* E_invX_j * .5
		for (j=N-1; j; j--) {
			E_invX_j = E_invX[one2N,j]	
			EDE[|.,l-N+j+1 \ .,l|] = E_invX[|.,j+1 \ .,N|] :* E_invX_j // effectively double off-diagonal entries since symmetric
			l = l - N + j
			EDE[one2N,l--] = E_invX_j:*E_invX_j * .5
		}
	}
	return (EDE)
}

// Compute product of derivative of Phi w.r.t. partialled-out errors (provided) and derivative of partialled-out errors w.r.t. 
// original covariance matrix. Used as part of an application of the chain rule to transform the initial scores for Phi
// w.r.t. the partialled-out errors and covariance matrix into scores w.r.t. the un-partialled ones.
// Returns a score matrix with one row for each observation and one column for each element of the lower triangle of
// Var[in | out], ordered by the lists in parameters "in" and "out". E.g. if in=(1,3) and out=(2), then the column 
// order corresponds to (1,1),(1,3),(1,2),(3,3),(3,2),(2,2)
real matrix dPhi_dpE_dSig(real matrix E_out, real colvector one2N, real matrix beta, real matrix invSig_out, real matrix Sig_out_in, 
					real matrix dPhi_dpE, real scalar lin, real scalar lout, real matrix scores, real matrix J_d_uncens_d_cens_0) {
	real matrix neg_dbeta_dSig; real rowvector beta_j; real colvector invSig_out_j; real scalar i, j, l

	l = lin + lout
	for(l=j=1; j<=lin; j++) {
		// scores w.r.t. sig_ij where both i,j are in are 0, so skip those columns in score matrix
		l = l + lin - j + 1
		// scores w.r.t. sig_ij where i out and j in 
		for(i=1; i<=lout; i++) {
			(neg_dbeta_dSig = J_d_uncens_d_cens_0)[,j] = -invSig_out[,i]
			scores[one2N,l++] = quadrowsum(dPhi_dpE :* (E_out * neg_dbeta_dSig))
		}
	}
	// scores w.r.t. sig_ij where both i,j out
	for(j=1; j<=lout; j++) {
		beta_j = beta[j,]; invSig_out_j = invSig_out[,j]
		neg_dbeta_dSig = invSig_out_j * quadcross(invSig_out_j, Sig_out_in)
		scores[one2N,l++] = quadrowsum(dPhi_dpE :* (E_out * neg_dbeta_dSig))
		for(i=j+1; i<=lout; i++) {
			neg_dbeta_dSig = invSig_out[,i] * beta_j + invSig_out_j * beta[i,]
			scores[one2N,l++] = quadrowsum(dPhi_dpE :* (E_out * neg_dbeta_dSig))
		}
	}
	return (scores)
}

// (log) likelihood and scores for cumulative multivariate normal for a vector of observations of upper bounds and optional lower bounds
// i.e., computes multivariate normal cdf over L_1<=x_1<=U_1, L_2<=x_2<=U_2, ..., where some L_i's can be negative infinity
// Argument -bounded- indicates which dimensions have lower bounds as well as upper bounds.
// If argument N_perm>1, then returns Phi, not log Phi
// returns scores if requested in dPhi_dE, dPhi_dF, dPhi_dSig. dPhi_dF must already be allocated
real colvector vecmultinormal(real matrix E, real matrix F, real matrix Sig, real scalar d, real rowvector bounded, real colvector one2N, real scalar todo, 
						real matrix dPhi_dE, real matrix dPhi_dF, real matrix dPhi_dSig, transmorphic ghk2DrawSet, real scalar ghkAnti, real scalar GHKStart, real scalar N_perm) {
	real matrix dPhi_dE1, dPhi_dE2, dPhi_dF1, dPhi_dF2, _dPhi_dF2, _dPhi_dE1, _dPhi_dF1, _dPhi_dSig
	pragma unset dPhi_dE1; pragma unset dPhi_dE2; pragma unset dPhi_dF1; pragma unset dPhi_dF2; pragma unset _dPhi_dF2; pragma unset _dPhi_dE1; pragma unset _dPhi_dF1; pragma unset _dPhi_dSig
	real colvector Phi

	if (d == 1) {
		real scalar sqrtSig
		sqrtSig = sqrt(Sig[1,1])
		if (cols(bounded)) {
			Phi = normal2(F[,1]/sqrtSig, E[,1]/sqrtSig)
			if (todo) { // Compute partial deriv w.r.t. sig^2 in 1/sqrt(sig^2) term in normal dist
				if (N_perm == 1) {
					dPhi_dE =  editmissing(normalden(E, 0, sqrtSig), 0) :/ Phi
					dPhi_dF = -editmissing(normalden(F, 0, sqrtSig), 0) :/ Phi
				}
				dPhi_dSig = (rowsum(dPhi_dE :* E) + rowsum(dPhi_dF :* F)) / (-2 * Sig)
			}
		} else {
			Phi = normal(E / sqrtSig)
			if (todo) {
				if (N_perm == 1) dPhi_dE = editmissing(normalden(E, 0, sqrtSig), 0) :/ Phi
				dPhi_dSig = dPhi_dE :* E / (-2 * Sig)
			}
		}
		if (N_perm==1)
			return (ln(Phi))
		return (Phi)
	}

	if (d == 2) {
		if (cols(bounded)) {
			if (bounded[1]==1) {
				pointer (real colvector) scalar pE1, pF1
				pE1 = &(E[one2N,1]); pF1 = &(F[one2N,1])
				Phi = vecbinormal2(E[one2N,2], *pE1, *pF1, Sig, 1, 1, one2N, todo, dPhi_dE2, dPhi_dE1, dPhi_dF1, dPhi_dSig)
				if (bounded==1) {
					if (todo) {
						dPhi_dE = dPhi_dE1, dPhi_dE2
						dPhi_dF = dPhi_dF1, J(rows(E), 1, 0)
					}
				} else { // rectangular region integration 
					Phi = Phi - vecbinormal2(F[one2N,2], *pE1, *pF1, Sig, 0, 1, one2N, todo, _dPhi_dF2, _dPhi_dE1, _dPhi_dF1, _dPhi_dSig)
					if (todo) {
						dPhi_dE   = dPhi_dE1 -_dPhi_dE1, dPhi_dE2
						dPhi_dF   = dPhi_dF1 -_dPhi_dF1,         -_dPhi_dF2
						dPhi_dSig = dPhi_dSig-_dPhi_dSig
					}
				}
			} else {
				Phi = vecbinormal2(E[one2N,1], E[one2N,2], F[one2N,2], Sig, 1, 0, one2N, todo, dPhi_dE1, dPhi_dE2, dPhi_dF2, dPhi_dSig)
				if (todo) {
					dPhi_dE =         dPhi_dE1, dPhi_dE2
					dPhi_dF = J(rows(E), 1, 0), dPhi_dF2
				}
			}
		} else 
			Phi = vecbinormal(E, Sig, one2N, todo, dPhi_dE, dPhi_dSig)
	} else if (cols(bounded))
		if (todo)
			Phi = _ghk2_2d(ghk2DrawSet, F, E, Sig, ghkAnti, GHKStart, dPhi_dF, dPhi_dE, dPhi_dSig)
		else
			Phi = _ghk2_2 (ghk2DrawSet, F, E, Sig, ghkAnti, GHKStart)
	else if (todo)
			Phi = _ghk2_d (ghk2DrawSet,    E, Sig, ghkAnti, GHKStart,          dPhi_dE, dPhi_dSig)
		else
			Phi = _ghk2   (ghk2DrawSet,    E, Sig, ghkAnti, GHKStart)

	if (N_perm==1) {
		if (todo) {
			dPhi_dE = dPhi_dE :/ Phi
			dPhi_dSig = dPhi_dSig :/ Phi
			if (cols(bounded)) dPhi_dF = dPhi_dF :/ Phi
		}
		return(ln(Phi))
	}
	return (Phi)
}

// compute the log likelihood associated with a given error data matrix, for "continuous" variables
// Sig is the assumed covariance for the full error set and inds marks the observed variables assumed to have a joint normal distribution,
// i.e., the ones not censored
// dphi_dE should already be allocated
real colvector lnLContinuous(pointer(struct subview scalar) scalar v, real scalar todo) {
	real matrix C, t, phi, invSig; real rowvector in

	in = v->uncens
//if in were before out, then this would just be the upper left of cholesky(Omega)
	C = luinv(cholesky(v->Omega[in, in]))
	phi = quadrowsum(lnnormalden(v->EUncens * C')) :+ quadsum(ln(diagonal(C)), 1)
	if (todo) {
		t = v->EUncens * -(invSig = quadcross(C,C))
		v->dphi_dE[v->one2N, in] = t
		v->dphi_dSig[v->one2N, v->SigIndsUncens] = neg_half_E_Dinvsym_E(t, v->one2N, v->EDE) :- vech(invSig - diag(invSig)*.5)'
	}
	return (phi)
}

// log likelihood and scores for likelihood over total range of truncation--denominator of L
// returns scores in the optional arguments dPhi_dE, dPhi_dSig
real colvector lnLTrunc(pointer(struct subview scalar) scalar v, pointer (struct RE colvector) REs, real scalar todo) {
	real matrix dPhi_dEt, dPhi_dFt, dPhi_dSigt; real colvector Phi
	pragma unset dPhi_dEt; pragma unset dPhi_dFt; pragma unset dPhi_dSigt

	Phi = vecmultinormal(v->Et, v->Ft, v->Omega[v->trunc,v->trunc], v->d_trunc, v->one2d_trunc, v->one2N, todo, 
							dPhi_dEt, dPhi_dFt, dPhi_dSigt, REs->ghk2DrawSet, REs->ghkAnti, v->GHKStartTrunc, 1)

	if (todo) {
		v->dPhi_dEt[v->one2N,v->one2d_trunc] = dPhi_dEt +  dPhi_dFt
		v->dPhi_dSigt[v->one2N, v->SigIndsTrunc] = dPhi_dSigt
	}
	return (Phi)
}

// log likelihood and scores for cumulative normal
// returns scores in the optional arguments dPhi_dE, dPhi_dSig
real colvector lnLCensored(pointer(struct subview scalar) scalar v, pointer (struct RE colvector) REs, real scalar todo) {
	real matrix t, pSig, this_pSig, beta, dPhi_dpE, dPhi_dpSig, invSig_uncens, Sig_uncens_cens, S_dPhi_dpE, S_dPhi_dpSig
	real scalar ThisNumCuts, d_cens, d_two_cens, N_perm, ThisPerm
	real colvector Phi, i, j, S_Phi
	real rowvector uncens, cens, oprobit
	pointer (real matrix) pE, this_pE, pF, pQ_E
	pragma unset dPhi_dpE; pragma unset dPhi_dpSig

	uncens=v->uncens; oprobit=v->oprobit; cens=v->cens; d_cens=v->d_cens; d_two_cens=v->d_two_cens; N_perm=v->N_perm; ThisNumCuts=v->NumCuts

	if (v->d_uncens) { // Partial continuous variables out of the censored ones
		beta = (invSig_uncens = cholinv(v->Omega[uncens,uncens])) * (Sig_uncens_cens = v->Omega[uncens, cens])
		t = v->EUncens * beta
		this_pE = pE = &(v->ECens - t)                   // partial out errors from upper bounds
		if (d_two_cens)              // partial out errors from lower bounds
			pF = &(v->F - t)
		else
			pF = &J(0,0,0)
		this_pSig = pSig = v->Omega[cens, cens] - quadcross(Sig_uncens_cens, beta) // corresponding covariance
	} else {
		this_pE = pE = &(v->ECens)
		if (d_two_cens)
			pF = &(v->F)
		else
			pF = &J(0,0,0)
		this_pSig = pSig = v->Omega[cens, cens]
	}

	for (ThisPerm = N_perm; ThisPerm; ThisPerm--) {  
		if (v->NumRoprobitGroups) {
			pQ_E = v->roprobit_Q_E[ThisPerm]
			this_pE = &(*pE * -*pQ_E) // negation makes up for E being set, for speed, to theta instead of neg theta
			this_pSig = quadcross(*pQ_E, pSig) * *pQ_E
		}


		Phi = vecmultinormal(*this_pE, *pF, this_pSig, v->dCensNonrobase, v->two_cens, v->one2N, todo, dPhi_dpE, v->dPhi_dpF, dPhi_dpSig, 
		                            REs->ghk2DrawSet, REs->ghkAnti, v->GHKStart, N_perm)

		if (todo & v->NumRoprobitGroups) {
			dPhi_dpE = dPhi_dpE * *pQ_E'
			dPhi_dpSig = dPhi_dpSig * *v->roprobit_Q_Sig[ThisPerm]
		}
		
		if (N_perm > 1)
			if (ThisPerm == N_perm) {
				S_Phi = Phi
				if (todo) {
					S_dPhi_dpE   = dPhi_dpE
					S_dPhi_dpSig = dPhi_dpSig
				}
			} else {
				S_Phi = S_Phi + Phi
				if (todo) {
					S_dPhi_dpE   = S_dPhi_dpE   + dPhi_dpE
					S_dPhi_dpSig = S_dPhi_dpSig + dPhi_dpSig
				}
			}
	}

	if (N_perm > 1) {
		Phi = ln(S_Phi)
		if (todo) {
			dPhi_dpE = S_dPhi_dpE :/ S_Phi
			dPhi_dpSig = S_dPhi_dpSig :/ S_Phi
		}
	}

	if (todo) {
		real matrix dpE_dE, dpSig_dSig; real scalar lcut, lcat
		pointer (real colvector) pYi_lcat, pYi_lcatm1

		// Translate scores w.r.t. partialled errors and variance to ones w.r.t. unpartialled ones
		if (v->d_uncens) {
			t = I(cols(beta)), -beta'
			(dpE_dE = v->J_d_cens_d_0)[, v->cens_uncens] = t
			v->dPhi_dE = dPhi_dpE * dpE_dE
			(dpSig_dSig = v->J_d2_cens_d2_0)[, v->SigIndsCensUncens] = (t#t)[v->CensLTInds,] * v->dSig_dLTSig
			v->dPhi_dpE_dSig[v->one2N, v->SigIndsCensUncens] = 
					dPhi_dpE_dSig(v->EUncens, v->one2N, beta, invSig_uncens, Sig_uncens_cens, dPhi_dpE, d_cens, v->d_uncens, 
										v->_dPhi_dpE_dSig, v->J_d_uncens_d_cens_0)
			v->dPhi_dSig = dPhi_dpSig * dpSig_dSig + v->dPhi_dpE_dSig
		} else {
			v->dPhi_dE  [v->one2N, v->cens_uncens         ] = dPhi_dpE
			v->dPhi_dSig[v->one2N, v->SigIndsCensUncens] = dPhi_dpSig
		}

		if (d_two_cens) {
			if (v->d_uncens) {
				v->dPhi_dF = v->dPhi_dpF * dpE_dE
				v->dPhi_dpF_dSig[v->one2N, v->SigIndsCensUncens] = 
						dPhi_dpE_dSig(v->EUncens, v->one2N, beta, invSig_uncens, Sig_uncens_cens, v->dPhi_dpF, d_cens, v->d_uncens, 
											v->_dPhi_dpF_dSig, v->J_d_uncens_d_cens_0)
				v->dPhi_dSig = v->dPhi_dSig + v->dPhi_dpF_dSig
			} else
				v->dPhi_dF[v->one2N, v->cens_uncens] = v->dPhi_dpF
				
			if (ThisNumCuts) {
				lcat = (lcut = ThisNumCuts) + (i = v->d_oprobit) + 1
				for (; i; i--) { // for each oprobit eq
					pYi_lcat = &(v->Yi[v->one2N, --lcat])
					for (j = (v->vNumCuts)[i]; j; j--) {
						pYi_lcatm1 = &(v->Yi[v->one2N, --lcat])
						v->dPhi_dcuts[v->one2N, (v->CutInds)[lcut--]] = v->dPhi_dE[v->one2N, oprobit[i]] :* *pYi_lcatm1 + v->dPhi_dF[v->one2N, oprobit[i]] :* *pYi_lcat
						pYi_lcat = pYi_lcatm1
					}
				}
			}
			v->dPhi_dE = v->dPhi_dE + v->dPhi_dF
		}
	}
	return (Phi)
}

// translate draws or nodes at a given level, possibly adaptively shifted, into total effects of random effects and coefficients
void BuildTotalEffects(pointer (struct RE colvector) scalar REs, real scalar l) {
	real scalar r, eq; real matrix UT; pointer (struct RE scalar) scalar RE, base
	RE = &((*REs)[l]); base = &((*REs)[REs->L])
	for (r=(*REs)[l+1].NumREDraws; r; r--) {
		if (RE->HasRC) {
			UT = RE->J_N_NEq_0
			if (cols(RE->REInds))
			  UT[base->one2N, RE->REEqs] = RE->U[r].M * RE->T[, RE->REInds] // REs
		} else
			UT                           = RE->U[r].M * RE->T               // REs

		for (eq=RE->NEq; eq; eq--)               // RCs
			if (cols(RE->X[eq].M))
				UT[base->one2N,eq] = UT[base->one2N,eq] + quadrowsum((RE->U[r].M * RE->T[, RE->RCInds[eq].M]) :* RE->X[eq].M) // RCs * X
		if (REs->HasGamma)
			for (eq=cols(RE->GammaEqs); eq; eq--)
				RE->TotalEffect[r,eq].M = UT * RE->invGamma[,eq]
		else
			for (eq=cols(RE->GammaEqs); eq; eq--)
				RE->TotalEffect[r,eq].M = UT[base->one2N,eq]
	}
}

void BuildXU(pointer(struct subview scalar) scalar subviews, pointer (struct RE colvector) scalar REs, real scalar l, real scalar L) {
	real scalar c, r, j, k, e, eq1, eq2; pointer (struct RE scalar) scalar RE, base; pointer(struct subview scalar) scalar v
	RE = &((*REs)[l])
	base = &((*REs)[L])
	if (RE->HasRC)
		for (r=RE->R; r; r--) { // pre-compute X-U products in order most convenient for computing scores w.r.t upper-level T's
			k = e = 0
			for (eq1=1; eq1<=RE->NEq; eq1++)
				for (c=1; c<=cols(RE->X[eq1].M)+anyof(RE->REEqs, eq1); c++) {
					e++
					RE->XU[r,++k].M = c<=cols(RE->X[eq1].M)? RE->U[r].M[base->one2N,e]:*RE->X[eq1].M[|.,c\.,.|] : J(base->N, 0, 0)
					if (anyof(RE->REEqs, eq1))
						RE->XU[r,k].M = RE->XU[r,k].M, RE->U[r].M[base->one2N,e]
					for (eq2=eq1+1; eq2<=RE->NEq; eq2++) {
						RE->XU[r,++k].M = cols(RE->X[eq2].M)? RE->U[r].M[base->one2N,e] :*RE->X[eq2].M            : J(base->N, 0, 0)
						if (anyof(RE->REEqs, eq2))
							RE->XU[r,k].M = RE->XU[r,k].M, RE->U[r].M[base->one2N,e]
					}
				}
		}
	else
		for (r=RE->R; r; r--) // simpler form works when just REs
			for (j=RE->d; j; j--)
				RE->XU[r,j].M = RE->U[r].M[base->one2N,j]

	for (v = subviews; v!=NULL; v = v->next)
		for (r=RE->R; r; r--)
			for (j=cols(v->XU[l].M); j; j--)
				if (cols(RE->XU[r,j].M))
					v->XU[l].M[r,j].M = (RE->XU[r,j].M)[v->SubsampleInds,]
}

void _st_view(real matrix V, real scalar missing, string rowvector vars) {
	external real scalar _interactive; pragma unused missing
	if (vars != ".")
		if (_interactive) st_view(V, ., vars, st_global("ML_samp"))
			else            st_view(V, ., vars                      )
}











































































// main evaluator routine
// return value indicates whether parameters feasible. .=infeasible
// lf indicates lf or lf1 estimator:  name of variable to receive log likelihoods (otherwise stored in var _cmp_lnfi)
// ScoreVars indicates lf1 estimate: contains names of variables to store scores in
void cmp_lnL(real scalar todo, string scalar lf, | string rowvector ScoreVars) {
	real matrix Rho, t, L_g, invGamma, C
	real scalar i, j, k, l, m, _l, r, d, d2, L, tEq, EUncensEq, ECensEq, cols, NewIter
	real rowvector sig, rho, one2d, cuts
	real colvector this_lnL, shift, lnLmin, lnLmax, lnL, out, in
	string rowvector signames, atanhrhonames 
	pointer(struct subview scalar) scalar v
	pointer(real matrix) scalar pdlnL_dtheta, pdlnL_dSig
	pointer(struct scores scalar) scalar pScores
	external pointer(struct subview scalar) scalar _subviews
	pointer(struct subview scalar) scalar subviews
	external real scalar _first_call, _interactive, _NumCuts, _L, _REAnti, _REScramble, _ghkScramble, _HasGamma, _SigXform
	external real colvector _vNumCuts, _NumREDraws
	external real matrix _NumEff
	external pointer(real matrix) colvector _Eqs, _GammaEqs, _GammaInds // , _RC_T
	external struct RE colvector _REs
	pointer (struct RE colvector) scalar REs
	pointer (struct RE scalar) scalar RE, base
	pragma unset this_lnL; pragma unset out

	L = _L
	signames = tokens(st_local("sigs"))
	atanhrhonames = tokens(st_local("atanhrhos"))
	one2d = 1.. (d = cols(st_matrix(signames[L]))); d2 = d*(d+1)*.5
	ScoreVars = tokens(ScoreVars)
	
	if (_first_call | _interactive) {
		external real scalar _ghkDraws, _ghkAnti, _num_mprobit_groups, _mprobit_ind_base, _num_roprobit_groups, _roprobit_ind_base, _intreg, _trunc, _reverse, _Quadrature, _IntMethod, _QuadTol, _QuadIter
		external real matrix _mprobit_group_inds, _roprobit_group_inds, _nonbase_cases, _trunceqs, _intregeqs
		external string scalar _ghkType, _REType
		real scalar ghk_nobs, eq, eq1, eq2, c, e, d_oprobit, d_mprobit, d_roprobit, start, stop, PrimeIndex, Hammersley, NDraws, HasRE
		real matrix Yi, indicators, U, theta
		real colvector remaining, S
		real rowvector mprobit, cens_nonrobase, Primes
		pointer(struct subview scalar) scalar next
		string scalar varnames, Iter, LevelName
		struct scores scalar Scores
		pointer(real matrix) rowvector QuadData
		pragma unset indicators; pragma unset Yi; pragma unset theta; pragma unset in

		if (_first_call) {
			REs = &(_REs = RE(L, 1))
			REs->ghkAnti = _ghkAnti
			REs->NumCuts = _NumCuts
			REs->trunceqs = _trunceqs
			REs->intregeqs = _intregeqs
			REs->mprobit_ind_base = _mprobit_ind_base
			REs->roprobit_ind_base = _roprobit_ind_base
			REs->HasGamma = _HasGamma
			REs->GammaInds = _GammaInds
			REs->NumREDraws = 1
			REs->Quadrature = _Quadrature
			REs->AdaptivePhaseThisEst = REs->IntMethod = _IntMethod
			if (REs->IntMethod) {
				REs->QuadTol = _QuadTol
				REs->QuadIter = _QuadIter
			}
			REs->L = L
			REs->SigXform = _SigXform
			base = &((*REs)[L])
			REs->y = REs->Lt = REs->Ut = REs->yL = base->dOmega_dGamma = smatrix(d)
			base->dOmega_dGamma = smatrix(d,d)
		} else {
			REs=&_REs
			base = &((*REs)[L])
		}

		_st_view(indicators, ., "_cmp_ind" :+ strofreal(one2d))
		base->one2N = 1 :: (base->N = rows(indicators))

		for (l=L; l; l--) {
			RE = &((*REs)[l])
			RE->ThisDraw = 1
			RE->one2d = 1..( RE->d = cols(st_matrix(signames[l])) )
			RE->NEq = length(RE->Eqs = *_Eqs[l])
			RE->GammaEqs = *_GammaEqs[l]
			RE->theta = smatrix(d)
			RE->d2 = RE->d * (RE->d + 1) * .5
//			RE->RC_T = *(_RC_T[l])
			RE->dCns = cols(RE->RC_T) ? cols(RE->RC_T) : RE->d
			RE->NEff = _NumEff[l,RE->Eqs]
			
			if (cols(ScoreVars)) {
				// build dSigdParams, derivative of sig, vech(rho) vector w.r.t. vector of actual sig, rho parameters, reflecting "exchangeable" and "independent" options
				real scalar accross, within, c1, c2; string scalar cmp_covl, cmp_covl_eq1
				t = J(0, 1, 0); i = 0 // index of entries in full sig, vech(rho) vector
				if ((cmp_covl = st_global("cmp_cov"+strofreal(l))) == "exchangeable")
					accross  = ++i
				for (eq1=1; eq1<=RE->NEq; eq1++) {
					if ((cmp_covl_eq1 = st_global("cmp_cov"+strofreal(l)+"_"+strofreal(RE->Eqs[eq1]))) == "exchangeable")
						if (cmp_covl == "exchangeable")
							within = accross
						else
							within = ++i
					for (c1=1; c1<=RE->NEff[eq1]; c1++)
						if  (st_matrix("cmp_fixed_sigs"+strofreal(l))[1, RE->Eqs[eq1]] == .)
							if (anyof(("unstructured","independent"), cmp_covl_eq1) & cmp_covl != "exchangeable")
								t = t \ ++i
							else
								t = t \ within
						else
							t = t \ . // entry of sig vector corresponds to no parameter in model, being fixed
				}
				if (cmp_covl=="exchangeable" & RE->d>1)
					accross  = ++i
				for (eq1=1; eq1<=RE->NEq; eq1++) {
					if ((cmp_covl_eq1 = st_global("cmp_cov"+strofreal(l)+"_"+strofreal(RE->Eqs[eq1])))=="exchangeable" & RE->NEff[eq1]>1)
						within = ++i
					for (c1=1; c1<=RE->NEff[eq1]; c1++) {
						for (c2=c1+1; c2<=RE->NEff[eq1]; c2++) {
							if (cmp_covl_eq1=="unstructured")
								within = ++i
							t = t \ (cmp_covl_eq1=="independent"? . : within)
						}
						for (eq2=eq1+1; eq2<=RE->NEq; eq2++)
							for (c2=1; c2<=RE->NEff[eq2]; c2++) {
								if (st_matrix("cmp_fixed_rhos"+strofreal(l))[RE->Eqs[eq2],RE->Eqs[eq1]]==.) {
									if (cmp_covl == "unstructured")
										accross = ++i
									t = t \ accross
								} else
									t = t \ .
						}
					}
				}
				RE->dSigdParams = i? designmatrix(editmissing(t,i+1))[|.,.\.,i|] : J(RE->d2, 0, 0)
			}
		}

		for (i=d; i; i--) {
			_st_view(REs->y   [i].M,  ., st_global("cmp_y"   + strofreal(i)))
			if (_trunc) {
			  _st_view(REs->Lt[i].M,  ., st_global("cmp_Lt"  + strofreal(i)))
			  _st_view(REs->Ut[i].M,  ., st_global("cmp_Ut"  + strofreal(i)))
			}

			if (REs->intregeqs[i])
			  _st_view(REs->yL[i].M,  ., st_global("cmp_y" + strofreal(i) + "_L"))
		}

		if (L > 1)
			base->lnL = J(base->N, 1, 0)
		else if (strlen(lf) == 0)
			_st_view(base->lnL, ., "_cmp_lnfi")

		Primes = 2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109
		if (L>1 & _REType != "random" & length(Primes) < strtoreal(st_global("cmp_NSimEff")) + d - 1 - (_ghkType=="hammersley" | _REType=="hammersley")) {
			errprintf("Number of unobserved variables to simulate too high for Halton-based simulation. Try {cmd retype(random)}.\n")
			return 
		}
		PrimeIndex = 1

		if (cols(ScoreVars)) {
			Scores = scores()
			REs->G = J(d, 1, 0); Scores.GammaScores = smatrix(d*d) // more than needed
			cols = d + 1
			for (c=m=1; m<=d; m++)
				for (i=1; i<=(REs->G[m]=rows(*REs->GammaInds[m])); i++)
				                _st_view(Scores.GammaScores[c++].M, ., ScoreVars[cols++]                      )
			                  _st_view(Scores.ThetaScores       , ., ScoreVars[|.    \ d                  |])
			if (REs->NumCuts) _st_view(Scores.CutScores         , ., ScoreVars[|cols \ cols+REs->NumCuts-1|])
			cols = cols + REs->NumCuts
			Scores.SigScores = smatrix(L)
			for (l=1; l<=L; l++)
				if (t = cols((*REs)[l].dSigdParams)) {
			                  _st_view(Scores.SigScores[l].M    , ., ScoreVars[|cols \ cols+t-1           |])
					cols = cols + t
				}
		}

		for (l=L-1; l; l--)
			_st_view((*REs)[l].id,  ., "_cmp_id" + strofreal(l))

		for (l=L-1; l; l--) {
			RE = &((*REs)[l])

			if (_first_call) {
				RE->one2N = 1 :: ( RE->N = RE->id[base->N] )
				RE->J_N_1_0 = J(RE->N, 1, 0)
				RE->REInds = OneInds(tokens(st_global("cmp_rc"+strofreal(l))) :== "_cons")
				RE->X = RE->RCInds = smatrix(RE->NEq)

				RE->HasRC = 0
				for (start=j=1; j<=RE->NEq; j++) {
					if (HasRE = st_global("cmp_re"+strofreal(l)+"_"+strofreal(RE->Eqs[j])) != "")
						RE->REEqs = RE->REEqs, j
					if (strlen(varnames = st_global("cmp_rc"+strofreal(l)+"_"+strofreal(RE->Eqs[j])))) {
						RE->HasRC = 1
						RE->X[j].M = st_data(., varnames)
						stop = start + cols(tokens(varnames))
						RE->RCInds[j].M = start..stop-1
						start = stop + HasRE
					}
				}
				if (RE->HasRC) RE->J_N_NEq_0 = J(base->N, RE->NEq, 0)

				RE->IDRanges = panelsetup(RE->id, 1)
				RE->IDRangesGroup = l==L-1? RE->IDRanges : panelsetup(RE->id[(*REs)[l+1].IDRanges[,1]], 1)

				Hammersley = _REType=="hammersley" & l==1
				
				LevelName = L>2? " for level " +strofreal(l) : ""
				if (REs->Quadrature)
						if (REs->IntMethod) {
							if (l==1) printf("{res}Performing %s adaptive quadrature.\n",("Naylor-Smith", "Richard-Zhang")[REs->IntMethod])
						} else if (RE->d == 1)
							printf("{res}Random effects/coefficients%s modeled with Gauss-Hermite quadrature.\n", LevelName)
						else {
							printf("{res}Random effects/coefficients%s modeled with%s quadrature.\n", LevelName, RE->d>2 ? " sparse-grid" : "")
							printf("Precision equivalent to one-dimensional quadrature with %f integration points.\n", _NumREDraws[l+1])
						}
				else {
					printf("{res}Random effects/coefficients%s simulated.\n", LevelName)
					printf("    Sequence type = %s\n", _REType)
					printf("    Number of draws per observation = %f\n", _NumREDraws[l+1]/_REAnti)
					printf("    Include antithetic draws = %s\n", _REAnti==2? "yes" : "no")
					printf("    Scramble = %s\n", _REScramble? "yes" : "no")
					if ((_REType=="halton" | _REType=="ghalton") | (Hammersley & RE->d>1))
						printf("    Prime base%s = %s\n", RE->d > 1+Hammersley? "s" : "", invtokens(strofreal(Primes[PrimeIndex..PrimeIndex-1+RE->dCns-Hammersley])))
					if (l==1) printf(`"Each observation gets different draws, so changing the order of observations in the data set would change the results.\n\n"')
				}

				if (REs->Quadrature) {
					QuadData = SpGr(RE->d, _NumREDraws[l+1])
					NDraws = (*REs)[l+1].NumREDraws = rows(*QuadData[1])
					if (_first_call & !REs->IntMethod) printf("Number of integration points = %f.\n\n", NDraws)
	 // inefficiently duplicates draws over groups then parcels them out below
					U = J(RE->N, 1, 1) # (*QuadData[1])
					RE->QuadX = *QuadData[1]
					RE->QuadW = *QuadData[2]'
					if (REs->IntMethod) {
						REs->todo = cols(ScoreVars)
						RE->QuadMean = RE->QuadSD = RE->QuadXAdapt = smatrix(RE->N)
						for (j=RE->N; j; j--) {
							RE->QuadXAdapt[j].M = RE->QuadX
							RE->QuadSD[j].M = J(RE->d, 1, .)
						}
						RE->AdaptiveShift = J(RE->N, NDraws, 0)
						RE->lnnormaldenQuadX = quadrowsum(lnnormalden(RE->QuadX))'
						REs->LastlnLThisIter=0; REs->LastlnLLastIter=1
					}
				} else {
					NDraws = ((*REs)[l+1].NumREDraws = _NumREDraws[l+1]) / _REAnti
					if (_REType=="random")
						U = invnormal(uniform(RE->N * NDraws / _REAnti, RE->d))
					else if (_REType=="halton" | Hammersley) {
						U = J(RE->N * NDraws, RE->d, 0)
						if (Hammersley)
							U[,1] = invnormal(J(RE->N,1,1) # (0.5::NDraws)/NDraws)
						for (r=1+Hammersley; r<=cols(U); r++)
							U[,r] = invnormal(halton2(rows(U), Primes[PrimeIndex++], _REScramble? &ghk2SqrtScrambler() : J(1,0,NULL)))
					} else {
						U = J(RE->N * NDraws, RE->d, 0)
						for (r=1; r<=cols(U); r++)
							U[,r] = invnormal(ghalton(rows(U), Primes[PrimeIndex++], uniform(1,1)))
					}
				}
				RE->one2R = 1..(RE->R = (*REs)[l+1].NumREDraws)
				RE->U = smatrix(RE->R)
				RE->TotalEffect = smatrix(RE->R, cols(RE->GammaEqs))
				RE->XU          = smatrix(RE->R, sum((RE->NEq..1) :* RE->NEff))

	//			if (rows(RE->RC_T)) // expand reduced set of simulated effects set into full, constrained set
	//				U = U * RE->RC_T'

				S = ((1::RE->N) * NDraws)[RE->id]
				for (r=NDraws; r; r--) {
					RE->U[r].M = U[S, RE->one2d]
					if (_REAnti == 2)
						RE->U[r+RE->R*0.5].M = -RE->U[r].M
					S = S :- 1
				}

				RE->lnLlimits = ln(smallestdouble()) + 1, ln(maxdouble()) - (RE->lnNumREDraws = ln(RE->R)) - 1

				RE->lnLByDraw = J(RE->N, RE->R, 0)
			} // if (_first_call)
		}

		if (_first_call) {
			if (L > 1) {
				for (l=L; l; l--)
					if (st_global("parse_wexp"+strofreal(l)) != "") {
						RE = &((*REs)[l])
						_st_view(RE->Weights, ., "_cmp_weight"+strofreal(l))
						if (l < L) RE->Weights = RE->Weights[RE->IDRanges[,1]] // get one instance of each group's weight
						if (anyof(("pweight", "aweight"), st_global("parse_wtype"+strofreal(l)))) // normalize pweights, aweights to sum to # of groups
							if (l == 1)
								REs->Weights = RE->Weights / mean(RE->Weights)
							else
								for (j=(*REs)[l-1].N; j; j--) {
									S = (*REs)[l-1].IDRangesGroup[j,]', (.\.)
									RE->Weights[|S|] = RE->Weights[|S|] / mean(RE->Weights[|S|])
								}
						t = l==L? RE->Weights : RE->Weights[RE->id]
						REs->WeightProduct = rows(REs->WeightProduct)? REs->WeightProduct:* t : t
					}
			}

			for (l=L-1; l; l--)
				(*REs)[l].IDRangesGroup = (*REs)[l].IDRangesGroup[,2]
		}

		ghk_nobs = 0; v = NULL

		remaining = base->one2N
		while (t = max(remaining)) { // build linked list of subviews onto data, each a set of rows with same indicator combination
			next = v; (v = &(subview()))->next = next  // add new subview to linked list
			remaining = remaining :* !(v->subsample = rowmin(indicators :== (v->TheseInds = indicators[t,])))
			v->SubsampleInds = OneInds(v->subsample)
			if (!strlen(lf)) st_select(v->lnL, base->lnL, v->subsample)
			v->theta = v->tau = smatrix(d)
			v->QE = diag(2*(v->TheseInds:==3 :| v->TheseInds:==8) :- 1)
			v->one2N = 1 :: (v->N = colsum(v->subsample))
			v->d_uncens = cols(v->uncens = OneInds(v->TheseInds:==1))
			d_oprobit = cols(v->oprobit = OneInds(v->TheseInds:==5))
			v->d_trunc = cols(v->trunc = OneInds(REs->trunceqs))
			v->d_cens         = cols(v->cens          = OneInds(                   v->TheseInds:>1 :& v->TheseInds:<. :& (v->TheseInds:<REs->mprobit_ind_base :| v->TheseInds:>=REs->roprobit_ind_base)))
			v->dCensNonrobase = cols(cens_nonrobase   = OneInds(_nonbase_cases :& (v->TheseInds:>1 :& v->TheseInds:<. :& (v->TheseInds:<REs->mprobit_ind_base :| v->TheseInds:>=REs->roprobit_ind_base))))
			if (v->d_cens)
				v->d_two_cens = cols(v->two_cens = OneInds((v->TheseInds:==5 :| v->TheseInds:==7 :| (v->TheseInds:==2 :| v->TheseInds:==3 :| v->TheseInds:==4 :| v->TheseInds:==8) :& REs->trunceqs)[v->cens])) //indexes *within* list of censored eqs of doubly censored ones
			else
				v->d_two_cens = 0
			
			if (v->d_cens > 2) {
				v->GHKStart = ghk_nobs + 1
				ghk_nobs = ghk_nobs + v->N
			}
			if (v->d_uncens) v->EUncens = J(v->N, v->d_uncens, 0)
			if (v->d_cens)   v->ECens   = J(v->N, v->d_cens  , 0)
			if (REs->NumCuts | _intreg | _trunc) {
				v->F = J(v->N, v->d_cens, 0)
				if (_trunc)
					v->Et = v->Ft = J(v->N, v->d_trunc, .)
			}

			if (d_oprobit) {
				l = 1
				if (v->oprobit[1]>1) l = l + colsum(_vNumCuts[1::v->oprobit[1]-1])
				v->CutInds = l .. l+_vNumCuts[v->oprobit[1]]-1
				for (k=2; k<=d_oprobit; k++) {
					l = l + colsum(_vNumCuts[v->oprobit[k-1]::v->oprobit[k]-1])
					v->CutInds = v->CutInds, l .. l+_vNumCuts[v->oprobit[k]]-1
				}
				v->vNumCuts = _vNumCuts[v->oprobit]

 				v->NumCuts = cols(v->CutInds)
			} else
				v->NumCuts = 0

			if (v->NumMprobitGroups = _num_mprobit_groups) {
				v->mprobit = mprobit_group(v->NumMprobitGroups)

				for (k=v->NumMprobitGroups; k; k--) {
					start = _mprobit_group_inds[k, 1]; stop = _mprobit_group_inds[k, 2]

					v->mprobit[k].d = d_mprobit = cols( mprobit = OneInds(v->TheseInds :& one2d:>=start :& one2d:<=stop) ) - 1

					if (d_mprobit>0) {
						v->mprobit[k].out = v->TheseInds[start] - REs->mprobit_ind_base // eq of chosen alternative
						v->mprobit[k].res = OneInds((v->TheseInds :& one2d:>start  :& one2d:<=stop)[v->cens]) // index in v->ECens for relative differencing results
						v->mprobit[k].in =  OneInds( v->TheseInds :& one2d:>=start :& one2d:<=stop :& one2d:!=v->mprobit[k].out) // eqs of rejected alternatives
						(v->QE)[mprobit, mprobit] = J(d_mprobit+1, 1, 0), insert(-I(d_mprobit), v->mprobit[k].out-start+1, J(1, d_mprobit, 1))
					}
				}
			}

			v->N_perm = 1
			if (v->NumRoprobitGroups = _num_roprobit_groups) {
				pointer(real rowvector) colvector roprobit
				real rowvector this_roprobit
				pointer (real matrix) colvector perms
				pointer(real matrix) ThesePerms
				real scalar ThisPerm
				
				perms = roprobit = J(v->NumRoprobitGroups, 1, NULL)
				v->dCensNonrobase = cols(v->cens)
				v->d2_cens = v->d_cens * (v->d_cens + 1)*.5

				for (k=v->NumRoprobitGroups; k; k--)
					if (cols(this_roprobit=*(roprobit[k] = &OneInds(v->TheseInds :& one2d:>=_roprobit_group_inds[k,1] :& one2d:<=_roprobit_group_inds[k,2]))))
						v->N_perm = v->N_perm * (rows(*(perms[k] = &PermuteTies(_reverse? v->TheseInds[this_roprobit] : -v->TheseInds[this_roprobit]))))
				
				v->roprobit_Q_E = v->roprobit_Q_Sig = J(i=v->N_perm, 1, NULL)
				for (; i; i--) { // combinations of perms across multiple roprobit groups
					j = i - 1
					t = I(d)
					for (k = v->NumRoprobitGroups; k; k--) 
						if (d_roprobit = cols(this_roprobit = *roprobit[k])) {
							ThisPerm = mod(j, rows(*(ThesePerms=perms[k]))) + 1
							t[this_roprobit, this_roprobit] = 
								J(d_roprobit, 1, 0), (I(d_roprobit)[,(*ThesePerms)[|ThisPerm, 2 \ ThisPerm, .           |]] - 
								                      I(d_roprobit)[,(*ThesePerms)[|ThisPerm, 1 \ ThisPerm, d_roprobit-1|]] )
							j = (j - ThisPerm + 1) / rows(*ThesePerms)
						}
					(v->roprobit_Q_Sig)[i] = &QE2QSig(*((v->roprobit_Q_E)[i] = &t[v->cens, cens_nonrobase]))
				}
			}

			if (v->d_trunc) {
				v->one2d_trunc = 1..v->d_trunc
				v->SigIndsTrunc = vSigInds(v->trunc, d)

				if (v->d_trunc > 2) {
					v->GHKStartTrunc = ghk_nobs + 1
					ghk_nobs = ghk_nobs + v->N
				}
			}

			if (REs->todo) {
				v->XU = ssmatrix(L-1)
				for (l=L-1; l; l--)
					v->XU[l].M = smatrix(rows(RE->XU), cols(RE->XU))
			}

			if (cols(ScoreVars)) { // pre-compute stuff for scores
				v->Scores = scorescol(L)
				for (l=L; l; l--) {
					v->Scores[l].M = scores((*REs)[l].NumREDraws)
					for (r=(*REs)[l].NumREDraws; r; r--) {
						v->Scores[l].M[r].GammaScores = smatrix(sum(REs->G))
						v->Scores[l].M[r].TScores = smatrix(L) // last entry holds scores of base-level Sig parameters not T
					}
				}
				v->Scores.M.SigScores = smatrix(L)
				v->id =  smatrix(L-1)
				for (l=L-1; l; l--)
					v->id[l].M = (*REs)[l].id[v->SubsampleInds,]

				if (rows(REs->WeightProduct)) v->WeightProduct = REs->WeightProduct[v->SubsampleInds,]
					
				                                   st_select(v->Scores.M.ThetaScores     , Scores.ThetaScores     , v->subsample)
				if (REs->NumCuts)                  st_select(v->Scores.M.CutScores       , Scores.CutScores       , v->subsample)
				for (c=L; c; c--)
					if (cols((*REs)[c].dSigdParams)) st_select(v->Scores.M.SigScores  [c].M, Scores.SigScores[c].M  , v->subsample)
				for (c=sum(REs->G); c; c--)        st_select(v->Scores.M.GammaScores[c].M, Scores.GammaScores[c].M, v->subsample)

				for (l=L-1; l; l--)
					for (r=base->NumREDraws; r; r--)
						v->Scores[L].M[r].TScores[l].M = J(v->N, (*REs)[l].d2, 0)

				v->J_N_1_0 = J(v->N, 1, 0)

				v->dOmega_dGamma = smatrix(d,d)
				
				v->SigIndsUncens = vSigInds(v->uncens, d)
				v->d_oprobit = d_oprobit
				v->cens_uncens = v->cens, v->uncens
				v->J_d_uncens_d_cens_0 = J(v->d_uncens, v->d_cens, 0)
				v->J_d_cens_d_0 = J(v->d_cens, d, 0)
				v->J_d2_cens_d2_0 = J(v->d_cens*(v->d_cens+1)*0.5, d2, 0)				

				if (!v->d_uncens) 
					v->dPhi_dE = J(v->N, d, 0)
				else {
					v->dphi_dE = J(v->N, d, 0)
					v->dphi_dSig = J(v->N, d2, 0)
					v->EDE = J(v->N, v->d_uncens*(v->d_uncens+1)*.5, 0)
				}

				if (v->d_two_cens | v->d_trunc) {
					v->dPhi_dpF = J(v->N, v->d_cens, 0)
					if (!v->d_uncens)
						v->dPhi_dF = J(v->N, d, 0)
					if (v->d_trunc) {
						v->dPhi_dEt = J(v->N, d,  0)
						v->dPhi_dSigt = J(v->N, d2, 0)
					}
				}

				if (v->d_cens & !v->d_uncens)
					v->dPhi_dSig = J(v->N, d2, 0)
				if (v->d_cens & v->d_uncens) {
					v->dPhi_dpE_dSig = J(v->N, d2, 0)
					v->_dPhi_dpE_dSig = J(v->N, (v->d_cens+v->d_uncens)*(v->d_cens+v->d_uncens+1)*.5, 0)
				}
				if (v->d_two_cens & v->d_uncens) {
					v->dPhi_dpF_dSig = J(v->N, d2, 0)
					v->_dPhi_dpF_dSig = J(v->N, (v->d_cens+v->d_uncens)*(v->d_cens+v->d_uncens+1)*.5, 0)
				}
				if (REs->NumCuts) v->dPhi_dcuts = J(v->N, REs->NumCuts, 0)
				
				if (v->d_cens)
					v->CensLTInds = vech(colshape(1..v->d_cens*v->d_cens, v->d_cens)')

				if (d_oprobit) {
					varnames = ""
					for (k=1; k<=d_oprobit; k++) {
						stata("unab yis: _cmp_y" + strofreal(v->oprobit[k]) + "_*")
						varnames = varnames + " " + st_local("yis")
					}
					_st_view(Yi, ., tokens(varnames))
					st_select(v->Yi, Yi, v->subsample)
				}

				v->QSig = QE2QSig(v->QE)'
				v->SigIndsCensUncens = vSigInds(v->cens_uncens, d)
				v->dSig_dLTSig = Dmatrix(v->d_cens + v->d_uncens)
			}
		}
		_subviews = v

		if (cols(ScoreVars))
			for (l=L-1; l; l--)
				BuildXU(v, REs, l, L)

		if (ghk_nobs) {
			// by default, make # draws at least sqrt(N) (Cappellari and Jenkins 2003)
			if (_ghkDraws == 0) _ghkDraws = ceil(2 * sqrt(ghk_nobs+1))

			if ((!_interactive | _first_call) & !REs->IntMethod) {
				printf("{res}Likelihoods for %f observations involve cumulative normal distributions above dimension 2.\n", ghk_nobs)
				printf(`"Using {stata "help ghk2" :ghk2()} to simulate them. Settings:\n"')
				printf("    Sequence type = %s\n", _ghkType)
				printf("    Number of draws per observation = %f\n", _ghkDraws)
				printf("    Include antithetic draws = %s\n", _ghkAnti? "yes" : "no")
				printf("    Scramble = %s\n", _ghkScramble? "yes" : "no")
				printf("    Prime bases = %s\n", invtokens(strofreal(Primes[PrimeIndex..PrimeIndex-2+d])))
				if (_ghkType=="random" | _ghkType=="ghalton")
					printf(`"    Initial {stata "help mf_uniform" :seed string} = %s\n"', uniformseed())
				printf(`"Each observation gets different draws, so changing the order of observations in the data set would change the results.\n\n"')
			}
			
			REs->ghk2DrawSet = ghk2setup(ghk_nobs, _ghkDraws, d, _ghkType, PrimeIndex, _ghkScramble? &ghk2SqrtScrambler() : J(1,0,NULL))
		}
		
		if ((ghk_nobs & (_ghkType=="random" | _ghkType=="ghalton")) | (L>1 & (_REType=="random" | _REType=="ghalton")))
			printf("Starting seed for random number generator = %s\n", st_strscalar("c(seed)"))
		
		_first_call = 0 // done with one-time prep
	} else {
		REs=&_REs
		base = &((*REs)[L])
	}
	subviews = _subviews
	cuts = st_matrix(st_local("cuts"))

	if (strlen(lf)) _st_view(base->lnL, ., lf)

	for (eq1=d; eq1; eq1--)
		_st_view(REs->theta[eq1].M, ., "_cmp_theta"+strofreal(eq1))

	if (REs->HasGamma) {
		invGamma = luinv(I(d) - st_matrix(st_local("Gamma")))
		if (invGamma[1,1] == .) return
		_st_view(theta, ., "_cmp_theta" :+ strofreal(1..d))
		for (eq1=d; eq1; eq1--)
			REs->theta[eq1].M = theta * invGamma[,eq1]
	}

	if (REs->AdaptivePhaseThisEst)
		NewIter = (Iter = st_global("ML_ic")) != REs->LastIter

	for (l=1; l<=L; l++) {
		RE = &((*REs)[l])

		sig = st_matrix(signames[l])
		if (RE->d == 1) {
			Rho = J(0,0,0); rho = J(1,0,0)
			RE->Sig = (RE->T = sig) * sig
		} else {
			rho = st_matrix(atanhrhonames[l])
			Rho = I(RE->d); k = 0
			for (j=1; j<=RE->d; j++)
				for (i=j+1; i<=RE->d; i++)
					if (REs->SigXform)
						if (rho[++k]>100)
							Rho[i,j] = 1
						else if (rho[k]<-100)
							Rho[i,j] = -1
						else
							Rho[i,j] = tanh(rho[k])
					else
						Rho[i,j] = rho[++k]
			_makesymmetric(Rho)
			RE->T = cholesky(Rho)' :* sig
			if (RE->T[1,1] == .) return
			RE->Sig = quadcross(sig,sig) :* Rho
		}

		if (todo)
			RE->D = dSigdsigrhos(REs, RE, sig, RE->Sig, rho, Rho) * RE->dSigdParams

		if (REs->HasGamma)
			RE->invGamma = invGamma[RE->Eqs,RE->GammaEqs]

		if (l < L) {
			BuildTotalEffects(REs, l)
			for (eq1=cols(RE->GammaEqs); eq1; eq1--) // compute effect of first draws
				(*REs)[l+1].theta[RE->GammaEqs[eq1]].M = RE->theta[RE->GammaEqs[eq1]].M + RE->TotalEffect[1,eq1].M
			for (eq1=d; eq1; eq1--) // by default lower errors = upper ones, for eqs with no random effects/coefs at this level
				if (!anyof(RE->GammaEqs,eq1))
					(*REs)[l+1].theta[eq1].M = RE->theta[eq1].M
			if (todo)
				RE->D = ghk2_dTdV(RE->T') * RE->D
			if (REs->AdaptivePhaseThisEst & NewIter)
				RE->ToAdapt = J(RE->N, 1, 2)
			RE->AdaptivePhaseThisIter = 0
		}
	}

	if (REs->HasGamma) {
		if (todo) {
			base->dOmega_dSig = QE2QSig(invGamma)
			t = Lmatrix(d) * vec(base->Sig)'#I(d*d) * I(d)#_Kmatrix(d)#I(d) * (I(d*d)#vec(invGamma') + vec(invGamma')#I(d*d)) * _Kmatrix(d)
			for (m=d; m; m--)
				for (c=1; c<=REs->G[m]; c++)
					base->dOmega_dGamma[m,c].M = t * invGamma[m,]'#invGamma[,(*REs->GammaInds[m])[c]]
		}
		base->Omega = quadcross(invGamma, base->Sig) * invGamma
	} else
		base->Omega = base->Sig
	

	for (v = subviews; v!=NULL; v = v->next) {
		v->Omega = quadcross(v->QE, base->Omega) * v->QE
		if (todo)
			if (REs->HasGamma) {
				for (m=d; m; m--) {
					st_select(v->tau[m].M, REs->theta[m].M, v->subsample)
					if (REs->G[m] & v->TheseInds[m])
						for (c=1; c<=REs->G[m]; c++)
							v->dOmega_dGamma[m,c].M = v->QSig * base->dOmega_dGamma[m,c].M
				}
				v->QEinvGamma    = quadcross(v->QE, invGamma')
				v->invGammaQSigD = quadcross(v->QSig, base->dOmega_dSig) * base->D
			} else {
				v->QEinvGamma    = v->QE'
				v->invGammaQSigD = quadcross(v->QSig, base->D)
			}
	}

	do {   // for each draw combination
		for (v = subviews; v!=NULL; v = v->next) {
			tEq = EUncensEq = ECensEq = 0
			for (i=1; i<=d; i++)
				if (v->TheseInds[i]==6) // handle mprobit eqs below
					++ECensEq
				else {
					if (v->TheseInds[i]<REs->mprobit_ind_base | v->TheseInds[i]>=REs->roprobit_ind_base) { // skip mprobit base eqs but includes unobserved cade (TheseInds=.)
						if(REs->HasGamma | L > 1)
							v->theta[i].M = base->theta[i].M[v->SubsampleInds]
						else
							st_select(v->theta[i].M, base->theta[i].M, v->subsample)

						if (v->TheseInds[i] & v->TheseInds[i]<.) {
							if (v->TheseInds[i]==1)
								v->EUncens[v->one2N,++EUncensEq] = REs->y[i].M[v->SubsampleInds] - v->theta[i].M
							else if (v->TheseInds[i]==2 | v->TheseInds[i]==7)
								v->ECens  [v->one2N,++ECensEq  ] = REs->y[i].M[v->SubsampleInds] - v->theta[i].M
							else if (v->TheseInds[i]==3)
								v->ECens  [v->one2N,++ECensEq  ] =  v->theta[i].M - REs->y[i].M[v->SubsampleInds]
							else if (v->TheseInds[i]==4)
								v->ECens  [v->one2N,++ECensEq  ] = -v->theta[i].M
							else if (v->TheseInds[i]==8)
								v->ECens  [v->one2N,++ECensEq  ] =  v->theta[i].M
							else if (v->TheseInds[i]==5) {
								if (REs->trunceqs[i]) {
									t = REs->y[i].M[v->SubsampleInds] :> v->vNumCuts[i] // bit of inefficiency in truncated oprobit case
									v->ECens[v->one2N,++ECensEq] = (t :* REs->Ut[i].M[v->SubsampleInds] + (1:-t) :* cuts[REs->y[i].M[v->SubsampleInds]:+1, i]) - v->theta[i].M
								} else
									v->ECens[v->one2N,++ECensEq] = cuts[REs->y[i].M[v->SubsampleInds]:+1, i] - v->theta[i].M
							} else // roprobit
								v->ECens[v->one2N,++ECensEq] = v->theta[i].M

							if (cols(v->F)) {
								if (v->TheseInds[i]==7)
									v->F[v->one2N,ECensEq] = REs->yL[i].M[v->SubsampleInds] - v->theta[i].M
								else if (v->TheseInds[i]==5)
									if (REs->trunceqs[i]) {
										t = REs->y[i].M[v->SubsampleInds]
										v->F[v->one2N,ECensEq] = (t :* REs->Lt[i].M[v->SubsampleInds] + (1:-t) :* cuts[REs->y[i].M[v->SubsampleInds], i]) - v->theta[i].M
									} else
										v->F[v->one2N,ECensEq] = cuts[ REs->y[i].M[v->SubsampleInds], i] - v->theta[i].M
								else if (REs->trunceqs[i])
									if (v->TheseInds[i]==2)
										v->F[v->one2N,ECensEq] = REs->Lt[i].M[v->SubsampleInds] - v->theta[i].M
									else if (v->TheseInds[i]==3)
										v->F[v->one2N,ECensEq] = v->theta[i].M - REs->Ut[i].M[v->SubsampleInds]
									else if (v->TheseInds[i]==4)
										v->F[v->one2N,ECensEq] = REs->Lt[i].M[v->SubsampleInds] - v->theta[i].M
									else if (v->TheseInds[i]==8)
										v->F[v->one2N,ECensEq] = v->theta[i].M - REs->Ut[i].M[v->SubsampleInds]
							}

							if (REs->trunceqs[i]) {
								++tEq
								if (v->TheseInds[i]==2) {
									v->Et[v->one2N,tEq] = REs->Ut[i].M[v->SubsampleInds] - v->theta[i].M
									v->Ft[v->one2N,tEq] = v->F[v->one2N,i]
								} else if (v->TheseInds[i]==3) {
									v->Et[v->one2N,tEq] = v->theta[i].M - REs->Lt[i].M[v->SubsampleInds]
									v->Ft[v->one2N,tEq] = v->F[v->one2N,i]
								} else if (v->TheseInds[i]==4) {
									v->Et[v->one2N,tEq] = REs->Ut[i].M[v->SubsampleInds] - v->theta[i].M
									v->Ft[v->one2N,tEq] = v->F[v->one2N,i]
								} else if (v->TheseInds[i]==8) {
									v->Et[v->one2N,tEq] = v->theta[i].M - REs->Lt[i].M[v->SubsampleInds]
									v->Ft[v->one2N,tEq] = v->F[v->one2N,i]
								} else if (anyof((1,5,7), v->TheseInds[i])) {
									v->Et[v->one2N,tEq] = REs->Ut[i].M[v->SubsampleInds] - v->theta[i].M
									v->Ft[v->one2N,tEq] = REs->Lt[i].M[v->SubsampleInds] - v->theta[i].M
								}
							}
						}
					}
				}

			for (j=v->NumMprobitGroups; j; j--) // relative-difference mprobit errors
				if (v->mprobit[j].d > 0)
					if(isview(base->theta.M)) { // non-hierarchical model?
						st_select(out, base->theta[v->mprobit[j].out].M, v->subsample)
						for (i=v->mprobit[j].d; i; i--) {
							st_select(in, base->theta[(v->mprobit[j].in)[i]].M, v->subsample)
							v->ECens[v->one2N,(v->mprobit[j].res)[i]] = out - in
						}
					} else {
						out = base->theta[v->mprobit[j].out].M[v->SubsampleInds]
						for (i=v->mprobit[j].d; i; i--)
							v->ECens[v->one2N,(v->mprobit[j].res)[i]] = out - base->theta[(v->mprobit[j].in)[i]].M[v->SubsampleInds]
					}

			if (v->d_cens) {
				lnL = lnLCensored(v, REs, todo)
				if (v->d_uncens)
					lnL = lnL + lnLContinuous(v, todo)
			} else
				lnL = lnLContinuous(v, todo)

			if (v->d_trunc)
				lnL = lnL - lnLTrunc(v, REs, todo)
			if (strlen(lf)) {
				st_select(this_lnL, base->lnL, v->subsample)
				this_lnL[.,.] = lnL
			} else if (L > 1)
				(base->lnL)[v->SubsampleInds] = lnL
			else
				(v->lnL)[.,.] = lnL
			if (todo) {
				if (v->d_cens)
					if (v->d_uncens) {
						pdlnL_dtheta = &(v->dphi_dE + v->dPhi_dE) 
						pdlnL_dSig =  &(v->dphi_dSig + v->dPhi_dSig)
					} else {
						pdlnL_dtheta = &(v->dPhi_dE)
						pdlnL_dSig =  &(v->dPhi_dSig)
					}
				else {
					pdlnL_dtheta = &(v->dphi_dE)
					pdlnL_dSig = &(v->dphi_dSig)
				}
				if (v->d_trunc) {
					pdlnL_dtheta = &(*pdlnL_dtheta - v->dPhi_dEt)
					pdlnL_dSig   = &(*pdlnL_dSig   - v->dPhi_dSigt)
				}

				pdlnL_dtheta = &(*pdlnL_dtheta * v->QEinvGamma)

				if (L == 1) {
					                   (v->Scores.M.ThetaScores  )[.,.] = *pdlnL_dtheta
					if (REs->NumCuts)  (v->Scores.M.  CutScores  )[.,.] = v->dPhi_dcuts
					if (cols(base->D)) (v->Scores.M.  SigScores.M)[.,.] = *pdlnL_dSig * v->invGammaQSigD
					for (i=m=1; m<=d; m++)
						for (c=1; c<=REs->G[m]; c++)
							(v->Scores.M.GammaScores[i++].M)[.,.] = v->TheseInds[m]? 
									(*pdlnL_dtheta)[v->one2N,m]:*v->theta[(*REs->GammaInds[m])[c]].M + *pdlnL_dSig*v->dOmega_dGamma[m,c].M : v->J_N_1_0
				} else {
					_editmissing(*pdlnL_dtheta, 0)
					_editmissing(v->dPhi_dcuts, 0)
					_editmissing(*pdlnL_dSig, 0)

					pScores = &(v->Scores[L].M[(*REs)[L-1].ThisDraw])
					                   pScores->ThetaScores  = *pdlnL_dtheta
					if (REs->NumCuts)  pScores->CutScores    = v->dPhi_dcuts
					if (cols(base->D)) pScores->TScores[L].M = *pdlnL_dSig
					for (i=m=1; m<=d; m++)
						if (v->TheseInds[m])
							for (c=1; c<=REs->G[m]; c++)
								pScores->GammaScores[i++].M  = (*pdlnL_dtheta)[v->one2N,m] :* v->theta[(*REs->GammaInds[m])[c]].M
						else
							i = i + REs->G[m]

					for (l=1; l<L; l++) {
						RE = &((*REs)[l])
						 // dlnL/dSigparams = dlnL/dE^ * dE^/dE * dE/dT * dT/dOmega * dOmega/dSig * dSig/dSigparams=dlnL/dE * QE * {X*U} * dT_dSig * dOmega_dSig * D. Last 3 terms draw-invariant, so saved for end
						for (e=k=eq1=1; eq1<=RE->NEq; eq1++)
							if (RE->HasRC)
								for (c=1; c<=cols(RE->RCInds[eq1].M)+anyof(RE->REEqs, eq1); c++)
									for (eq2=eq1; eq2<=RE->NEq; eq2++)
										PasteAndAdvance(pScores->TScores[l].M, k, 
											(v->XU[l].M[RE->ThisDraw, e++].M) :* pScores->ThetaScores[v->one2N, RE->Eqs[eq2]])
							else
								PasteAndAdvance(pScores->TScores[l].M, k, (v->XU[l].M[RE->ThisDraw, eq1].M) :* pScores->ThetaScores[v->one2N, RE->Eqs[|eq1 \ .|]])
					}
				}
			}
		}

		for (l=L-1; l; l--) { // If L=1, sets l=0 as needed to terminate do loop. Usually this loop runs once.
			RE = &((*REs)[l])

			// efficient way to sum lnL by group
			_quadrunningsum((*REs)[l+1].lnL, rows((*REs)[l+1].Weights)? (*REs)[l+1].lnL :* (*REs)[l+1].Weights : (*REs)[l+1].lnL, 1)
			t = (*REs)[l+1].lnL[RE->IDRangesGroup]
			if (rows(t) > 1)
				RE->lnLByDraw[RE->one2N, RE->ThisDraw] = t - (0 \ t[|.\rows(t)-1|])
			else
				RE->lnLByDraw[1, RE->ThisDraw] = t

			if (RE->ThisDraw < RE->R)
				RE->ThisDraw = RE->ThisDraw + 1
			else {
				RE->ThisDraw = 1

				if (REs->IntMethod)
					RE->lnLByDraw = RE->lnLByDraw + RE->AdaptiveShift // even if active adaptation done, add adaptive ln(det(C)*normalden(QuadXAdapt)/normalden(QuadX))

				// for each group, make weights proportional to L (not lnL) for the group/obs at next-lower level
				t = RE->lnLlimits :- rowminmax(RE->lnLByDraw) // In summing groups' Ls, shift just enough to prevent underflow in exp(), but if necessary even less to avoid overflow
				lnLmin = t[,1]; lnLmax = t[,2]
				t = lnLmin:*(lnLmin:>0) - lnLmax; shift = t:*(t :< 0) + lnLmax // parallelizes better than rowminmax()
				_editmissing( L_g=exp(RE->lnLByDraw:+shift), 0) // un-log likelihood for each group & draw; lnL=. => L=0
				if (REs->Quadrature)
					L_g = L_g :* RE->QuadW
				RE->lnL = quadrowsum(L_g) // in non-quad case, sum rather than average of likelihoods across draws
				if (todo | (REs->AdaptivePhaseThisEst & REs->IntMethod==1))
					_editmissing(L_g = L_g :/ RE->lnL, 0) // normalize L_g's as weights for obs-level scores or for use in Smith-Naylor adaptation
				if (REs->AdaptivePhaseThisEst & NewIter) {
					for (j=RE->N; j; j--)
						if (RE->ToAdapt[j]) {
							RE->QuadMean[j].M = mean(RE->QuadXAdapt[j].M, t=L_g[j,]')
							C = cholesky(quadcrossdev(RE->QuadXAdapt[j].M, RE->QuadMean[j].M, t, RE->QuadXAdapt[j].M, RE->QuadMean[j].M))
							if (C[1,1] == .) { // diverged? try restarting, but decrement counter to prevent infinite loop
								RE->ToAdapt[j] = RE->ToAdapt[j] - 1
								RE->QuadXAdapt[j].M = RE->QuadX
								RE->AdaptiveShift[j,] = J(1, RE->R, 0)
							} else {
								RE->QuadSD[j].M = diagonal(C)
								if (mreldif(RE->QuadXAdapt[j].M, t=RE->QuadX*C':+RE->QuadMean[j].M) < REs->QuadTol) { // has adaptation converged for this ML search iteration?
									RE->ToAdapt[j] = 0
									continue
								}
								RE->QuadXAdapt[j].M = t
								RE->AdaptiveShift[j,] = quadcolsum(ln(RE->QuadSD[j].M),1) :+ quadrowsum(lnnormalden(RE->QuadXAdapt[j].M))' - RE->lnnormaldenQuadX
							}
							for (r=RE->R; r; r--)
								RE->U[r].M[|RE->IDRanges[j,]', (.\.)|] = J(RE->IDRanges[j,2]-RE->IDRanges[j,1]+1, 1, RE->QuadXAdapt[j].M[r,])
						}
					if (RE->AdaptivePhaseThisIter = any(RE->ToAdapt) * mod(RE->AdaptivePhaseThisIter-1, REs->QuadIter)) { // not converged and haven't hit max number of adaptations?
						BuildTotalEffects(REs, l)
						if (REs->todo)
							BuildXU(subviews, REs, l, L)
					}
				}
			}

			if (l < L-2 & REs->AdaptivePhaseThisEst & NewIter) { // reset adaptive quad points next level down, at some efficiency cost, since the best points at levels 2 and below vary with each higher-level choice of draw
				for (j=(*REs)[l+1].N; j; j--)
					(*REs)[l+1].QuadXAdapt[j].M = (*REs)[l+1].QuadX
				(*REs)[l+1].AdaptiveShift = J((*REs)[l+1].N, (*REs)[l+1].NumREDraws, 0)
				(*REs)[l+1].lnnormaldenQuadX = quadrowsum(lnnormalden((*REs)[l+1].QuadX))'
			}

			if (RE->ThisDraw > 1 | RE->AdaptivePhaseThisIter) { // no (more) carrying? propagate draw changes down the tree
				for (_l=l; _l<L; _l++)
					for (eq=cols(RE->GammaEqs); eq; eq--)
						(*REs)[_l+1].theta[RE->GammaEqs[eq]].M = (*REs)[_l].theta[RE->GammaEqs[eq]].M + (*REs)[_l].TotalEffect[(*REs)[_l].ThisDraw, eq].M
				break
 			}

			// finished the group's (adaptive) draws
			if (todo) { // obs-level score for next level up is avg of scores over this level's draws, weighted by group's L for each draw
				real matrix L_gv, L_gvr, sThetaScores, sCutScores
				struct smatrix colvector sTScores, sGammaScores; sTScores=smatrix(L); sGammaScores=smatrix(sum(REs->G))

				for (v = subviews; v!=NULL; v = v->next) {
					L_gv = L_g[v->id[l].M, RE->one2R]

					L_gvr = L_gv[v->one2N, 1]
						sThetaScores = L_gvr :* v->Scores[l+1].M[1].ThetaScores
					if (REs->NumCuts)
						sCutScores   = L_gvr :* v->Scores[l+1].M[1].CutScores
					for (i=L; i; i--)
						if (cols((*REs)[i].D))
							sTScores[i].M = L_gvr :* v->Scores[l+1].M[1].TScores[i].M
					for (i=cols(v->Scores.M[1].GammaScores); i; i--)
						if (rows(v->Scores[l+1].M[1].GammaScores[i].M))
							sGammaScores[i].M = L_gvr :* v->Scores[l+1].M[1].GammaScores[i].M
					for (r = (*REs)[l+1].NumREDraws; r>1; r--) {
						L_gvr = L_gv[v->one2N, r]
						
							sThetaScores = sThetaScores + L_gvr :* v->Scores[l+1].M[r].ThetaScores
						if (REs->NumCuts)
							sCutScores   = sCutScores   + L_gvr :* v->Scores[l+1].M[r].CutScores
						for (i=L; i; i--)
							if (cols((*REs)[i].D))
								sTScores[i].M = sTScores[i].M + L_gvr :* v->Scores[l+1].M[r].TScores[i].M
						for (i=cols(v->Scores.M[1].GammaScores); i; i--)
							if (rows(v->Scores[l+1].M[r].GammaScores[i].M))
								sGammaScores[i].M = sGammaScores[i].M + L_gvr :* v->Scores[l+1].M[r].GammaScores[i].M
					}
					if (l==1) { // final scores
							v->Scores.M.ThetaScores[v->one2N, .] = rows(v->WeightProduct)? sThetaScores  :* v->WeightProduct : sThetaScores
						if (REs->NumCuts)
							v->Scores.M.CutScores[v->one2N, .]   = rows(v->WeightProduct)? sCutScores    :* v->WeightProduct : sCutScores
						if (cols(base->D))
							v->Scores.M.SigScores[L].M[v->one2N, .]   = rows(v->WeightProduct)? sTScores[L].M*v->invGammaQSigD :* v->WeightProduct : sTScores[L].M*v->invGammaQSigD
						for (i=L-1; i; i--)
							if (cols((*REs)[i].D))
								v->Scores.M.SigScores[i].M[v->one2N, .] = rows(v->WeightProduct)? (sTScores[i].M*(*REs)[i].D):*v->WeightProduct : sTScores[i].M*(*REs)[i].D
						for (i=m=1; m<=d; m++)
							for (c=1; c<=REs->G[m]; c++) {
								if (v->TheseInds[m])
									v->Scores.M.GammaScores[i].M[v->one2N, .]  = rows(v->WeightProduct)? 
										(sGammaScores[i].M + sTScores[L].M * v->dOmega_dGamma[m,c].M):*v->WeightProduct :
										 sGammaScores[i].M + sTScores[L].M * v->dOmega_dGamma[m,c].M
								else
									v->Scores.M.GammaScores[i].M[v->one2N, .] = v->J_N_1_0
								i++
							}
					} else {
							v->Scores[l].M[(*REs)[l-1].ThisDraw].ThetaScores = sThetaScores
						if (REs->NumCuts)
							v->Scores[l].M[(*REs)[l-1].ThisDraw].CutScores   = sCutScores
						for (i=L; i; i--)
							if (cols((*REs)[i].D))
								v->Scores[l].M[(*REs)[l-1].ThisDraw].TScores[i].M = sTScores[i].M
						for (i=cols(v->Scores.M[1].GammaScores); i; i--)
							v->Scores[l].M[(*REs)[l-1].ThisDraw].GammaScores[i].M = sGammaScores[i].M
					}
				}
			}
			RE->lnL = ln(RE->lnL) - shift
			if (!REs->Quadrature)
				RE->lnL = RE->lnL :- RE->lnNumREDraws
		}
	} while (l) // exit when adding one more draw causes carrying all the way accross the draw counters, back to 1, 1, 1...

	if (L > 1) {
		t = quadsum(rows(REs->Weights)? REs->Weights:*REs->lnL : REs->lnL, 1)
		if (REs->AdaptivePhaseThisEst & NewIter) {
			if (REs->AdaptivePhaseThisEst = mreldif(REs->LastlnLThisIter, REs->LastlnLLastIter) >= 1e-6)
				REs->LastlnLLastIter = REs->LastlnLThisIter
			else
				printf("\nAdaptive quadrature points fixed.\n")
			REs->LastIter = Iter
		}
		if (t < .) REs->LastlnLThisIter = t
		st_numscalar(st_local("lnfi"), t)
	}
}

void cmpSaveSomeResults() {
	external struct RE colvector _REs; pointer (struct RE scalar) scalar RE; external real scalar _L; real scalar l, j, k_aux_nongamma; real matrix means, ses; string matrix colstripe, _colstripe
	if (_L == 1)
		st_matrix("e(Sigma)", _REs.Sig)
	else {
		for (l=_L; l; l--) {
			RE = &(_REs[l])
			st_matrix("e(Sigma"+(l<_L?strofreal(l):"")+")", RE->Sig)
			if (l<_L & _REs.Quadrature & _REs.IntMethod) {
				ses = means = J(RE->N, RE->d, 0)
				for (j=RE->N; j; j--) {
					means[j,] = RE->QuadMean[j].M
					ses  [j,] = RE->QuadSD[j].M'
				}
				st_matrix("e(REmeans"+strofreal(l)+")", means * RE->T)
				st_matrix("e(RESEs"  +strofreal(l)+")", ses   * RE->T)
				colstripe = tokens(st_global("cmp_rceq"+strofreal(l)))', tokens(st_global("cmp_rc"+strofreal(l)))'
				st_matrixcolstripe("e(REmeans"+strofreal(l)+")", colstripe)
				st_matrixcolstripe("e(RESEs"  +strofreal(l)+")", colstripe)
			}
		}
		if (rows(_REs.WeightProduct))
			st_numscalar("e(N)", quadsum(_REs.WeightProduct))
	}
	if (_REs.HasGamma) {
		real scalar eq, d, k, NumCoefs
		real matrix Beta, BetaInd, GammaInd, REInd, dBeta_dB, dBeta_dGamma, dbr_db, dOmega_dSig, V, br, sig, rho, Rho, invGamma, Omega, NumEff
		real rowvector eb, p
		real colvector keep
		string rowvector eqnames
		pragma unset p
		
		colstripe = J(0, 1, ""); _colstripe = J(0, 2, "")
		V = st_matrix("e(V)")
		BetaInd = st_matrix("cmpBetaInd") ; GammaInd = st_matrix("cmpGammaInd")
		invGamma = _REs[_L].invGamma'
		Beta = (invGamma * st_matrix(st_local("Beta")))'
		d = cols(Beta); k = rows(Beta)
		br = vec(Beta)
		eb = st_matrix("e(b)")
		k_aux_nongamma = st_numscalar("e(k_aux)")-st_numscalar("e(k_gamma)")
		dBeta_dB = invGamma # I(k); dBeta_dGamma = invGamma # Beta

		dbr_db = J(rows(dBeta_dB), 0, 0)
		for (eq=d; eq; eq--)
			dbr_db = dBeta_dGamma[, GammaInd[OneInds(GammaInd[,1]:==eq),2] :+ (eq-1)*d         ], dbr_db        
		for (eq=d; eq; eq--)
			dbr_db = dBeta_dB    [, BetaInd [OneInds(BetaInd [,1]:==eq),2] :+ (eq-1)*rows(Beta)], dbr_db        

		keep = OneInds(rowsum(dbr_db:!=0):>0)
		br = br[keep]'
		dbr_db = dbr_db[keep,]
		eqnames = tokens(st_global("cmp_eq"))
		for (eq=d; eq; eq--)
			colstripe = J(rows(Beta), 1, eqnames[eq]) \ colstripe
		colstripe = (colstripe, J(d, 1, tokens(st_local("xvarsall"))'))[keep,]

		if (_REs.NumCuts) {
			br = br, eb[|cols(eb)-k_aux_nongamma+1 \ cols(eb)-k_aux_nongamma+_REs.NumCuts|]
			colstripe = colstripe \ st_matrixcolstripe("e(b)")[|cols(eb)-k_aux_nongamma+1, . \ cols(eb)-k_aux_nongamma+_REs.NumCuts,.|]
			dbr_db = blockdiag(dbr_db, I(_REs.NumCuts))
		}		

		NumEff = J(0, d, 0)
		for (l=1; l<=_L; l++) {
			RE = &(_REs[l])
			REInd = st_matrix("cmpREInd"+strofreal(l))
			k = colmax(REInd[,2])
			dOmega_dSig = (invGamma # I(k))[, (REInd[,1]:-1)*k + REInd[,2]]'
			st_matrix("e(Omega"+(l<_L?strofreal(l):"")+")", Omega = quadcross(dOmega_dSig, RE->Sig) * dOmega_dSig)
			Rho = corr(Omega); rho = rows(Rho)>1? vech(Rho[|2,1 \ .,cols(Rho)-1|])' : J(1,0,0)
			sig = sqrt(diagonal(Omega))'
			dOmega_dSig = edittozero(pinv(editmissing(dSigdsigrhos(&_REs, RE, sig, Omega, rho, Rho),0)),10) * QE2QSig(dOmega_dSig) * RE->D
			keep = OneInds((((sig:!=.) :* (sig:>0)), (rho:!=.)))'
			br = br, (_REs.SigXform? ln(sig), atanh(rho) : sig, rho)[keep]
			_colstripe = _colstripe \ ((tokens(st_local("sigparams"+strofreal(l)))' \ tokens(st_local("rhoparams"+strofreal(l)))')[keep] , J(rows(keep), 1, "_cons"))
			dbr_db = blockdiag(dbr_db, dOmega_dSig[keep,])
			keep = colshape(rowsum(dOmega_dSig[|.,.\k*d,.|]:!=0):>0, k) // get retained sig params by eq
			NumEff = NumEff \ rowsum(keep)'
			for (j=d; j; j--)
				st_global("e(EffNames_reducedform"+strofreal(l)+"_"+strofreal(j)+")", invtokens(tokens(st_local("cmp_rcu"+strofreal(l)))[OneInds(keep[j,])]))
			st_matrix("e(fixed_sigs_reducedform"+strofreal(l)+")", J(1, d, .)) 
			st_matrix("e(fixed_rhos_reducedform"+strofreal(l)+")", J(d, d, .)) 
		}
		st_matrix("e(NumEff_reducedform)", NumEff)
		st_numscalar("e(k_sigrho_reducedform)", rows(_colstripe))
		colstripe = colstripe \ _colstripe
		
		NumCoefs = rows(BetaInd) - 1
		BetaInd  = runningsum(colsum( BetaInd[|2,1\.,1|]#J(1,d,1) :== (1..d))')
		GammaInd = runningsum(colsum(GammaInd[|2,1\.,1|]#J(1,d,1) :== (1..d))') :+ NumCoefs
		BetaInd   = (0        \  BetaInd[|.\d-1|]):+1,  BetaInd
		GammaInd  = (NumCoefs \ GammaInd[|.\d-1|]):+1, GammaInd
		for (eq=1; eq<=d; eq++) {
			if (GammaInd[eq,2] >= GammaInd[eq,1]) p = p, GammaInd[eq,1]..GammaInd[eq,2]
			if ( BetaInd[eq,2] >=  BetaInd[eq,1]) p = p,  BetaInd[eq,1].. BetaInd[eq,2]
		}
		if (cols(p)<cols(eb))
			p = p, cols(p)+1 .. cols(eb)

		st_matrix("e(br)", br)
		st_matrix("e(Vr)", dbr_db * V * dbr_db')
		st_matrix("e(_p)", p)
		st_matrixcolstripe("e(br)", colstripe)
		st_matrixcolstripe("e(Vr)", colstripe)
		st_matrixrowstripe("e(Vr)", colstripe)
	}
}

/*void cmpParseCorrOption (string scalar option) {
	transmorphic t
	string scalar thisToken
	string rowvector eqs
	real matrix FixedRhos
	
	t = tokeninitstata()
	tokenset(t, option)
	eqs = tokens(st_global("cmp_eq"))
	FixedRhos = J(cols(eqs), cols(eqs), .)
	
	while ((thisToken = tokenget(t)) != "") {
		
	}
}

function cmp_lf1(transmorphic M, real scalar todo, real rowvector b, real colvector lnf, real matrix S, real matrix H) {
	real scalar i, d, l, GammaIndRow, cut, trunc, lnsigAccross lnsigWithin atanhrhoAccross atanhrhoWithin
	real matrix Gamma, cmpGammaInd, cuts
	real colvector truneqs, Lt, Ut, ind

	REs = _REs // move to userinfo() once way developed to call initialzation code in cmp_lnL() before moptimize()
	external struct RE colvector _REs; pointer (struct RE colvector) scalar REs

	d           = moptimize_init_userinfo(M, 1)
	cmpGammaInd = moptimize_init_userinfo(M, 2)
	vNumCuts    = moptimize_init_userinfo(M, 3)
	trunc       = moptimize_init_userinfo(M, 4)
	trunceqs    = moptimize_init_userinfo(M, 5)

	for (i=d; i; i--)
		REs->theta[i].M = moptimize_util_xb(M, b, 1)

	if (REs->HasGamma) {
		for (i=1; i<=d; i++)
			_editmissing(REs->theta[i].M, 0) // only time missing values would appear and be used is when multiplied by invGamma with 0's in corresponding entries
		Gamma = J(d, d, 0)
		GammaIndRow = 1
		for (eq1=1; eq1<=d; eq1++)
			while (cmpGammaInd[GammaIndRow,1] == eq1)
				Gamma[cmpGammaInd[GammaIndRow++,2], eq1] = b[|moptimize_util_eq_indices(M, ++i)|]
	}

	mat cuts = J(colmax(vNumCuts)+2, d, .)
	for (eq=1; eq<=d; eq++)
		if (vNumCuts[eq]) {
			cuts[1,eq] = minfloat()

			if (trunceqs[eq]) {
				_st_view(Lt , ., st_global("cmp_Lt"+strofreal(eq))) // these should be stored in REs or userinfo
				_st_view(Ut , ., st_global("cmp_Ut"+strofreal(eq)))
				_st_view(ind, .,         "_cmp_ind"+strofreal(eq) )
			}
			for (cut=1; cut<=vNumCuts[eq]; cut++) {
				cuts[cut+1,eq] = b[|moptimize_util_eq_indices(M, ++i)|]
				if (trunceqs[eq])
					if (any(_cmp_ind :& ((Lt:<. :& cuts[cut+1,eq]:<Lt) :| cuts[cut+1,eq]:>Ut))) {
						lnf = .
						return
					}
			}
		}

	forvalues l=1/$parse_L {
		tempname sig`l' atanhrho`l'
		local sigs `sigs' `sig`l''
		local atanhrhos `atanhrhos' `atanhrho`l''

		if "${cmp_cov`l'}" == "exchangeable" {
			mleval `lnsigAccross' = `b', eq(`++i') scalar
			scalar `lnsigWithin' = `lnsigAccross'
		}
		forvalues eq=1/d {
			if "${cmp_cov`l'_`eq'}"=="exchangeable" {
				if "${cmp_cov`l'}" != "exchangeable" {
					mleval `lnsigWithin' = `b', eq(`++i') scalar
				}
			}
			forvalues c=1/`=cmp_NumEff[`l', `eq']' {
				if  cmp_fixed_sigs`l'[1,`eq'] == . {
					if inlist("${cmp_cov`l'_`eq'}", "independent", "unstructured") & "${cmp_cov`l'}" != "exchangeable" {
						 mleval `lnsigWithin' = `b', eq(`++i') scalar
					}
				  if $cmpSigXform==0 & `lnsigWithin'==0 {
						replace `lnf' = .
						exit
					}
					mat `sig`l'' = nullmat(`sig`l''), `=cond($cmpSigXform, exp(`lnsigWithin'), `lnsigWithin')'
				}
				else mat `sig`l'' = nullmat(`sig`l''), cmp_fixed_sigs`l'[1,`eq']
			}
		}

		if "${cmp_cov`l'}" == "exchangeable" & d > 1 {
			mleval `atanhrhoAccross' = `b', eq(`++i') scalar
		}
		forvalues eq1=1/d {
			if "${cmp_cov`l'_`eq1'}"=="independent" {
				scalar `atanhrhoWithin' = 0
			}
			else if "${cmp_cov`l'_`eq1'}"=="exchangeable" & cmp_NumEff[`l', `eq1'] > 1 {
				mleval `atanhrhoWithin' = `b', eq(`++i') scalar
			}
			forvalues c1=1/`=cmp_NumEff[`l', `eq1']' {
				forvalues c2=`=`c1'+1'/`=cmp_NumEff[`l', `eq1']' {
					if "${cmp_cov`l'_`eq1'}" == "unstructured" {
						mleval `atanhrhoWithin' = `b', eq(`++i') scalar
					}
					mat `atanhrho`l'' = nullmat(`atanhrho`l''), `atanhrhoWithin'
				}
				forvalues eq2=`=`eq1'+1'/d {
					forvalues c2=1/`=cmp_NumEff[`l', `eq2']' {
						if cmp_fixed_rhos`l'[`eq2',`eq1'] == . {
							if "${cmp_cov`l'}" == "unstructured" {
								 mleval `atanhrhoAccross' = `b', eq(`++i') scalar
							}
							mat `atanhrho`l'' = nullmat(`atanhrho`l''), `atanhrhoAccross'
						}
						else mat `atanhrho`l'' = nullmat(`atanhrho`l''), cmp_fixed_rhos`l'[`eq2',`eq1']
					}
				}
			}
		}
	}

	if $parse_L > 1 {
		tempname lnfi
		scalar `lnfi' = . // create it in case cmp_lnL() doesn't, when it returns "."
		mata cmp_lnL(`todo', "", "`*'")
		qui replace `lnf' = `lnfi'/$cmpN
	}
	else mata cmp_lnL(`todo', "`lnf'", "`*'")
}
*/
mata mlib create lcmp, dir(PLUS) replace
mata mlib add lcmp *(), dir(PLUS)
mata mlib index
end
