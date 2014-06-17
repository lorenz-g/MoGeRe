var ProbabilityAPI = ProbabilityAPI || {};

/**
 * @class
 * General Idea of HMM Data Structure: the underlying states are dependent only on the previous state.
 * The observation produced at time t is dependent only on the underlying state at time t. 
 * 
 * Data structure specification:
 * startStateProb = the state transition probability distribution at time t=0 of an Observation sequence.
 * stateTransProb = state transition probability distribution.
 * obsSeq = observation symbol probability distribution.
 * stateTransProb.length = number of states in the model.
 * obsSeq.length = number of distinct observation symbols per state. i.e. discrete alphabet size.
 * -Chris Natale, August 2013
 */
ProbabilityAPI.HiddenMarkovModel = (function(win, doc){
	"use strict";
	var startProbabilities = [];
	var transitionProbabilities = [[]];
	var observationProbabilities = [[]];
	var t=0; var currentState=0; //t=time, currentState is used to show hidden state during observation generation routine
	
	function init(){
	}
	
	/**
	 * Re-estimation algorithm, based on Baum-Welch formula
	 * @param {array} obsSeq - The observation sequence.
	 * @param {array} startStateProb - Initial state probability distribution.
	 * @param {2d array} stateTransProb - The underlying state transition probability matrix.
	 * @param {2d array} stateToObsProb - The state to observation probability matrix.
	 */
	function reestimation(obsSeq, startStateProb, stateTransProb, stateToObsProb){
		var V=[], E=[], fwd=[], bkw=[], pi1= [], a1=[[]], b1=[[]];
		var rInitialStates, rStateTransitions, rObsProbs, numerator, denominator;
		var obsl = obsSeq.length, stpl = stateTransProb.length, stol = stateToObsProb[0].length;

		//get our forward and backward variables, stored in a 2d matrix TxN
		fwd= forward(obsSeq, startStateProb, stateTransProb, stateToObsProb,0)[0];
		bkw= backward(obsSeq, startStateProb, stateTransProb, stateToObsProb,0)[0];
		var pfwd=forward(obsSeq, startStateProb, stateTransProb, stateToObsProb,0)[1];
		var pbkw=backward(obsSeq, startStateProb, stateTransProb, stateToObsProb,0)[1];

		//re-estimation of initial state probabilities
		for (var i=0; i<stateTransProb.length; i++){	
			pi1[i] = gamma(i, 0, obsSeq, fwd, bkw, stpl);
		}
		
		//re-restimation of state transition probabilities
		for (i=0; i< stpl; i++){
			a1[i] = new Array();
			for (var j=0; j< stpl; j++){
				numerator=0;
				denominator=0;			
				for(var t=0; t< obsSeq.length; t++){
					numerator += p(t, i, j, obsSeq, fwd, bkw, stateTransProb, stateToObsProb);
					denominator += gamma(i, t, obsSeq, fwd, bkw, stpl);
				}
				a1[i][j] = div(numerator, denominator);
			}
		}
		
		var g;
		//re-estimation of emission probabilities
		for (i=0; i< stpl; i++){
			b1[i] = new Array();
			for (var k=0; k< stol; k++){
				numerator=0;
				denominator=0;
				
				for(t=0; t< obsl; t++){
					g= gamma(i, t, obsSeq, fwd, bkw, stpl);	
					numerator += g * (k == obsSeq[t] ? 1: 0);
					denominator += g;
				}
				b1[i][k] = div(numerator, denominator);
			}
		}
		startStateProb = pi1;
		stateTransProb= a1;
		stateToObsProb= b1;

		return([startStateProb, stateTransProb, stateToObsProb]);
	}
		
	/** Calculation of probability P(X_t = s_i, X_t+1 = s_j | O, m). Used in re-estimation.
	      @param {number} t - The current time step in observation sequence.
	      @param {number} i - State i index.
	      @param {number} j - State j index.
	      @param {array} obsSeq - The observation sequence.
	      @param {array} fwd - The forward algorithm results  for obsSeq.
	      @param {array} bwd - the backward algorithm results for obsSeq.
	*/	
	function p(t, i, j, obsSeq, fwd, bkw, stateTransProb, stateToObsProb){
		var num;
		if(t== obsSeq.length -1){
			num = fwd[t][i] * stateTransProb[i][j];
		}
		else{
			num = fwd[t][i] * stateTransProb[i][j] * stateToObsProb[j][obsSeq[t+1]] * bkw[t+1][j];
		}
		
		var denom = 0;
		
		for (var k=0; k< stateTransProb.length; k++){
			denom += (fwd[t][k] * bkw[t][k]);
		}
		
		if(isNaN(num) || isNaN(denom)){
			throw new Error('NaN detected in p()');
		}
		return div(num, denom);
	}
	
	/** Returns the probability of being in state i at time t, given our model and observation sequence.
	      @param {number} t - The current time step in observation sequence.
	      @param {number} i - State i index.
	      @param {number} j - State j index.
	      @param {array} obsSeq - The observation sequence.
	      @param {array} fwd - The forward algorithm results  for obsSeq.
	      @param {array} bwd - The backward algorithm results for obsSeq.
	      @param {number} N - The number of underlying states.
	*/		
	function gamma(i, t, obsSeq, fwd, bkw, N){
		var numerator = fwd[t][i] * bkw[t][i];
		var denominator=0;
		for(var j=0; j< N; j++){
			denominator += fwd[t][j] * bkw[t][j];
		}
		
		if(isNaN(numerator) || isNaN(denominator)){
			throw new Error('NaN detected in p()');
		}
		
		return div(numerator, denominator);
	}

	/**
	 * Computes the probability for ending up in a state at time t given an entire observation sequence of length t.
	 * @param {array} obsSeq - The observation sequence.
	 * @param {array} startStateProb - Initial state probability distribution.
	 * @param {2d array} stateTransProb - The underlying state transition probability matrix.
	 * @param {2d array} stateToObsProb - The state to observation probability matrix.
	 * @param {number} endSt - the ending state (optional).
	 */
	function forward(obsSeq, startStateProb, stateTransProb, stateToObsProb, endSt){		
		var prevFSum, fPrev, pFwd, summ, i, fCurr=[], fwd=[];

		for(var t=0; t<obsSeq.length; t++){
			fCurr= [];
			for(var j=0; j<stateTransProb.length; j++){
				if(t==0){
					prevFSum= startStateProb[j];
				}
				else{
					summ=0;
					for(i=0; i< stateTransProb.length; i++){
						summ+= (fPrev[i] * stateTransProb[i][j]);
					}	
					prevFSum= summ; 				
				}
				fCurr[j]= stateToObsProb[j][obsSeq[t]] * prevFSum;
			}
			fwd.push(fCurr);
			fPrev = fCurr;
		}

		summ=0;
		
		if(typeof endSt != 'undefined'){
			for(j=0; j<stateTransProb.length; j++){
				/*The combined probability of all state and observation transitions across 
				 * the entire observation time period is multiplied by the final state transition and summed over all states.*/
				summ += (fCurr[j]*stateTransProb[j][endSt]);
			}
			//Hence, pFwd is sum of the joint probability of all states in the HMM, dependent on the observation set.
			pFwd = summ;
		}
		else{
			for(j=0; j<stateTransProb.length; j++){
				summ += (fCurr[j]); //Assume that if the end state isn't specified, any end state will do.
			}
			pFwd = summ;
		}
		
		return [fwd, pFwd];
	}

	/**
	 * Provides probability of observing all observation in a given sequence after a particular time t.
	 * @param {array} obsSeq - The observation sequence.
	 * @param {array} startStateProb - Initial state probability distribution.
	 * @param {2d array} stateTransProb - The underlying state transition probability matrix.
	 * @param {2d array} stateToObsProb - The state to observation probability matrix.
	 * @param {number} endSt - the ending state (optional).
	 */	
	function backward(obsSeq, startStateProb, stateTransProb, stateToObsProb, endSt){
		var i, bCurr, pBkw, summ, bkw=[], bPrev=[];
		var revObsSeq = obsSeq.slice(0);
		var stpl = stateTransProb.length, obsl = obsSeq.length;
		revObsSeq.reverse();
		
		for(var t=0; t< obsl; t++){
			bCurr = [];
			for(var j=0; j<stpl; j++){
				if(t==0){
					if(typeof endSt != 'undefined')
						bCurr[j]=stateTransProb[j][endSt];
					else	
						bCurr[j]=1; //If the ending underlying state isn't specified, assume it can be any state and use probability of 1.
				}
				else{
					summ=0;
					for(i=0; i< stpl; i++){
						summ+= (stateTransProb[j][i] * stateToObsProb[i][revObsSeq[t-1]] * bPrev[i]);
					}	
					bCurr[j] = summ;
				}
			}
			bkw.unshift(bCurr)
			bPrev = bCurr;	
		}
		
		summ=0;
		for(j=0; j<stpl; j++){
			summ += startStateProb[j] * stateToObsProb[j][obsSeq[0]] * bCurr[j];
		}
		pBkw = summ;
		return [bkw, pBkw];
	}
	
	/**
	 * Calculates probabilities of all underlying states, given a sequence of observations, at any time t in the observation sequence.
	 * @param {array} obsSeq - The observation sequence.
	 * @param {array} startStateProb - Initial state probability distribution.
	 * @param {2d array} stateTransProb - The underlying state transition probability matrix.
	 * @param {2d array} stateToObsProb - The state to observation probability matrix.
	 * @param {number} endSt - the ending state.
	 */		
	function forwardBackward(obsSeq, startStateProb, stateTransProb, stateToObsProb, endSt){
		var fwd, pFwd, bkw, pBkw, posterior=[];
		var stpl = stateTransProb.length, obsl = obsSeq.length;
		
		//forward part of algorithm
		var fwdRes = forward(obsSeq, startStateProb, stateTransProb, stateToObsProb, endSt);
		fwd=fwdRes[0];
		pFwd = fwdRes[1];
		
		//backward part of algorithm
		var bkwRes = backward(obsSeq, startStateProb, stateTransProb, stateToObsProb, endSt);
		bkw = bkwRes[0];
		pBkw = bkwRes[1];
		
		var mult;
		var summ;
		for(var j=0; j<stpl; j++){
			summ=0;
			mult=1;
			for(var i=0; i< obsl; i++){
					mult *= (fwd[i][j]*bkw[i][j])/pFwd; //trying to comment out pFwd to see if this is the val i really want
			}
			posterior[j] = mult;
		}
		
		return [fwd, bkw, posterior];
	}
	
	/**
	 * Finds the most likely sequence of hidden states for a given observation sequence.
	 * NOTE: This method hasn't been thoroughly tested yet. Your mileage may vary.
	 * @param {array} obsSeq - The observation sequence.
	 * @param {array} startStateProb - Initial state probability distribution.
	 * @param {2d array} stateTransProb - The underlying state transition probability matrix.
	 * @param {2d array} stateToObsProb - The state to observation probability matrix.
	 * @param {number} endSt - the ending state.
	 */		
	function viterbi(obsSeq, startStateProb, stateTransProb, stateToObsProb){
		var V =[[]], path=[], newpath=[], T1 =[], T2= [];// 2 dimensional arrays of size [state.length][time.length]
		var total=0, argmax, valmax=0, prob=1, vPath, vProb=1, state, csarr, maxVal;
		var stpl = stateTransProb.length, obsl = obsSeq.length;

		//Calculate best estimate of states for t=0
		for(var y=0; y < stpl; y++){
			V[0][y] = startStateProb[y] * stateToObsProb[y][obsSeq[0]]
			path[y] = [y];
		}
		
		//Calculate best estimate of states for t>0
		for(var t=1; t < obsl; t++){
			V.push([]);
			newpath = [];
			for(y=0; y < stpl; y++){
				csarr = new Array();
				for(var y0=0; y0 < stpl; y0++){
					csarr.push([V[t-1][y0] * stateTransProb[y0][y] * stateToObsProb[y][obsSeq[t]], y0]);
				}	
				maxVal = mergeSort(csarr);
				state=maxVal[0][1];
				V[t][y] = maxVal[0][0];
				newpath[y] = path[state] + [y];
			}
			//Don't need to remember old paths
			path = newpath;
		}

		csarr = new Array();
		for(y=0; y < stpl; y++){
			csarr.push([V[obsl-1][y], y]);
		}	
		//Sort the results to get the max combined probability value at each observation time increment  
		var results = mergeSort(csarr);
		prob= results[0][0];
		state = results[0][1];

		return([prob, path[state]]);
	}
	
	/**
	 * Takes an array, and if any indices have 0 value, take an amt from largest index value and redistribute.
	 * Basically a way of keeping any transition index from having a 0 probability of occurring (and instead just having a tiny probability).
	 * @param {array} arr - An array of decimal numbers 0 <= d <= 1 which sum to 1.
	 */		
	function redistProbability(arr){
		//First pass to get the maximum value
		getIndices(arr);
		return arr;	
		
		function getIndices(arr){		
			//Handles multidimensional arrays as well, on assumption that each sub-index at a certain depth is an array so long as the first is.
			if(typeof arr[0] ==='object'){
				if(arr[0]){
					if(arr[0] instanceof Array)
						for(var j=0; j< arr.length; j++){
							getIndices(arr[j]);}
				}	
			}	
			var max= Math.max.apply(Math, arr);
			var indicesToIncrease=[];
			var maxValIndex;
			var distributionVal;				
			
			for(var i=0; i<arr.length; i++){
				if(arr[i]===max){
					maxValIndex=i;
				}
				if(arr[i] === 0){
					indicesToIncrease.push(i);
				}	
			}	
			
			//Do a second pass of 0 value indices for the actual smoothing
			//Take 10% of max value, and distribute evenly among all 0 vals
			distributionVal = arr[maxValIndex] * .01;
			for(var i=0; i<indicesToIncrease.length; i++){
				arr[indicesToIncrease[i]] = distributionVal;
				arr[maxValIndex] -= distributionVal;
			}				
		}
	}	
	
	//Generates an observation, given the current underlying state and our model, based on HMM rules.

	function generateObservation(currentState, startStateProb, stateTransProb, stateToObsProb){
		var p, e;
		//First, select a new state
		if(typeof currentState === 'undefined'){
			//Assuming this is probability at t=0, so use start probability
			p = weightedRandom(startStateProb);
		}
		else{
			p = weightedRandom(stateTransProb[currentState]);
		}
		currentState = p;
		
		//Next, use the state to select a observation symbol
		e = weightedRandom(stateToObsProb[p]);
		return e;
		t++;
	}

	/**
	 * Takes an array of decimal numbers 0 <= d <= 1 which sum to 1, and randomly returns the index one one based on decimal 'weight',
	 * i.e. indices closer to 1 have a greater chance of being selected.
	 * @param {array} weights - An array of decimal numbers 0 <= d <= 1 which sum to 1.
	 */	
	function weightedRandom(weights){
		var r = Math.random();
		
		for(var i=0; i<weights.length; i++){
			if(r < weights[i])
				return i;
			r -= weights[i];	
		}
	}
	
	/**
	 * Version of merge sort implementation which sorts a two dimensional array based on values of arr[i][0].
	 * Based on implementation by Nicholas C. Zakas, http://www.nczonline.net/
	 * NOTE: Should probably be moved to a utility module.
	 * @param {array} weights - An array of decimal numbers 0 <= d <= 1 which sum to 1.
	 */	
	function mergeSort(items){
	    // Terminal condition - don't need to do anything for arrays with 0 or 1 items
	    if (items.length < 2) {
	        return items;
	    }
	
	    var work = [], i, len;
	        
	    for (i=0, len=items.length; i < len; i++){
	        work.push([items[i]]);
	    }
	    work.push([]);  //In case of odd number of items
	
	    for (var lim=len; lim > 1; lim = Math.floor((lim+1)/2)){
	        for (var j=0,k=0; k < lim; j++, k+=2){
	            work[j] = merge(work[k], work[k+1]);
	        }
	        work[j] = [];  //In case of odd number of items
	    }
	
	    return work[0];
	}	
	
	function merge(left, right){
	    var result = [];
	    
	    while (left.length > 0 && right.length > 0){
	        if (left[0][0] > right[0][0]){
	            result.push(left.shift());
	        } else {
	            result.push(right.shift());
	        }
	    }	
	    result = result.concat(left).concat(right);
	    
	    //Make sure remaining arrays are empty
	    left.splice(0, left.length);
	    right.splice(0, right.length);
	    return result;
	}		
	
	//Here so we can do 0/0 and return imaginary 0
	function div(n, d){
		if(n == 0)
			return 0;
		else
			return n/d;	
	}	
	
	///////Accessor methods///////
	/**
	 * Accessor method for the markov model
	 * @returns An array in which [0]= the start probabilities, [1]=underlying state
	 * transition probabilities, and [2]=the observation probabilities.
	 */
	function getModel(){
		var m = [startProbabilities, transitionProbabilities, observationProbabilities];
		return m;
	}
	
    /**
	 * Accessor method for the current state
	 * @returns {number} currentState - The current HMM state, set by the generateObservation method.
	*/
	function getCurrentState(){
		return currentState;
	}		
	
	return {
		init: init,
		getModel: getModel,
		forward: forward,
		backward: backward,		
		forwardBackward: forwardBackward,
		reestimation: reestimation,		
		redistProbability: redistProbability,
		getCurrentState:getCurrentState,
		generateObservation:generateObservation
	}
	
}(window, document));

document.addEventListener("DOMContentLoaded", ProbabilityAPI.HiddenMarkovModel.init, false);
