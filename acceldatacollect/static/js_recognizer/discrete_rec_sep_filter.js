



// Unit test
/*

!! careful, the unit test does not work in here as the function uses a seperate filter...

To conduct the test, replace the sample vaiable by the the sample below by copying it...
g01_L1_t00.json, created in MATLAB. However the precicion of those var. here is larger than in matlab which make no sense
var sample =
{
"x": [0.042258,0.030691,0.02487,0.024002,0.024855,0.030751,0.025812,0.031559,0.031678,0.031678,0.021084,0.024915,0.028057,0.069507,0.14552,0.54118,0.54118,0.44297,0.44297,0.3307,0.23836,0.20062,-0.30171,-0.21334,-0.084979,0.16098,0.48741,0.40788,0.26478,0.26478,0.27574,0.22275,0.1664,0.1664,0.22981,0.27358,0.2488,0.14986,0.21672,0.20586,0.3087],
"y": [-0.20247,-0.19293,-0.19175,-0.19736,-0.18989,-0.19667,-0.18805,-0.19002,-0.1902,-0.1902,-0.19266,-0.19089,-0.20888,-0.26588,-0.34318,-0.5009,-0.5009,-0.54178,-0.54178,-0.5357,-0.52759,-0.44463,-0.99657,-0.95235,-1.011,-0.94486,-0.80311,-0.84321,-0.75518,-0.75518,-0.84352,-0.94873,-0.86942,-0.86942,-0.93422,-0.90254,-0.89663,-0.88205,-0.83902,-0.82265,-0.82181],
"z": [-0.96043,-0.97884,-0.96147,-0.96826,-0.96533,-0.98078,-0.96822,-0.95951,-0.99623,-0.99623,-0.97793,-0.97692,-1.0002,-1.1412,-1.2271,-1.3305,-1.3305,-0.27209,-0.27209,-0.013767,0.013677,0.11524,1.1981,-0.36965,-0.38066,-0.12564,0.5032,0.31313,0.33092,0.33092,-0.055905,-0.20837,0.0080505,0.0080505,-0.078754,-0.071617,-0.13939,-0.16991,-0.21088,-0.17418,-0.2228]
};

COMPARING THE LL VALUES
using the all_models_25_4.json results in the following:
from javascript
ll =[-7.037495044668778, -34.89117082351426, -88.14597861380275, -36.52104394743089, -116.1641074376012]

from matlab
got the same result in Matlab using the evaluate_model_disrete.m script with csvData_20Hz/g01_L1_t00.json
model_ll = -7.0375  -34.8912  -88.1460  -36.5210 -116.1641


COMPARING CLUSTER VALUES: (note that as matlab indexing starts at 1 and JS at 0 they are one apart)
from matlab (debugger stopped inside the test_single_data.m srcipt): 
    IDX.' = 4     7    13    13    13    13    13    13    13    13
from javasript
IDXs[1]  = [3, 6, 12, 12, 12, 12, 12, 12, 12, 12]


*/


/**
 * Calculate the most likeli gesture for sample givem the model JM
 * !! Call this function only with models that were created with no filtering at all. 
 * @param {object} JM - the json model
 * @param {object} sample - recoreded sample with x,z,y, and t. e.g. sample.x
 * @param number - noise th - t
 */ 
function discrete_recognizer_sep_filter(JM, sample, noise_th, ll_th)
{
    var sep_filter = JM.info.sep_filter;

    if (sep_filter == 1){
        // New variables for seperate filtering state
        idle_th = 0.1;
        dir_th = 0.1;
    }
    else{
        idle_th = JM.models[0].idle_th;
        dir_th = JM.models[0].dir_th;
    };

    //noise_th = JM.info.noise_th;
    //noise_th = 15;
    //ll_th = JM.info.ll_th;

    var t1 = new Date().getTime();


    var x = sample.x, y = sample.y, z = sample.z; 

    /**
     *  Filter data
    */
    //var x = [1, 2, 2], y = [0, 2, 2], z = [0, 2, 2];
    var x2 = [], y2 = [], z2 = [], accel = [];
    // idle th filter
    for(var i = 0; i < x.length; i++){
        tmp_accel = Math.sqrt(Math.pow(x[i], 2) + Math.pow(y[i], 2) + Math.pow(z[i], 2));
        // not very neat to do it that way, but I did not find a nice way to use masks
        if (tmp_accel > (1 + idle_th) || tmp_accel < (1 - idle_th)){
            accel.push(tmp_accel);
            x2.push(x[i]);
            y2.push(y[i]);
            z2.push(z[i]);
        };

    };


    // dir th filter
    var x3 = [x2[0]], y3 = [y2[0]], z3 = [z2[0]];
    var last = 0;
    var indeces = []
    for(var i = 1; i < x2.length; i++){
        if(Math.abs(x2[i] - x2[last]) >= dir_th ||
            Math.abs(y2[i] - y2[last]) >= dir_th ||
            Math.abs(z2[i] - z2[last]) >= dir_th)
        {
            x3.push(x2[i]);
            y3.push(y2[i]);
            z3.push(z2[i]);
            last = i;
            indeces.push(i);
        };
    };

    var t2 = new Date().getTime();

    if(x3.length < noise_th){

        return {
            status : 0,
            info: "x3.lenght < noise_th; " + x3.length + " < " + noise_th,
            t_filter : (t2 -t1),
        };
    };


    /**
     *  Assign to cluster
    */
    if (sep_filter == 1){
        // use the unfiltered sample, i.e. it has original length
        x = x; y = y; z = z;
    }
    else{
        // use the filtered sample
        x = x3; y = y3; z = z3;
    };

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
    };

    var t3 = new Date().getTime();

    /**
     *  Find best log likelihood
    */

    /*
    console.log("gesture:"+ JM.models[0].gesture);

    res = HMM.forward(test_IDX, JM.models[0].prior 
        , JM.models[0].transmat, JM.models[0].obsmat);

    */
    var HMM = ProbabilityAPI.HiddenMarkovModel;
    var ll = [], tmp;
    for(var i = 0; i < JM.models.length; i++){
        tmp = HMM.forward(IDXs[i], JM.models[i].prior 
            , JM.models[i].transmat, JM.models[i].obsmat);

        // convert tmp to log likelihood. tmp[0] is the alpha matrix
        ll.push(Math.log(tmp[1]));

    };
    // find the best scores...
    var best_score = Math.max.apply(Math, ll);
    var best_index = ll.indexOf(best_score);
    var best_gesture = JM.models[best_index].gesture;

    var t4 = new Date().getTime();

    if (best_score > ll_th){
        return {
            // status defines whether there is a valid result
            status : 1,
            best_gesture : best_gesture,
            ll : ll,
            t_filter : (t2 -t1),
            t_cluster: (t3 -t2),
            t_hmm: (t4 -t3),
            best_score: best_score,
            IDX_len : x3.length
        };
    }
    else{
        return{
            status : 0,
            info : "best_score < ll_th; " + best_score + " < " + ll_th
        };
    };




    


};





