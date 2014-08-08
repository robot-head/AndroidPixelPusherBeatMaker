import android.view.MotionEvent;
import java.util.*;
import android.view.View;
import com.heroicrobot.dropbit.registry.*;
import com.heroicrobot.dropbit.devices.pixelpusher.Pixel;
import com.heroicrobot.dropbit.devices.pixelpusher.Strip;


int beat_width=0;
long period = 1000000000 / (120 / 60);
long lastbeat = 0;
int BEAT_WIDTH = 5;
int color_idx = 0;
int palette_idx = 0;
boolean launch_beat = false;
long lastTap = 0;

int palettes[][] = {
  {
    #B21212, #FFFC19, #FF0000, #1485CC, #0971B2
  }
  , 
  {
    #435772, #2DA4A8, #FEAA3A, #FD6041, #CF2257
  }
  , 
  {
    #FF003C, #FF8A00, #FABE28, #88C100, #00C176
  }
};

void setup() {
  size(displayWidth, displayHeight);
  noSmooth();
  noStroke();
  //size(400, 660); // needs to be a multiple of 330
  colorMode(RGB, 100);
  orientation(PORTRAIT);
  final View surfaceView = this.getSurfaceView();
  runOnUiThread(new Runnable() {
    public void run() {
      surfaceView.setKeepScreenOn(true);
    }
  }
  );

  registry = new DeviceRegistry();
  testObserver = new TestObserver();
  registry.addObserver(testObserver);
  registry.setAntiLog(true);
  lastbeat = System.nanoTime();
}

void pattern() {
  float sliceHeight = height / (float)palettes[color_idx].length;
  float y = 0;
  for (int i = 0; i < palettes[color_idx].length; i++) {
    fill(palettes[color_idx][(palette_idx + i) % palettes[color_idx].length]);
    y = i * sliceHeight;
    rect(0, y, width, y + sliceHeight);
  }
  //background(palettes[color_idx][palette_idx]);
}

void draw() {
  pattern(); 
  if (launch_beat) {
    beat_width--;
    if (beat_width == 0) {
      launch_beat = false;
      palette_idx++;
      if (palette_idx >= palettes[color_idx].length) {
        palette_idx = 0;
      }
    }
  }
  
  scrape();
  
  if (System.nanoTime() - lastbeat > period) {
    launch_beat=true;
    beat_width = BEAT_WIDTH;
    lastbeat = System.nanoTime();
  }
}

void tap() {
  if (lastTap != 0) { // if we have a last tap time
    period = System.nanoTime() - lastTap; // calculate how long it's been and set the period
    println("Period is "+period);
  } else {
    println("First tap");
  }
  lastTap = System.nanoTime();
}

void nextColor() {
  color_idx++;
  if (color_idx >= palettes.length) {
    color_idx = 0;
  }
}
boolean cancelTap = false;

@Override
public boolean dispatchTouchEvent(MotionEvent event) {

  float x = event.getX();                              // get x/y coords of touch event
  float y = event.getY();

  int action = event.getActionMasked();          // get code for action
  //pressure = event.getPressure();                // get pressure and size
  //pointerSize = event.getSize();

  switch (action) {                              // let us know which action code shows up
  case MotionEvent.ACTION_DOWN:
    //touchEvent = "DOWN";

    break;
  case MotionEvent.ACTION_UP:
    //    touchEvent = "UP";
    if (!cancelTap) {
      tap();
    }
    cancelTap = false;
    break;
  case MotionEvent.ACTION_POINTER_DOWN: 
    nextColor();
    cancelTap = true;
    break;
  default:
    //    touchEvent = "OTHER (CODE " + action + ")";  // default text on other event
  }

  return super.dispatchTouchEvent(event);        // pass data along when done!
}

