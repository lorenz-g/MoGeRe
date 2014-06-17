var ProbabilityAPI = ProbabilityAPI || {};

/*  Implementation of discrete visible Markov Model. 
  Allows calculation of a chain of probabilities, with each item in the chain dependent only on the last
	state in chain.
	
	*note that '|' = 'dependent upon'
	
	Formally, if observation sequence O = {S1, S2, S3...},
	corresponding to discrete time measurement of time t= 1,2,...8,
	and matrix A of state transition probabilities is:
	
	A = {a[ij]} = [
					[.4, .3, .3],
					[.2, .6, .2],
					[.1, .1, .8]
				  ]	

	, 
	
	we can determine the probability of O. This probability can be expressed as:
	P(O|Model) = P[S3, S3, S3, S1, S1, S3, S2, S3|Model]
			   = P[S3] * P[S3|S3] * P[S3|S3] * P[S1|S3] * P[S1|S1] * P[S3|S1] * P[S2|S3] * P[S3|S2]
			   = InitialState * a[3][3] * a[3][3] * a[3][1] * a[1][1] * a[1][3] *a[3][2] * a[2][3]
			   = 1 * (.8)*(.8)*(.1)*(.4)*(.3)*(.1)*(.2)
			   = 1.536 * 10^-4
			   
	
	-Using this model, we can also find out the probability of a model staying in a state for x discrete time, given initial state i.
	This can be evaluated by making O an observation list with the same state, and it's final entity being any value != to prior state
			   

	Chris Natale
	8/1/2013
	Source: Rabiner, Lawrence. 'A Tutorial on Hidden Markov Models and Selected Applications in Speech Recognition'
			'Proceedings of the IEEE', Vol. 77, No. 2. Feb, 1989
*/
ProbabilityAPI.ObservableMarkovModel = (function(win, doc){
	"use strict";
	
	function init(){

	}
	
	//the probability of state chain s occurring
	function getProbability(sc, prob){
		// sc= the state chain
		//prob = probability array 
		var p=1; //set to 1 bc first item in chain has 100% probability of occurring
		for(var i=1; i<sc.length; i++){
			p *= prob[sc[i-1]][sc[i]];
		}
		return p;
	}
	
	//given discrete state, for how many transitions can we expect the model to stay in the state?
	function expectedDurationOfState(state, prob){
		return 1/(1-prob[state][state]);
	}
	
	return {
		init:init,
		getProbability:getProbability,
		expectedDurationOfState:expectedDurationOfState
	}
	
}(window, document));

document.addEventListener("DOMContentLoaded", ProbabilityAPI.ObservableMarkovModel.init, false);
