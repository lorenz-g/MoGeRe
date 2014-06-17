
//************************************************************************************
// CONST GLOBAL VARIABLES

const int DEBUG = 0;

const int xpin = A4;                  // x-axis (only on 3-axis models)
const int ypin = A5;                  // y-axis (only on 3-axis models)
const int zpin = A7;                  // z-axis (only on 3-axis models)
const int low_v_pin = A6;            // reads the VCC of the chip --> make sure the jumper on the launchpad is removed

const int BLINK_LED = RED_LED;
const int STATUS_LED = P2_2;


const int period = 50; // in ms
const int window_length = 30;
// window length in seconds = window_length / (1000 / period) 
// so if per = 50 and w_l = 30, it is 1.5 seconds long

const int no_of_blink_samples = 40; // the blinking duration in seconds = period * no_of_blink_samples / 1000; 
const int toggle_samples = 8; // the blinking frequency in Hz = 1/ (period * 2 * toggle_samples / 1000);

// this is false
//const int z_comp[30] = {1,  1,  1,  1,  1,     1,  1,  1,  1, -1,     -1, -1, -1, -1, -1,     -1, -1, -1, -1, -1,    -1,  1,  1,  1,  1,    1,  1,  1,  1,  1};
const int z_comp[30] = {-1, -1, -1, -1, -1,     -1, -1, -1, -1, 1,       1,  1,  1,  1,  1,      1,  1,  1,  1,  1,     1, -1, -1, -1, -1,   -1,  -1,  -1,  -1,  -1};

// those settings are for case with a regulator and VCC for accel chip is 2.75V
const int x_diff_th = 500; // from 12.fig
// at the end of a blinking period, continue blinging if the average x value is greater than that threshold
const int x_average_th = 280;

const int z_mean = 350; // found from 18.fig, with the potiental devider for accel values
const int neg_z_th = 35;
const int pos_z_th = 35;

const int z_score_th = 10; // from 12.fig

// not the actual voltage
const int disconnect_voltage = 600;

//************************************************************************************
// global read and write buffers

unsigned int x_buffer[30];
unsigned int z_buffer[30]; 

// needs to be int as it can contain -1
int z_simple_buffer[30];




//************************************************************************************
// SETUP
void setup()
{
  // initialize the serial communications:
  Serial.begin(4800); // msp430g2231 must use 4800
    
  pinMode(BLINK_LED, OUTPUT); 
  pinMode(STATUS_LED, OUTPUT); 
  delay(50);
  digitalWrite(BLINK_LED, 0);
  digitalWrite(STATUS_LED, 0);
  
  pinMode(low_v_pin, INPUT);
  
  
  // set the internal voltage reference
  analogReference(INTERNAL2V5);
  
  // serial is only needed for debugging
  if (DEBUG == 1){
    establishContact();  // send a byte to establish contact until receiver responds
  }
  
}


//************************************************************************************
// MAIN LOOP
void loop()
{
  // detect a low voltage
  int vcc = analogRead(low_v_pin);
  boolean led_state = 0;
  // pot devider to get vcc/1 and want to detect voltages under 3v -? 1.5/2.5*1025 = 614
  while (vcc < disconnect_voltage){
      digitalWrite(STATUS_LED, led_state);
      delay(1000);
      led_state = !led_state;
      vcc = analogRead(low_v_pin);
      
      //Serial.print(vcc, DEC);  // print as an ASCII-encoded decimal
      //Serial.print("\n");
  }
  
  digitalWrite(STATUS_LED, 1);
  // will stay in that loop
  detectMovements(); 
}




//************************************************************************************
// HELP FUNCTIONS

void detectMovements(){
  // this looks out for the 
  long int x_difference;
  int z_score;
  long currentMillis;
  long previousMillis = 0;
  int i = 0;
  
  while(1){
    currentMillis = millis();
    if ((currentMillis - previousMillis) > period){
      previousMillis = currentMillis;
      readAndStoreXYZ(i);
      x_difference = analyseXAxis(i);
      z_score = analyseZAxis(i);
      
      if (DEBUG == 1){
        Serial.print(x_difference, DEC);  // print as an ASCII-encoded decimal
        Serial.print("\n");
        Serial.print(z_score, DEC);  // print as an ASCII-encoded decimal
        Serial.print("\n");
      }
      
      if ((z_score > z_score_th) && (x_difference > x_diff_th)){
        i = blinkLED(i);
        //i = i;
      }
       
      i = (i+1) % window_length;
      
      //Serial.print(i, DEC);  // print as an ASCII-encoded decimal
      //Serial.print("\n");
    }
  
  } 
}



void establishContact() {
  while (Serial.available() <= 0) {
    Serial.println('A');   // send a capital A
    delay(300);
  }
}




void readAndStoreXYZ(int storeInt){
  // reads the x y z var from analogue in, and then stores them in the buffers at buffer[storInt]
  int x = analogRead(xpin);
  int y = analogRead(ypin);
  int z = analogRead(zpin);
  
  x_buffer[storeInt] = x;
  //y_buffer[storeInt] = y;
  z_buffer[storeInt] = z;
 
  
  if (DEBUG == 1){

    // the x is needed by matlab for error checking...    
    Serial.println("x");
    Serial.print(x, DEC);  // print as an ASCII-encoded decimal
    Serial.print("\n");
  
    //Serial.print("y:");
    //Serial.print(y, DEC);  // print as an ASCII-encoded decimal
    //Serial.print("\n");
    
    //Serial.print("z:");
    Serial.print(z, DEC);  // print as an ASCII-encoded decimal
    Serial.print("\n");
  
  
  
  }
  
}

long int analyseXAxis(int currI){
  
  // buffer[currI] is the one that was just recorded. 
  // buffer[currI + 1] is the one that was recorded window length seconds ago (i.e. 1.5s)
  
  
  // sum first 6 samples
  // by first I mean the first six samples of the window. i.e. sum(currI + 1 to currI + 6)
  
  int bI ; // buffer index
  
  long int sumFirst = 0;
  
  for(int i =0 ;i < 6; i++){
    bI = (currI + i + 1) % window_length;
    sumFirst = sumFirst + x_buffer[bI];
  }
  
  // sum last 6 samnples
  long int sumLast = 0;
  for(int i =0 ;i < 6; i++){
    if ((currI - i) <  0 ){
      bI = window_length + currI - i;
    }
    else{
      bI = currI - i;
    }
    sumLast = sumLast + x_buffer[bI];
  }
  
  return sumLast - sumFirst;
  
}

int analyseZAxis(int currI){
  
  // qunatize the current z value...
  if (z_buffer[currI] > z_mean + pos_z_th){
    z_simple_buffer[currI] = 1;
  }
  else if (z_buffer[currI] > z_mean - neg_z_th){
    z_simple_buffer[currI] = -1;
  }
  else{
    z_simple_buffer[currI] = 0;
  }
  
  
  // calculate the z_score
  int bI; // buffer index
  int z_score = 0;
  for(int i = 0; i < window_length; i++){
    bI = (i + currI) % window_length;
    
    // as long as z_comp is symmetric, no need to think about its index, but do NOT use bI for it. 
    if(z_simple_buffer[bI] == 0){
      z_score += 0;
    }
    else if(z_simple_buffer[bI] == z_comp[i]){
      z_score +=1;
    } 
    else if(z_simple_buffer[bI] != z_comp[i]){
      z_score += -1;
    }
  }
  return z_score;
  
}

int blinkLED(int currI){
  // this function will record the xyz values, but no analyse them. And it toggles the LED
  long currentMillis;
  long previousMillis = 0;
  int j = 0;
  
  int led_toggle_counter = 0;
  
  int x_average;
  
  boolean LED_state = true;
  digitalWrite(BLINK_LED, LED_state);
  
  while(j <= no_of_blink_samples){
    currentMillis = millis();
    
    if ((currentMillis - previousMillis) > period){
      previousMillis = currentMillis;
      
      currI = (currI+1) % window_length;
      readAndStoreXYZ(currI);
      
      led_toggle_counter +=1;
      if ((led_toggle_counter % toggle_samples) == 0){
        LED_state = !LED_state;
        digitalWrite(BLINK_LED, LED_state);
      } 
      
      if (DEBUG == 1){
        Serial.print(0, DEC);  // print as an ASCII-encoded decimal
        Serial.print("\n");
        Serial.print(0, DEC);  // print as an ASCII-encoded decimal
        Serial.print("\n");
      }
      
      
      if(j == no_of_blink_samples){
        x_average = getAvgAccel(1, 4, currI);
        // stay in the blinking loop if the arm is still up...
        if (x_average > x_average_th){
          j = j;
        }
        else{
        j+=1;
        }
      }
      else{
        j++;
      }
      
    }
  
  
  }
  
  digitalWrite(BLINK_LED, 0);
  return currI;      

}


unsigned int getAvgAccel(int axis, int avg_length, int currI){
// get average accelleration...
// for the length, use only powers of 2, as bithsifting is used for multiplication
// only works for x axis so far
  
  int bI ; // buffer index
    
  // sum last avg_length samnples
  long int sumLast = 0;
  
  for(int i =0 ;i < avg_length; i++){
    if ((currI - i) <  0 ){
      bI = window_length + currI - i;
    }
    else{
      bI = currI - i;
    }
    sumLast = sumLast + x_buffer[bI];
  }
  
  // bitshifting to devide...
  unsigned int average= 0;
  
  if (avg_length == 2){
    average = sumLast >> 1;
  }
  else if (avg_length == 4){
    average = sumLast >> 2;
  }
  
  else if (avg_length == 8){
    average = sumLast >> 3;
  }
  
  return average;


}
