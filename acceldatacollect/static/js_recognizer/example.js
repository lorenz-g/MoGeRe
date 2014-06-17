


/**
 * A demonstration of using re-estimation and the forward algorithm with a Hidden Markov Model.
*/

var alphabetSize = 20,
    numStates = 20,
    isFirstConditioning = true,
    model;
var sp = [
    []
],
    tp = [
        []
    ],
    ep = [
        []
    ];
var p = ProbabilityAPI.HiddenMarkovModel;
var outputDiv = document.getElementById("output");
var model = p.getModel();

//random distribution of initial values
//pass one: create random variables at each index
var stp, sep;
var stpArr = [],
    sepArr = [];
for (var i = 0; i < numStates; i++) {
    sp[i] = Math.random();
    tp[i] = [];
    ep[i] = [];
    stp = 0;
    sep = 0;
    //one loop for state to state transition
    for (var j = 0; j < numStates; j++) {
        tp[i].push(Math.random());
        stp += tp[i][j];
    }
    //...and another for observation dependent on state transition
    for (var j = 0; j < alphabetSize; j++) {
        ep[i].push(Math.random());
        sep += ep[i][j];
    }
    stpArr.push(stp);
    sepArr.push(sep);
}

//pass two:normalize random variables so a row sums to 1
for (var i = 0; i < numStates; i++) {
    for (var j = 0; j < numStates; j++) {
        tp[i][j] /= stpArr[i];
    }
    for (var j = 0; j < alphabetSize; j++) {
        ep[i][j] = 1 / alphabetSize; //keep the emissions uniform
    }
}

/**d= A dummy data array. Play around with the individual indices, and try passing the forward algorithm various numeric arrays after re-estimation to see how it scores them.
*/
var d = [0, 0, 1, 1, 0, 3, 2, 0, 1];
var n1 = logScore(p.forward(d, sp, tp, ep)[1]);
model = p.reestimation(d, sp, tp, ep);
//evens out probability distribution so there are no rows with absolute 0 probability, which causes problems
model[0] = p.redistProbability(model[0]);
model[1] = p.redistProbability(model[1]);
model[2] = p.redistProbability(model[2]);
var n2 = logScore(p.forward(d, model[0], model[1], model[2])[1]);

var output = "<p>Normalized closeness of data average to model before re-estimation: " + n1 + " ...and after: " + n2 + "</p>";
outputDiv.innerHTML = output;

//used to make the forward algorithm output easier to read
function logScore(v) {
    return 100 + (Math.log(v) / Math.log(1.5));
}


Array.prototype.sum = function() {
for (var i = 0, L = this.length, sum = 0; i < L; sum += this[i++]);
return sum;
}

var myArray=[1,2,3,4,5];
tt = myArray.sum();
ee = tp[1].sum();


