from __future__ import division
import os
import re
import json
import webapp2
import jinja2
import datetime
import csv
import glob

import zipfile
import StringIO

from google.appengine.ext import ndb
from google.appengine.api import mail

from numpyAnalysis import tickMov_v1


#*******************************************************************************
# Helper functions

template_dir = os.path.join(os.path.dirname(__file__), 'templates')
jinja_env = jinja2.Environment(loader = jinja2.FileSystemLoader(template_dir),
                               autoescape = True)

def render_str(template, **params):
    t = jinja_env.get_template(template)
    return t.render(params)

class BlogHandler(webapp2.RequestHandler):
    def write(self, *a, **kw):
        self.response.out.write(*a, **kw)

    def render_str(self, template, **params):
        return render_str(template, **params)

    def render(self, template, **kw):
        self.write(self.render_str(template, **kw))

    def initialize(self, *a, **kw):
        webapp2.RequestHandler.initialize(self, *a, **kw)
        
        
EMAIL_RE  = re.compile(r'^[\S]+@[\S]+\.[\S]+$')
def valid_email(email):
    return EMAIL_RE.match(email)


#*******************************************************************************      
##### Data base models   
def users_key(group = 'default'):
    return ndb.Key('users', group)


class User(ndb.Model):
    """ user details"""
    name = ndb.StringProperty()
    email = ndb.StringProperty()
    created = ndb.DateTimeProperty(auto_now_add = True)
    
class MotionData(ndb.Model):
    """ for the continuous recordings
        raw data is stored as json sin dataPoints
        - has a back reference to the user that submitted it. Though is just a name so far...
        """
    user = ndb.KeyProperty(kind = User)
    startTime = ndb.DateTimeProperty()
    duration = ndb.FloatProperty()
    dataPoints = ndb.JsonProperty()
    sampleNumber = ndb.IntegerProperty()
    avSampleFrequ = ndb.FloatProperty()
    # origSF is the parameter that is set from the client....
    origSampleFrequ = ndb.FloatProperty()
    userAgent = ndb.StringProperty()
    # dataGap is 1 if there is a gap in the recording, 0 if it is ok
    dataGap = ndb.IntegerProperty()

class DiscreteData(ndb.Model):
    """ for the discrete recordings 
        This model is used for the discreteRecorder
        """
    user = ndb.StringProperty()
    gesture = ndb.StringProperty()    
    origSampleFrequ = ndb.FloatProperty()
    periodGesture = ndb.FloatProperty()
    noOfRepetitions = ndb.FloatProperty()
    startTime = ndb.DateTimeProperty()
    userAgent = ndb.StringProperty()
    data = ndb.JsonProperty()
    
    created = ndb.DateTimeProperty(auto_now_add = True)

    @classmethod
    def query_disrete(cls, number):
        # make use of the structured property values and use the projection to prevent loading all the data
        return cls.query().order(-cls.startTime).fetch(number, projection=
            ["user", "gesture", "origSampleFrequ", "periodGesture", "noOfRepetitions",
            "startTime"])

class DemoDoubleDB(ndb.Model):
    """ keeps track when which gesture was submitted, if multpile user submit,
    then it gets into trouble"""
    page = ndb.StringProperty()
    gestureName = ndb.StringProperty()
    created = ndb.DateTimeProperty(auto_now_add = True)



##### Page Handlers
class MainPage(BlogHandler):
    def get(self):
        #self.redirect("/discreteRecognizer")
        self.render("index.html")


#*******************************************************************************
##### Discrete data handlers 

class DiscreteRecorder(BlogHandler):
    def get(self):
        self.render("discreteRecorder.html")


class PostGesture(BlogHandler):
    """ this is called via AJAX only, so no need to implement a GET here"""
    def post(self):
         # those two lines are a work around, as I did not get it to 
        # work with extracing the variables directly
        r = self.request.body
        r = json.loads(r)   
        
        m = DiscreteData()
        m.user = r["user"]
        m.gesture = r["gesture"]
        # get the data in milliseconds from server, hence need to devide by 1000
        m.startTime = datetime.datetime.fromtimestamp(r["startTime"]/1000)
        m.origSampleFrequ = r["origSampleFrequ"] 
        m.userAgent =  self.request.headers.get('User-Agent')
        m.noOfRepetitions = r["noOfRepetitions"]
        m.periodGesture = r["periodGesture"]/1000    
        m.data = r

        # insert data into database
        m.put()
                
        # Response:
        self.response.headers["Content-Type"] = 'application/json; charset=UTF-8'
        info ="Thanks %s, data received." %(r["user"])
        self.write(json.dumps({"status": 1, "info" : info}))


class DownloadGestures(BlogHandler):
    def get(self):
        secure = self.request.get("secure");
        user = self.request.get("user");
        fetch = self.request.get("fetch");
        

        if user != '':
            print user
            # http://stackoverflow.com/questions/19720113/cannot-filter-a-non-node-argument-datastore-google-app-engine-python
            # when filtering strings, it is different. 
            q = DiscreteData.query().filter(ndb.GenericProperty('user') == user).fetch(100)
        else:
            if fetch != '':
                fetch = int(fetch)
            else:
                fetch = 100
            q = DiscreteData.query().order(-MotionData.startTime).fetch(fetch)
        
        if secure == '1':
            jsonList = [i.data for i in q if "OS 6_" in i.userAgent]
        else:
            print "in else statement"
            jsonList = [i.data for i in q]
        
        self.write(json.dumps(jsonList))


class ListDataDisc(BlogHandler):
    def get(self):
        user = self.request.get("user");
        fetch = self.request.get("fetch");
        if fetch == '':
            fetch = 20
        else:
            fetch = int(fetch)
            if fetch > 50:
                fetch = 50

        if user != '':
            # http://stackoverflow.com/questions/19720113/cannot-filter-a-non-node-argument-datastore-google-app-engine-python
            # when filtering strings, it is different. 
            q = DiscreteData.query().filter(ndb.GenericProperty('user') == user).fetch(fetch)
        else:
            q = DiscreteData.query_disrete(fetch)

        self.render("listDataDisc.html", q = q, fetch= fetch, user = user)



class DiscRawData(BlogHandler):
    def get(self, keyId, format1):
        "I get the key_id, as in the route, a regex is set up"        
        # contstructs the key class fromt he key_id
        print format1
        key = ndb.Key('DiscreteData', int(keyId))       
        q = key.get()

        if format1 == "/.json":
            ##change content type header
            self.response.headers["Content-Type"] = 'application/json; charset=UTF-8'
            #convert python dict to json and write it out
            self.write("%s"%json.dumps(q.data))

        elif format1 == "/.zip":
            # create one stream for zip file and a second one for csvfile
            csvStream = StringIO.StringIO()
            w = csv.writer(csvStream)
            zipstream=StringIO.StringIO()
            file = zipfile.ZipFile(file=zipstream,compression=zipfile.ZIP_DEFLATED,mode="w")

            # loop through all the repetitions
            for dP in q.data["repetitions"]:
                w.writerow(["t", "tRel", "x", "y", "z", "alpha", "beta", "gamma"])
                # convert the abolute time to relative times in seconds   
                tRel = []
                for item in dP["t"]:
                   tRel.append((item - dP["t"][0]) / 1000)

                for j in range(len(dP["t"])):
                    w.writerow([dP["t"][j] , tRel[j], dP["x"][j],
                                 dP["y"][j] , dP["z"][j], dP["alpha"][j],
                                 dP["beta"][j], dP["gamma"][j]])

                # write the csv stream to zip
                file.writestr("rep" + str(dP["rep"]) + ".csv",csvStream.getvalue().encode("utf-8"))
            
                # need to reset the csvstream each time.
                csvStream.truncate(0)

            file.close()
            zipstream.seek(0)
            self.response.headers['Content-Type'] ='application/zip'
            self.response.headers['Content-Disposition'] = 'attachment; filename="'+ keyId +'.zip"'
            self.response.out.write(zipstream.getvalue())

class DiscreteRecognizer(BlogHandler):
    def get(self):
        self.render("discreteRecognizer.html")


#*******************************************************************************
##### Continuous data handlers 

class ContinuousRecorder(BlogHandler):
    def get(self):
        self.render("continuousRecorder.html")

      
class PostData(BlogHandler):
    """ this is called via AJAX only, so no need to implement a GET here"""
    def post(self):
        # those two lines are a work around, as I did not get it to 
        # work with extracing the variables directly
        r = self.request.body
        r = json.loads(r)   
        
        u = User(name = r["user"])
        if valid_email(r["email"]):
            u.email = r["email"]
        u.put()

        m = MotionData(user = u.key)
        print r["startTime"]
        # get the data in milliseconds from server, hence need to devide by 1000
        m.startTime = datetime.datetime.fromtimestamp(r["startTime"]/1000)
        # duration in seconds
        
        # compute tRel and tDiff, tDiff is one element less as it computes difference 
        t0 = r["dataPoints"]["t"][0]
        r["dataPoints"]["tRel"] = [ (i - t0)/1000 for i in r["dataPoints"]["t"]]
        tDiff = []
        for i in range(len(r["dataPoints"]["t"]) -1):
            tDiff.append(r["dataPoints"]["tRel"][i+1] - r["dataPoints"]["tRel"][i])
        # add an arbitrary element to make the string the same size
        tDiff.append(1/r["origSampleFrequ"])
        r["dataPoints"]["tDiff"] = tDiff
                 
        m.dataPoints = r["dataPoints"]
        
        # Check if the has no big gaps. Use 10 * period as threshold
        if max(tDiff) > (1 / r["origSampleFrequ"] * 10):
            m.dataGap = 1
        else:
            m.dataGap = 0
            

        # for the list:
        start, end  = r["dataPoints"]["t"][0] , r["dataPoints"]["t"][-1]
        m.duration = (end - start) / 1000       
        m.sampleNumber = len(r["dataPoints"]["t"])
        m.avSampleFrequ = m.sampleNumber / m.duration 
        m.origSampleFrequ = r["origSampleFrequ"] 
        
        m.userAgent =  self.request.headers.get('User-Agent')    
        
        
        # Response:
        self.response.headers["Content-Type"] = 'application/json; charset=UTF-8'
        info ="Thanks %s, <br> %s samples received" %(r["user"], m.sampleNumber)
        self.write(json.dumps({"status": 1, "info" : info}))
        
        # insert data into database
        m.put()
            
        # Send Email        
        if valid_email(r["email"]):
            user_address = r["email"]
            sender_address = "AccelDataCollect <noreply@acceldatacollect.appspotmail.com>"
            subject = "Link to your acceleration data"
            body = """ 
            Hi %s,
            
            Thanks a lot for helping me!
            
            The following link takes you to a summery of your data:
            
            http://acceldatacollect.appspot.com/sample/%d/plot
            
            See you!
                
            """%(u.name, m.key.id()) 
            #print body
            mail.send_mail(sender_address, user_address, subject, body)
                 
        
class ListDataCont(BlogHandler):
    def get(self):
        user = self.request.get("user");
        fetch = self.request.get("fetch");
        if fetch == '':
            fetch = 20
        else:
            fetch = int(fetch)
            if fetch > 50:
                fetch = 50

        # need a work around for the continuous data as user is stored in separate table
        # So need to query the user ids first. And then look them up indivudually...       
        if user != '':
            u_ids = User.query(ndb.GenericProperty('name') == user).fetch(fetch)
            q = []
            for i in u_ids:
                q.append(MotionData.query(ndb.KeyProperty('user') == i.key).get())
            # in case a user was created that has not MotionData entry, a 'None' field pops up.
            # Need to remove this fied as o/w jinja gives an error. 
            q = [i for i in q if i is not None]
        else:
            q = MotionData.query().order(-MotionData.startTime).fetch(fetch)
        self.render("listDataCont.html", q = q, user = user, fetch = fetch)

        

class RawJsonSample(BlogHandler):
    def get(self, keyId, format1):
        "I get the key_id, as in the route, a regex is set up"        
        # contstructs the key class fromt he key_id
        key = ndb.Key('MotionData', int(keyId))       
        q = key.get()
                       
        jcode= {}
        jcode["dataPoints"]= q.dataPoints
        jcode["name"] = q.user.get().name
        jcode["gdbKey"] = q.key.id() 
        jcode["startTime"] = str(q.startTime)
        jcode["duration"] = q.duration
        jcode["avSampleFrequ"] = q.avSampleFrequ
        jcode["origSampleFrequ"] = q.origSampleFrequ
        jcode["userAgent"] = q.userAgent
    
        ##change content type header
        self.response.headers["Content-Type"] = 'application/json; charset=UTF-8'
    
        #convert python dict to json and write it out
        self.write("%s"%json.dumps(jcode))

        
class RawCsvSample(BlogHandler):
    def get(self, keyId, format1):
        "I get the key_id, as in the route, a regex is set up"        
        # contstructs the key class fromt he key_id
        key = ndb.Key('MotionData', int(keyId))       
        q = key.get()                       
        dP = q.dataPoints
        
        ##change content type header
        self.response.headers['Content-Type'] = 'text/csv'
        self.response.headers['Content-Disposition'] = \
            'filename="'+ keyId +'.csv"' 
        
        w = csv.writer(self.response.out)
        if dP["alpha"] != []:
            w.writerow(["t", "tRel", "x", "y", "z", "alpha", "beta", "gamma"])        
            for i in range(len(dP["t"])):
                w.writerow([dP["t"][i] , dP["tRel"][i], dP["x"][i],
                             dP["y"][i] , dP["z"][i], dP["alpha"][i],
                             dP["beta"][i], dP["gamma"][i]])            
            
        else:
            w.writerow(["t", "tRel", "x", "y", "z"])        
            for i in range(dP["t"]):
                w.writerow([dP["t"][i] , dP["tRel"][i],
                            dP["x"][i], dP["y"][i] , dP["z"][i]])

            
class PlotSample(BlogHandler):
    def get(self, keyId, format1):
        "I get the key_id, as in the route, a regex is set up"        
        # contstructs the key class fromt he key_id
        key = ndb.Key('MotionData', int(keyId))       
        q = key.get()
                              
        dP = q.dataPoints
                
        print len(dP["tRel"])
        print len(dP["t"])
        
        # generate the lists for flot library, devide them by zero
        # the format is: [[[0, 0 ], [1, 1], [2, 0.5]], next line]
        xPairs = [list(i) for i in zip(dP["tRel"], [j for j in dP["x"]] )]
        yPairs = [list(i) for i in zip(dP["tRel"], [j for j in dP["y"]] )]
        zPairs = [list(i) for i in zip(dP["tRel"], [j for j in dP["z"]] )]
        accelPlot = [xPairs, yPairs, zPairs]
        
        # detect plot
        detectPlot = {}
        try:
            tM = tickMov_v1.TickMovV1()
            tM.passData(dP)
            detectPlot["data"] = [list(i) for i in zip(dP["tRel"], tM.result())]
            detectPlot["label"] = tM.version
            detectPlot["report"] = tM.report("html")
            error = ""
        except Exception, e:
            detectPlot["data"] = [[0,0]]
            detectPlot["label"] = "error"
            detectPlot["report"] = "error"
            error = """Ooops, something went wrong. Possibly the sampling frequency 
            used was too <5Hz or dataGap is 1. Error message: %s""" %(e)
        
        
        # gyro Plot
        gyroPlot = []
        if dP["alpha"] != []:
            alphaPairs = [list(i) for i in zip(dP["tRel"], dP["alpha"] )]
            betaPairs = [list(i) for i in zip(dP["tRel"], dP["beta"] )]
            gammaPairs = [list(i) for i in zip(dP["tRel"], dP["gamma"] )]
            gyroPlot = [alphaPairs, betaPairs, gammaPairs]
              
                   
        self.render("plotData.html", q = q, 
                                    error = error,
                                    accelPlot = accelPlot,
                                    gyroPlot = gyroPlot,
                                    detectPlot = detectPlot )         


class ContinuousRecognizer(BlogHandler):
    def get(self):

        # get a list of all the models models directory...

        # apparently one cannot have files in the static dir as on app engine they are stored somewhere esle...
        # hence use the templates dir and jinja2 rendering...
        files = glob.glob("./templates/json_models/*.json")
        print files
        # only keep the filename
        file_names = [i.split('/')[-1] for i in files]
        print "filenames:"
        print file_names

        self.render("continuousRecognizer.html", file_names = file_names)

class RenderJsonModels(BlogHandler):

    def get(self, mName):
        print mName
        print self.request.path

        self.response.headers["Content-Type"] = 'application/json'
        self.render(self.request.path[1:])


#*******************************************************************************       
##### Bookmark demos
class DemoSingle(BlogHandler):
    def get(self):
        self.render("demoSingle.html")

class DemoDoublePhone(BlogHandler):
    def get(self):
        self.render("demoDoublePhone.html")

class DemoDoubleDesktop(BlogHandler):
    def get(self):
        self.render("demoDoubleDesktop.html")

class DemoDoubleAction(BlogHandler):
    def post(self):        
        page = self.request.get("page")
        print page
        m = DemoDoubleDB()
        m.page = page
        m.gestureName = self.request.get("gestureName")
        m.put()

    def get(self):
        # get() gets a dict directly, fetch(1) gives a list of one dict
        entry = DemoDoubleDB.query().order(-DemoDoubleDB.created).get()
        print entry.created

        # for debugging, use the weeks as well...
        #delta = datetime.timedelta(weeks = 1, seconds = 10)
        delta = datetime.timedelta(seconds = 10)
        now = datetime.datetime.now()
        if (entry.created > (now - delta)):
            status, page = 1, entry.page
            gestureName = entry.gestureName
            # TODO enable this for the final version again...
            entry.key.delete()
        else:
            status, page, gestureName = 0, "", ""


        response = {"status": status, "page": page, "gestureName": gestureName}
        self.write(json.dumps(response))
        
class SamplePost(BlogHandler):
    def post(self):
        pass
        

#*******************************************************************************       
##### Page routing

# http://webapp-improved.appspot.com/guide/routing.html
# The matched group values are passed to the handler as positional arguments
# --> need

app = webapp2.WSGIApplication([('/', MainPage),
                               ('/continuousRecorder', ContinuousRecorder),
                               ('/postData', PostData),
                               ('/listDataCont', ListDataCont),
                               ('/listDataDisc', ListDataDisc),
                               ('/samplePost', SamplePost),
                               # TODO: fix this regex, it allows too much...
                               # handlers for cont. samples
                               ('/sample/(\d{16})(/.json)?', RawJsonSample),
                               ('/sample/(\d{16})(/.csv)?', RawCsvSample),
                               ('/sample/(\d{16})(/plot)?', PlotSample),
                               # handlers for discrete samples
                               ('/disc_sample/(\d{16})(/.json|/.zip|/plot)?', DiscRawData),

                               #webapp2.Route(r'/sample/<key:\d{16}>/<format>', handler=JsonSample, name='sample'),
                               ('/discreteRecorder', DiscreteRecorder),
                               ('/postGesture', PostGesture),
                               ('/downloadGestures', DownloadGestures), 
                               ('/discreteRecognizer', DiscreteRecognizer),
                               ('/continuousRecognizer', ContinuousRecognizer),
                               ('/json_models/(.+)', RenderJsonModels),
                               ('/demoSingle', DemoSingle),
                               ('/demoDoublePhone', DemoDoublePhone),
                               ('/demoDoubleDesktop', DemoDoubleDesktop),
                               ('/demoDoubleAction', DemoDoubleAction),
                               ],
                              debug=True)


