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
    #FF110D, #E80C6C, #FF00EF, #B30CE8, #830DFF
  }
  , 
  {
    #435772, #2DA4A8, #FEAA3A, #FD6041, #CF2257
  }
  , 
  {
    #FF003C, #FF8A00, #FABE28, #88C100, #00C176
  },
  {
    #000000, #333333, #FF358B, #01B0F0, #AEEE00
  },
  {
    #272F32, #9DBDC6, #FFFFFF, #FF3D2E, #DAEAEF
  }
};

void setup() {
  size(displayWidth, displayHeight);
  noSmooth();
  noStroke();
  rectMode(CORNERS);
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

float offset = 0;
float fillPct = 0.50;
float numLines = 8;
float speed = 1;
  
void pattern() {
  background(0);
  float sliceHeight = height / (float)palettes[color_idx].length;
  float y = 0;
  
  if (offset > 0) {
    if (palette_idx == 0)
      fill(palettes[color_idx][palettes[color_idx].length - 1]);
    else
      fill(palettes[color_idx][palette_idx - 1]);
    fillRectWithLines((0 - sliceHeight) + offset, offset, fillPct, (int)numLines);
    //rect(0, 0, width, offset);
  }
  for (int i = 0; i < palettes[color_idx].length; i++) {
    fill(palettes[color_idx][(palette_idx + i) % palettes[color_idx].length]);
    y = i * sliceHeight;
    //rect(0, y + offset, width, y + sliceHeight + offset);
    fillRectWithLines(y + offset, y + sliceHeight + offset, fillPct, (int)numLines);
  }
  offset += speed;
  if (offset > sliceHeight) {
    offset = 0;
    decrementPalette();
  }
}

void fillRectWithLines(float yStart, float yEnd, float fillPct, int numLines) {
  float lineOffset = (yEnd - yStart) / (float)numLines;
  float lineHeight = lineOffset * fillPct;

  for (int i = 0; i < numLines; i++) {
    float y1 = yStart + ((float)i * lineOffset);
    float y2 = y1 + lineHeight;
    rect(0, y1, width, y2);
  }
}

void incrementPalette() {
  palette_idx++;
  if (palette_idx >= palettes[color_idx].length) {
    palette_idx = 0;
  }
}

void decrementPalette() {
  palette_idx--;
  if (palette_idx <= 0) {
    palette_idx = palettes[color_idx].length - 1;
  }
}

void draw() {
  pattern(); 
  if (launch_beat) {
    beat_width--;
    if (beat_width == 0) {
      launch_beat = false;
      incrementPalette();
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

void calculateLineWidth(float y1, float y2) {
  fillPct += (y2-y1) / 300;
  if (fillPct < 0)
    fillPct = 0;
  if (fillPct > 1)
    fillPct = 1;
}

void calculateNumLines(float x1, float x2) {
  numLines += (x2-x1) / 30.0;
  if (numLines < 1)
    numLines = 1;
  if (numLines > 100)
    numLines = 100;
    
}

void calculateSpeed(float y1, float y2) {
  speed += (y2-y1) / 30.0;
  if (speed < 1)
    speed = 1;
  if (speed > 300)
    speed = 300;
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
  case MotionEvent.ACTION_MOVE:
    if (event.getHistorySize() > 0) {
      if (event.getPointerCount() == 1) {
        calculateLineWidth(event.getHistoricalY(0, 0), event.getY(0));
        calculateNumLines(event.getHistoricalX(0, 0), event.getX(0));
      }
      if (event.getPointerCount() == 2) {
        calculateSpeed(event.getHistoricalY(0, 0), event.getY(0));
      }
    }
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

