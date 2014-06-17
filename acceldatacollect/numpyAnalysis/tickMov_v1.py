
from __future__ import division
import os
import json
import urllib2

import numpy as np

url1 = "http://acceldatacollect.appspot.com/sample/6281948016148480/.json"
url2 = "http://localhost:8080/sample/4984842122952704/.json"

DEBUG = 0

def d_print(*arguments):
    if DEBUG == 1:
        for arg in arguments: print arg

class TickMovV1():
    def __init__(self):
        self.mov_duration = 1
        # x
        self.neg_x_thr = -0.15 
        self.score_perc_high = 0.6
        self.score_perc_low = 0.4
        # y
        self.len_of_average = 0.2 
        self.y_diff_thr = 0.7
        #z
        self.neg_z_thr = -0.2
        self.z_score_perc = 0.4
        self.z_trigger_delay = 0.4 # in seconds
                
        self.version = "tickMov_v1"
        
    def getData(self, url):
        d = json.load(
            urllib2.urlopen(url, timeout=5))
    
        self.t = np.array(d["dataPoints"]["tRel"])
        self.x = np.array(d["dataPoints"]["x"])
        self.y = np.array(d["dataPoints"]["y"])
        self.z = np.array(d["dataPoints"]["z"])

    def passData(self, dataPoints):    
        self.t = np.array(dataPoints["tRel"])
        self.x = np.array(dataPoints["x"])
        self.y = np.array(dataPoints["y"])
        self.z = np.array(dataPoints["z"])


    def general(self):
        self.f_sample = len(self.t)/self.t[-1]
        self.b_len = 2*round(self.mov_duration * self.f_sample/2)
        d_print("f_sample: ", self.f_sample)
        d_print("b_len: ", self.b_len)   


    def x_analyse(self):
        pos_x_thr = - self.neg_x_thr
        neg = (self.x < self.neg_x_thr) * -1
        pos = self.x > pos_x_thr
        x_simple = neg + pos
        
        # too long
        #x_criteria = np.concatenate((np.ones((1, b_len/2)), np.ones((1, b_len/2)) *-1), axis = 1)
        # better
        x_criteria = [1]* int(self.b_len/2) + [-1] * int(self.b_len/2)
        d_print( "x_criteria", x_criteria)
    
        # the filter function in matlab treats the edges differently, hence the
        # selector at the back of the convolve statement
        x_scores = np.convolve(x_simple, x_criteria, 'full')[0:x_simple.shape[0]] 
    
        score_thr = self.score_perc_high * self.b_len;
        self.x_ind_high = x_scores > score_thr;
     
        score_thr = self.score_perc_low * self.b_len;
        self.x_ind_low = x_scores > score_thr;
        d_print( "Dimensions x simple, x_scores: ", x_simple.shape, x_scores.shape)
        
    def y_analyse(self):
        y_plus_one = self.y + 1
        # this line can cause a zero division error if f_sample is too small
        l_a = int(round(self.len_of_average * self.f_sample))
        
        tmp = [-1] * l_a + [0] * int(self.b_len - 2 * l_a) + [1] * l_a
        y_criteria = [ i / l_a for i in tmp]
        
        y_scores = np.convolve(y_plus_one, y_criteria, 'full')[0:self.y.shape[0]] 
        self.y_ind = y_scores > self.y_diff_thr
        d_print( 'y_criteria', y_criteria)
        d_print( "Dimensions self.y, y_scores: ", self.y.shape, y_scores.shape)
        
    def z_analyse(self):
        
        # remove gravity. Only works if screen of phone faces up. 
        z_plus_one = self.z + 1;
        pos_z_thr = - self.neg_z_thr
        neg = (z_plus_one < self.neg_z_thr) * -1
        pos = z_plus_one > pos_z_thr
        z_simple = neg + pos
        
        # in contrast to matlab version, the z_criteria is calculated dynamically based on fs
        # example for 20Hz and mov_duration = 1; 
        # z_criteria = [1 1 1 1 1 1 1 -1 -1 -1 -1 -1 -1 -1 1 1 1 1 1 1 ];
        perc = [0.3, 0.4, 0.3]
        tot = [int(round(i * self.f_sample * self.mov_duration)) for i in perc]
        b0_cr = [1] * tot[0] + [0] * tot[1] + [0] * tot[2]  
        b1_cr = [0] * tot[0] + [-1] * tot[1] + [0] * tot[2]  
        b2_cr = [0] * tot[0] + [0] * tot[1] + [1] * tot[2]  
        
        b0 = np.convolve(z_simple, b0_cr, 'full')[0:self.z.shape[0]]
        b1 = np.convolve(z_simple, b1_cr, 'full')[0:self.z.shape[0]]
        b2 = np.convolve(z_simple, b2_cr, 'full')[0:self.z.shape[0]]
        
        # do not use b0 & b1 & b2 -> somhow it takes the modolo 2 of each number and ands them
        z_cond1 = np.logical_and(b0, np.logical_and(b1, b2))
        z_score2 = b0 + b1 + b2
        
        d_print( "Dimensions self.z, z_score2: ", self.z.shape, z_score2.shape)
        d_print( 'b0_cr', b0_cr)
        d_print( 'b1_cr', b1_cr)
        d_print( 'b2_cr', b2_cr)

        z_ind_orig = np.logical_and(z_cond1,( z_score2 > self.b_len * self.z_score_perc))
        
        # delay the trigger by self.z_trigger_delay seconds
        delay = [1] * int(round(self.z_trigger_delay * self.f_sample))
        d_print( "delay", delay)
        z_ind_broad = np.convolve(z_ind_orig, delay, 'full')[0:self.z.shape[0]]

        self.z_ind = np.logical_and(z_ind_broad, 1) 
        
        
    def result(self):
        self.general()
        self.x_analyse()
        self.y_analyse()
        self.z_analyse()
        # here one can use the &, as *_ind are ones and zeors only
        self.cond1 = self.x_ind_high & self.z_ind
        self.cond2 = self.x_ind_low & self.y_ind & self.z_ind       
        self.cond_all = self.cond1 | self.cond2
        
        # prepare the return lise
        return [int(i) for i in self.cond_all]
        #self.report()
        
    def report(self, mode):
        """ mode can be debug or html. In case of debug it is printed to the console,
        in case of html, a string is returned"""
        len = self.t.shape[0]
        
        li = [[self.x_ind_high, "self.x_ind_high"],
              [self.x_ind_low, "self.x_ind_low"],
              [self.y_ind, "self.y_ind"],
              [self.z_ind, "self.z_ind"],
              [self.cond1, "self.cond1"],
              [self.cond2, "self.cond2"],
              [self.cond_all, "self.cond_all"],
              ]
        perc_list = []
        for i in li:
            perc_list.append(i[1][5:] + " triggered: %.2f" %(sum(i[0])/len*100) +
                                "%, " + str(sum(i[0])))
        t_events = []
        for i in range(len):
            if self.cond_all[i] == 1:
                t_events.append("Trigger at %.2f s."%self.t[i])
        
        params = [[self.mov_duration,"self.mov_duration"],
                  [self.neg_x_thr,"self.neg_x_thr"],
                  [self.score_perc_high,"self.score_perc_high"],
                  [self.score_perc_low,"self.score_perc_low"],
                  [self.len_of_average,"self.len_of_average"],
                  [self.y_diff_thr,"self.y_diff_thr"],
                  [self.neg_z_thr,"self.neg_z_thr"],
                  [self.z_score_perc,"self.z_score_perc"],
                  [self.z_trigger_delay,"self.z_trigger_delay"]                  
                  ]
        params_list = ["%s: %.2f"%(i[1][5:], i[0]) for i in params]
        if mode == "debug":
            print "VERSION:  ", self.version
            print "percentages:"  
            print "\n".join(perc_list)
            print "\n\nevents:"  
            print "\n".join(t_events)
            print " \n \n parameters:" 
            print "\n".join(params_list)
        else:
            return "VERSION:  " + self.version + \
                "<p><b>Percentages</b></p>" + "<br> - ".join(perc_list) + \
                "<p><b>Events</b></p>" + "<br> - ".join(t_events) + \
                "<p><b>Params</b></p>" + "<br> - ".join(params_list)
            
        
        
        
if __name__ == '__main__':    
    B = TickMovV1()
    B.getData(url1)
    B.result()
    print B.report("html")


