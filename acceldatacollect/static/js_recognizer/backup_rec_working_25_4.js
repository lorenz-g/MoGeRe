

var HMM = ProbabilityAPI.HiddenMarkovModel;

/**
 * Load the Json Model
*/
var JM = new Object();

var res;

$.getJSON("/static/json_models/all_models_25_4.json")
.done(function( data ) {
    JM = data;

    // g01_L1_t00.json, created in MATLAB. However the precicion of those var. here is larger than in matlab which make no sense
    var test_sequence =
    {
    "x": [0.042258,0.030691,0.02487,0.024002,0.024855,0.030751,0.025812,0.031559,0.031678,0.031678,0.021084,0.024915,0.028057,0.069507,0.14552,0.54118,0.54118,0.44297,0.44297,0.3307,0.23836,0.20062,-0.30171,-0.21334,-0.084979,0.16098,0.48741,0.40788,0.26478,0.26478,0.27574,0.22275,0.1664,0.1664,0.22981,0.27358,0.2488,0.14986,0.21672,0.20586,0.3087],
    "y": [-0.20247,-0.19293,-0.19175,-0.19736,-0.18989,-0.19667,-0.18805,-0.19002,-0.1902,-0.1902,-0.19266,-0.19089,-0.20888,-0.26588,-0.34318,-0.5009,-0.5009,-0.54178,-0.54178,-0.5357,-0.52759,-0.44463,-0.99657,-0.95235,-1.011,-0.94486,-0.80311,-0.84321,-0.75518,-0.75518,-0.84352,-0.94873,-0.86942,-0.86942,-0.93422,-0.90254,-0.89663,-0.88205,-0.83902,-0.82265,-0.82181],
    "z": [-0.96043,-0.97884,-0.96147,-0.96826,-0.96533,-0.98078,-0.96822,-0.95951,-0.99623,-0.99623,-0.97793,-0.97692,-1.0002,-1.1412,-1.2271,-1.3305,-1.3305,-0.27209,-0.27209,-0.013767,0.013677,0.11524,1.1981,-0.36965,-0.38066,-0.12564,0.5032,0.31313,0.33092,0.33092,-0.055905,-0.20837,0.0080505,0.0080505,-0.078754,-0.071617,-0.13939,-0.16991,-0.21088,-0.17418,-0.2228]
    };
    var x = test_sequence.x, y = test_sequence.y, z = test_sequence.z; 

    /**
     *  Filter data
    */
    //var x = [1, 2, 2], y = [0, 2, 2], z = [0, 2, 2];
    var x2 = [], y2 = [], z2 = [], accel = [];
    // idle th filter
    for(var i = 0; i < x.length; i++){
        tmp_accel = Math.sqrt(Math.pow(x[i], 2) + Math.pow(y[i], 2) + Math.pow(z[i], 2));
        // not very neat to do it that way, but I did not find a nice way to use masks
        if (tmp_accel > (1 + JM.models[0].idle_th) || tmp_accel < (1 - JM.models[0].idle_th)){
            accel.push(tmp_accel);
            x2.push(x[i]);
            y2.push(y[i]);
            z2.push(z[i]);
        };

    };

    // todo: check that x len is bigger than 0
    if(x2.length == 0){
        alert("x2.length = 0");
    }

    // dir th filter
    var x3 = [x2[0]], y3 = [y2[0]], z3 = [z2[0]];
    var last = 0;
    var indeces = []
    for(var i = 1; i < x2.length; i++){
        if(Math.abs(x2[i] - x2[last]) >= JM.models[0].dir_th ||
            Math.abs(y2[i] - y2[last]) >= JM.models[0].dir_th ||
            Math.abs(z2[i] - z2[last]) >= JM.models[0].dir_th)
        {
            x3.push(x2[i]);
            y3.push(y2[i]);
            z3.push(z2[i]);
            last = i;
            indeces.push(i);
        };
    };

    if(x3.length == 0){
        alert("x3.length = 0");
    }


    /**
     *  Assign to cluster
    */

    //var x = [1, 2], y = [1, 2], z = [1, 2]; 

    // assign x3 var to x
    x = x3; y = y3; z = z3;

    var no_clusters, min_dis, tmp_d, IDXs = [];

    for(var i = 0; i < JM.models.length; i++){
        
        no_clusters = JM.models[i].cluster_centers.length;
        var cc = JM.models[i].cluster_centers;

        // initialiasing IDXs[[]] above does not work
        IDXs[i] = [];
        
        for(var j = 0; j < x.length; j++){
            min_dis = 100;

            for(var k = 0; k < no_clusters; k++){
                tmp_d = Math.sqrt(Math.pow(x[j]- cc[k][0], 2) + 
                    Math.pow(y[j]- cc[k][1], 2) + Math.pow(z[j]- cc[k][2], 2));
                if (tmp_d < min_dis){
                    min_dis = tmp_d;
                    IDXs[i][j] = k; 
                };
            };
        };
    };;


    /**
     *  Find best log likelihood
    */

    // one has to be very carefull, as matlab indices start with 1 and js with zero. So one needs to subract one...
    // valid for matlab:
    //var test_IDX = [3, 11, 11, 11, 10, 10, 10, 10, 8, 12, 12, 2, 14];

    //var test_IDX = [2, 10, 10, 10, 9, 9, 9, 9, 7, 11, 11, 1, 13];
    // model used all_models_23_4.json, used gesture1
    // ll_result_g1 = -21.8754 from matlab
    // Math.log(res[1]) = -21.875409306438588 with JS version

    /*
    console.log("gesture:"+ JM.models[0].gesture);

    res = HMM.forward(test_IDX, JM.models[0].prior 
        , JM.models[0].transmat, JM.models[0].obsmat);

    */

    var ll = [], tmp;
    for(var i = 0; i < JM.models.length; i++){
        tmp = HMM.forward(IDXs[i], JM.models[i].prior 
            , JM.models[i].transmat, JM.models[i].obsmat);

        // convert tmp to log likelihood. tmp[0] is the alpha matrix
        ll.push(Math.log(tmp[1]));

    };
    // find the best scores...
    var best_index = ll.indexOf(Math.max.apply(Math, ll));
    var best_gesture = JM.models[best_index].gesture;
    


    }
  );





